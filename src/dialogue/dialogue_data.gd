class_name DialogueData
extends RefCounted
## All dialogue nodes, loaded from the JSON that tools/dialogue/build_dialogue.py
## writes from design/narrative/dialogue/*.md, plus the tuning values in
## affinity_values.json. Validates everything at load time: a broken target,
## condition, affinity step or placeholder is reported in `errors` (and with
## push_error), never discovered mid-play. Implements Story 002
## (production/epics/uncharles/story-002-dialogue-affinity.md).
##
## Each node dictionary keeps its file fields (id, speaker, text, next, choices,
## battle, on_*, condition, then, else, end, affinity, set_flag, action, cut) and gains
## `scene` (its scene id) and `backdrop` (that scene's backdrop id, or "").

const INDEX_PATH: String = "res://assets/data/dialogue/index.json"
const VALUES_PATH: String = "res://assets/data/dialogue/affinity_values.json"
const MIN_CHOICES: int = 2
const MAX_CHOICES: int = 4
const FLOW_KEYS: PackedStringArray = ["next", "choices", "battle", "condition", "end"]
const PLACEHOLDER_PATTERN: String = "\\{([^{}]*)\\}"

## Node id -> node dictionary.
var nodes: Dictionary = {}
## Scene id -> id of its first node.
var scene_first: Dictionary = {}
## Affinity step ("++", "+", "0", "−") -> number.
var affinity_steps: Dictionary = {}
## Threshold name -> number.
var thresholds: Dictionary = {}
var candidates: Array = []
## Counter name -> starting value.
var counter_defaults: Dictionary = {}
var placeholder_names: Array = []
## Everything wrong with the data; empty when it is usable.
var errors: PackedStringArray = PackedStringArray()

var _conditions: Dictionary = {}


## Loads index.json, every file it lists and affinity_values.json.
static func load_default() -> DialogueData:
	var index: Dictionary = _read_json(INDEX_PATH)
	var files: Array = []
	for file_name: String in index.get("files", []):
		files.append(_read_json(INDEX_PATH.get_base_dir().path_join(file_name)))
	return from_dicts(files, _read_json(VALUES_PATH))


## Builds and validates from already parsed JSON: `files` is an array of
## {"scenes": [...]} dictionaries, `values` the affinity_values.json content.
static func from_dicts(files: Array, values: Dictionary) -> DialogueData:
	var data := DialogueData.new()
	data.affinity_steps = values.get("steps", {})
	data.thresholds = values.get("thresholds", {})
	data.candidates = values.get("candidates", [])
	data.counter_defaults = values.get("counter_defaults", {})
	data.placeholder_names = values.get("placeholders", [])
	for file: Dictionary in files:
		for scene: Dictionary in file.get("scenes", []):
			data._add_scene(scene)
	data._validate()
	for message in data.errors:
		push_error("DialogueData: " + message)
	return data


## True when loading found no errors.
func is_valid() -> bool:
	return errors.is_empty()


## The node with `id`, or an empty dictionary.
func get_node_data(id: String) -> Dictionary:
	return nodes.get(id, {})


## Id of the node to run for `entry`, which is a node id or a scene id; "" when
## it is neither.
func resolve_entry(entry: String) -> String:
	if nodes.has(entry):
		return entry
	return scene_first.get(entry, "")


## The parsed condition of node or choice dictionary `item`, or null.
func condition_of(item: Dictionary) -> DialogueCondition:
	return _conditions.get(item.get("condition", ""))


## Numeric value of affinity step `step` ("++", "+", "0", "−").
func step_value(step: String) -> int:
	return int(affinity_steps.get(step, 0))


static func _read_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not parsed is Dictionary:
		push_error("DialogueData: cannot read %s" % path)
		return {}
	return parsed


