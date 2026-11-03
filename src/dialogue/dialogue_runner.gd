class_name DialogueRunner
extends RefCounted
## Walks dialogue nodes. No scene tree, no UI: it reports what to show through
## signals and takes the player's input through `advance()`, `choose()` and
## `resolve_battle()`. Implements Story 002
## (production/epics/uncharles/story-002-dialogue-affinity.md); the node format
## is design/narrative/dialogue/job1-narae.md section 0.
##
## Entering a node, in this order: condition nodes are resolved silently (they
## have no text); the node's `affinity` and `set_flag` are applied; its `action`
## is emitted; then `node_shown` (and `choices_presented` for a choice node).
## What happens after the line is read depends on the node:
##   next    -> `advance()` enters the next node
##   choices -> `choose(index)` applies the choice's affinity / flag, enters its `next`
##   battle  -> `advance()` emits `battle_requested`; the host fights, then calls
##              `resolve_battle(result)` to continue at on_persuaded / on_defeated / on_depleted
##   end     -> `advance()` emits `scene_ended(end value)`; the host decides what comes next
##
## State transitions (TRANSITIONS):
##   IDLE      -> SHOWING | CHOOSING   start()
##   SHOWING   -> SHOWING | CHOOSING | IN_BATTLE | ENDED   advance()
##   CHOOSING  -> SHOWING | CHOOSING   choose()
##   IN_BATTLE -> SHOWING | CHOOSING   resolve_battle()
##   ENDED     -> SHOWING | CHOOSING   start() again

enum State { IDLE, SHOWING, CHOOSING, IN_BATTLE, ENDED }

const TRANSITIONS: Dictionary = {
	State.IDLE: [State.SHOWING, State.CHOOSING],
	State.SHOWING: [State.SHOWING, State.CHOOSING, State.IN_BATTLE, State.ENDED],
	State.CHOOSING: [State.SHOWING, State.CHOOSING],
	State.IN_BATTLE: [State.SHOWING, State.CHOOSING],
	State.ENDED: [State.SHOWING, State.CHOOSING],
}
const BATTLE_TARGETS: Dictionary = {
	BattleState.Result.PERSUADED: "on_persuaded",
	BattleState.Result.DEFEATED: "on_defeated",
	BattleState.Result.DEPLETED: "on_depleted",
}
const PLACEHOLDER_PATTERN: String = "\\{([^{}]*)\\}"

## A line is on screen. `text` has its placeholders filled.
signal node_shown(node: Dictionary, text: String)
## The visible choice labels of the node just shown, in the order `choose()` takes.
signal choices_presented(labels: PackedStringArray)
## A node asked for `action` (accept_job, charge_battery, save_game). The host does the work.
signal action_requested(action: String, node: Dictionary)
## The player advanced past a battle node; the host runs the fight.
signal battle_requested(enemy_id: String)
## The scene is over; `end_value` is the node's `end:` text.
signal scene_ended(end_value: String)

var state: State = State.IDLE
## Placeholder values the host injects ({reward}, {money_lost}, {charge_cost}).
## Names not found here are read from the store's counters ({money}, {reboot_count}).
var placeholders: Dictionary = {}

var _data: DialogueData
var _store: AffinityStore
var _current: Dictionary = {}
var _presented: Array = []
var _regex: RegEx = RegEx.create_from_string(PLACEHOLDER_PATTERN)


func _init(data: DialogueData, store: AffinityStore) -> void:
	assert(data.is_valid(), "dialogue data has errors")
	_data = data
	_store = store


## The node on screen (empty when none).
func current_node() -> Dictionary:
	return _current


## Starts at `entry`, a scene id or a node id. False (and an error) for an unknown entry.
func start(entry: String) -> bool:
	var id: String = _data.resolve_entry(entry)
	if id.is_empty():
		push_error("DialogueRunner: unknown entry '%s'" % entry)
		return false
	_enter(id)
	return true


## The player has read the line (no choices). False outside SHOWING.
func advance() -> bool:
	if state != State.SHOWING:
		return false
	if _current.has("end"):
		_transition_to(State.ENDED)
		scene_ended.emit(_current.end)
	elif _current.has("battle"):
		_transition_to(State.IN_BATTLE)
		battle_requested.emit(_current.battle)
	else:
		_enter(_data.resolve_entry(_current.next))
	return true


## The player picked visible choice `index`. False outside CHOOSING or out of range.
func choose(index: int) -> bool:
	if state != State.CHOOSING or index < 0 or index >= _presented.size():
		return false
	var choice: Dictionary = _presented[index]
	_apply_effects(choice)
	_enter(_data.resolve_entry(choice.next))
	return true


## The host finished the fight requested by `battle_requested`. False outside IN_BATTLE.
func resolve_battle(result: BattleState.Result) -> bool:
	if state != State.IN_BATTLE:
		return false
	_enter(_data.resolve_entry(_current[BATTLE_TARGETS[result]]))
	return true


func _enter(id: String) -> void:
	var node: Dictionary = _data.get_node_data(id)
	while node.has("condition"):
		var holds: bool = _data.condition_of(node).evaluate(_store)
		node = _data.get_node_data(_data.resolve_entry(node.then if holds else node["else"]))
	_current = node
	_apply_effects(node)
	if node.has("action"):
		action_requested.emit(node.action, node)
	_presented = []
	if node.has("choices"):
		for choice: Dictionary in node.choices:
			var condition: DialogueCondition = _data.condition_of(choice)
			if condition == null or condition.evaluate(_store):
				_presented.append(choice)
	_transition_to(State.CHOOSING if node.has("choices") else State.SHOWING)
	node_shown.emit(node, _fill(node.text))
	if node.has("choices"):
		var labels := PackedStringArray()
		for choice: Dictionary in _presented:
			labels.append(_fill(choice.text))
		choices_presented.emit(labels)


func _apply_effects(item: Dictionary) -> void:
	var change: Dictionary = item.get("affinity", {})
	for candidate: String in change:
		_store.add_affinity(candidate, _data.step_value(change[candidate]))
	if item.has("set_flag"):
		_store.set_flag(item.set_flag)


func _fill(text: String) -> String:
	var result: String = text
	for found in _regex.search_all(text):
		var key: String = found.get_string(1)
		if placeholders.has(key):
			result = result.replace(found.get_string(), str(placeholders[key]))
		elif _data.counter_defaults.has(key):
			result = result.replace(found.get_string(), str(_store.get_counter(key)))
		else:
			push_error("DialogueRunner: no value for placeholder {%s}" % key)
	return result


func _transition_to(next: State) -> void:
	assert(next in TRANSITIONS[state], "illegal dialogue state transition")
	state = next