func _add_scene(scene: Dictionary) -> void:
	var scene_id: String = scene.get("id", "")
	if scene_first.has(scene_id) or nodes.has(scene_id):
		errors.append("scene id '%s' is used twice" % scene_id)
	var scene_nodes: Array = scene.get("nodes", [])
	if scene_nodes.is_empty():
		errors.append("scene '%s' has no nodes" % scene_id)
		return
	scene_first[scene_id] = scene_nodes[0].get("id", "")
	for node: Dictionary in scene_nodes:
		var id: String = node.get("id", "")
		if nodes.has(id) or scene_first.has(id):
			errors.append("node id '%s' is used twice" % id)
		node["scene"] = scene_id
		node["backdrop"] = scene.get("backdrop", "")
		nodes[id] = node


func _validate() -> void:
	var set_flags: Dictionary = {}
	for node: Dictionary in nodes.values():
		for item: Dictionary in [node] + node.get("choices", []):
			if item.has("set_flag"):
				set_flags[item.set_flag] = true
	var vocabulary: Dictionary = {"candidates": candidates, "counters": counter_defaults, "thresholds": thresholds}
	for node: Dictionary in nodes.values():
		_validate_node(node, vocabulary, set_flags)


func _validate_node(node: Dictionary, vocabulary: Dictionary, set_flags: Dictionary) -> void:
	var id: String = node.id
	var used: Array[String] = []
	for key in FLOW_KEYS:
		if node.has(key):
			used.append(key)
	if used.size() != 1:
		errors.append("node '%s' needs exactly one of next/choices/battle/condition/end" % id)
		return
	match used[0]:
		"next":
			_check_target(id, node.next)
		"condition":
			_check_condition(id, node, vocabulary, set_flags)
			_check_target(id, node.get("then", ""))
			_check_target(id, node.get("else", ""))
		"battle":
			for key: String in ["on_persuaded", "on_defeated", "on_depleted"]:
				_check_target(id, node.get(key, ""))
		"choices":
			_validate_choices(node, vocabulary, set_flags)
	if used[0] != "condition":
		_check_text(id, node.get("text", ""))
		_check_affinity(id, node)


func _validate_choices(node: Dictionary, vocabulary: Dictionary, set_flags: Dictionary) -> void:
	var id: String = node.id
	var choices: Array = node.choices
	if choices.size() < MIN_CHOICES or choices.size() > MAX_CHOICES:
		errors.append("node '%s' has %d choices (need %d-%d)" % [id, choices.size(), MIN_CHOICES, MAX_CHOICES])
	var unconditional: int = 0
	for choice: Dictionary in choices:
		_check_target(id, choice.get("next", ""))
		_check_text(id, choice.get("text", ""))
		_check_affinity(id, choice)
		if choice.has("condition"):
			_check_condition(id, choice, vocabulary, set_flags)
		else:
			unconditional += 1
	if unconditional == 0:
		errors.append("node '%s' has no choice that is always available" % id)


func _check_target(from_id: String, target: String) -> void:
	if not nodes.has(target) and not scene_first.has(target):
		errors.append("node '%s' points to unknown node or scene '%s'" % [from_id, target])


func _check_condition(from_id: String, item: Dictionary, vocabulary: Dictionary, set_flags: Dictionary) -> void:
	var expression: String = item.condition
	var condition: DialogueCondition = DialogueCondition.parse(expression, vocabulary)
	if not condition.error.is_empty():
		errors.append("node '%s' condition '%s': %s" % [from_id, expression, condition.error])
		return
	for flag_name in condition.flags_read:
		if not set_flags.has(flag_name):
			errors.append("node '%s' condition '%s' reads flag '%s' that no node sets" % [from_id, expression, flag_name])
	_conditions[expression] = condition


func _check_affinity(from_id: String, item: Dictionary) -> void:
	var change: Dictionary = item.get("affinity", {})
	for candidate: String in change:
		if not candidate in candidates:
			errors.append("node '%s' changes affinity of unknown candidate '%s'" % [from_id, candidate])
		if not affinity_steps.has(change[candidate]):
			errors.append("node '%s' uses unknown affinity step '%s'" % [from_id, change[candidate]])


func _check_text(from_id: String, text: String) -> void:
	var regex := RegEx.create_from_string(PLACEHOLDER_PATTERN)
	for found in regex.search_all(text):
		if not found.get_string(1) in placeholder_names:
			errors.append("node '%s' uses unknown placeholder {%s}" % [from_id, found.get_string(1)])
