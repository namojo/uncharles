extends Control
## Story flow host: plays the dialogue in order and stands in for walking
## around until Story 003 builds exploration. Owns the backdrop, the dialogue
## box, a "map menu" (the places Charles could walk to), the AffinityStore and
## the hosted battle scene. Implements Story 002
## (production/epics/uncharles/story-002-dialogue-affinity.md).
##
## The order is data (assets/data/dialogue/flow.json): new game starts at
## `entry`; each scene's `end:` value is looked up in `end_routes` (open a map,
## start a scene, or return to the agency). Returning to the agency pays the
## job reward and counts the job (a stub of Story 003), unless Charles was
## rebooted: then `reboot_scene` plays. A DEPLETED battle restores the store to
## the snapshot taken when the job was accepted, keeps the reboot count up,
## takes `money_loss_ratio` of the money (floored) and refills the battery.
##
## Debug hooks, after `--`:
##   --choices=1,0,2   play automatically: confirm lines, and pick these
##                     indexes at each dialogue choice or map menu, in order.
##                     When the list runs out, the player gets control.
##   --fast            with --choices, also skip the typewriter.
##   --start=<id>      start at a scene id or node id (or `map:<map id>`),
##                     as if the first job in flow.json had been accepted.
##   --commands=...    passed through to every hosted battle (BattleUI).
## Example:
##   godot --path . res://src/flow/story_flow.tscn -- --start=job1_kitchen_door --choices=0,1 --commands=persuade_plead,persuade_plead,persuade_plead

enum Mode { DIALOGUE, MAP, BATTLE, CARD }

const ENEMY_PATH: String = "res://assets/data/battle/enemies/%s.tres"
const ARG_CHOICES: String = "--choices="
const ARG_START: String = "--start="
const ARG_FAST: String = "--fast"
const MAP_PREFIX: String = "map:"
const SEEN_FLAG: String = "seen_%s"

@export var palette: UiPalette
## Audio event id -> sound ("cursor", "confirm"). Empty plays no effects.
@export var sound_bank: SoundBank
## The battle scene hosted for `battle:` nodes (BattleUI).
@export var battle_scene: PackedScene
@export_file("*.json") var flow_path: String = "res://assets/data/dialogue/flow.json"
## How long a stub notice stays on screen.
@export var toast_sec: float = 2.0
## How long the end card ignores input, so the menu pick does not skip it.
@export var card_input_delay_sec: float = 0.5
## Pause between automatic steps of `--choices=`.
@export var auto_step_sec: float = 0.5

var _flow: Dictionary = {}
var _data: DialogueData
var _store: AffinityStore
var _runner: DialogueRunner
var _sound: SoundPlayer
var _mode: Mode = Mode.DIALOGUE
var _map_items: Array = []
## The accepted job (a flow.json `jobs` entry); empty when none.
var _job: Dictionary = {}
var _job_snapshot: Dictionary = {}
var _rebooted: bool = false
var _battle: BattleUI
var _battle_result: BattleState.Result = BattleState.Result.DEFEATED
var _battle_over: bool = false
var _card_shown_msec: int = 0

var _box: DialogueBox
var _backdrop: TextureRect
var _map_panel: PanelContainer
var _map_title: Label
var _map_list: ChoiceList
var _toast: PanelContainer
var _toast_label: Label
var _toast_timer: Timer
var _card: Control

var _auto_choices: Array[int] = []
var _auto_target: int = -1
var _auto_fast: bool = false
var _auto_timer: Timer


func _ready() -> void:
	assert(palette != null and battle_scene != null, "story flow needs a palette and a battle scene")
	var flow_json: Variant = JSON.parse_string(FileAccess.get_file_as_string(flow_path))
	if not flow_json is Dictionary:
		push_error("story flow: cannot read %s" % flow_path)
		return
	_flow = flow_json
	_data = DialogueData.load_default()
	if not _data.is_valid():
		return
	_store = AffinityStore.new(_data.counter_defaults)
	_runner = DialogueRunner.new(_data, _store)
	_runner.placeholders = {"charge_cost": int(_flow.charge_cost)}
	_runner.node_shown.connect(_on_node_shown)
	_runner.choices_presented.connect(func(labels: PackedStringArray) -> void: _box.show_choices(labels))
	_runner.action_requested.connect(_on_action_requested)
	_runner.battle_requested.connect(_start_battle)
	_runner.scene_ended.connect(_route_end)
	_sound = SoundPlayer.new()
	_sound.bank = sound_bank
	add_child(_sound)
	theme = UiStyle.make_theme(palette)
	_build_ui()
	_box.advance_requested.connect(func() -> void: _runner.advance())
	_box.choice_picked.connect(func(index: int) -> void: _runner.choose(index))
	var start: String = _parse_args()
	if start.is_empty():
		_start_dialogue(_flow.entry)
		return
	_accept_job(_flow.jobs[0])
	if start.begins_with(MAP_PREFIX):
		_open_map(start.trim_prefix(MAP_PREFIX))
	else:
		_start_dialogue(start)


func _unhandled_input(event: InputEvent) -> void:
	if _mode == Mode.CARD and event.is_action_pressed(&"ui_accept"):
		_leave_card()


func _input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if _mode == Mode.CARD and click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_leave_card()


func _start_dialogue(entry: String) -> void:
	_mode = Mode.DIALOGUE
	_map_panel.hide()
	var scene_id: String = _data.get_node_data(_data.resolve_entry(entry)).get("scene", "")
	for job: Dictionary in _flow.jobs:
		if job.board_scene == scene_id:
			_runner.placeholders["reward"] = int(job.reward)
	_runner.start(entry)


func _on_node_shown(node: Dictionary, text: String) -> void:
	_trace("node %s" % node.id)
	# A node's `cut` (a close-up for this line) wins over its scene's backdrop.
	_show_backdrop([node.get("cut", ""), node.backdrop, node.scene])
	_box.show_line(node.speaker, text)


func _on_action_requested(action: String, node: Dictionary) -> void:
	if action == "accept_job":
		for job: Dictionary in _flow.jobs:
			if job.board_scene == node.scene:
				_accept_job(job)
	else:
		_show_toast(_flow.stub_toast)


## Remembers the job and the state to roll back to if Charles is rebooted during it.
func _accept_job(job: Dictionary) -> void:
	_job = job
	_job_snapshot = _store.snapshot()


func _route_end(end_value: String) -> void:
	var route: Dictionary = _flow.end_routes.get(end_value, {})
	if route.has("map"):
		_open_map(route.map)
	elif route.has("scene"):
		_start_dialogue(route.scene)
	elif route.get("special", "") == "return_to_agency":
		_return_to_agency()
	else:
		_start_dialogue(end_value)


func _return_to_agency() -> void:
	if _rebooted:
		_rebooted = false
		_start_dialogue(_flow.reboot_scene)
		return
	_store.add_counter("money", int(_job.reward))
	_store.add_counter("jobs_completed", 1)
	_runner.placeholders["reward"] = int(_job.reward)
	var return_scene: String = _job.return_scene
	_job = {}
	_job_snapshot = {}
	_start_dialogue(return_scene)


func _open_map(map_id: String) -> void:
	_trace("map %s" % map_id)
	_mode = Mode.MAP
	_box.hide()
	var menu: Dictionary = _flow.maps[map_id]
	_map_items = (menu.items as Array).filter(func(item: Dictionary) -> bool:
		return not (item.get("once", false) and _store.has_flag(SEEN_FLAG % item.scene)))
	var labels := PackedStringArray()
	for item: Dictionary in _map_items:
		labels.append(item.label)
	_map_title.text = menu.title
	_show_backdrop([map_id])
	_map_list.show_options(labels)
	_map_panel.show()


func _on_map_picked(index: int) -> void:
	var item: Dictionary = _map_items[index]
	_map_panel.hide()
	if item.has("scene"):
		if item.get("once", false):
			_store.set_flag(SEEN_FLAG % item.scene)
		_start_dialogue(item.scene)
	else:
		_show_card()


func _start_battle(enemy_id: String) -> void:
	_mode = Mode.BATTLE
	_box.hide()
	_battle = battle_scene.instantiate()
	_battle.enemy = load(ENEMY_PATH % enemy_id)
	_battle.hosted = true
	_battle.battery_max = int(_flow.battery_max)
	_battle.battery_start = _store.get_counter("battery")
	# Fight where the scene happens: the living room, the kitchen, ...
	if _backdrop.texture != null:
		_battle.background = _backdrop.texture
	_battle_over = false
	_battle.battle_ended.connect(func(result: BattleState.Result) -> void:
		_battle_result = result
		_battle_over = true)
	_battle.result_acknowledged.connect(_on_battle_acknowledged)
	add_child(_battle)


func _on_battle_acknowledged() -> void:
	_trace("battle %s, battery %d" % [BattleState.Result.find_key(_battle_result), _battle.battery()])
	_store.set_counter("battery", _battle.battery())
	_battle.queue_free()
	_battle = null
	if _battle_result == BattleState.Result.DEPLETED:
		_reboot()
	_mode = Mode.DIALOGUE
	_runner.resolve_battle(_battle_result)


## Story 004 rule (job1-narae.md section 5 decision): the job goes back to its
## start and the affinity earned on this attempt is lost.
func _reboot() -> void:
	var money: int = _store.get_counter("money")
	var lost: int = floori(money * float(_flow.money_loss_ratio))
	var reboots: int = _store.get_counter("reboot_count") + 1
	if not _job_snapshot.is_empty():
		_store.restore(_job_snapshot)
	_store.set_counter("reboot_count", reboots)
	_store.set_counter("money", maxi(0, money - lost))
	_store.set_counter("battery", int(_flow.reboot_battery))
	_runner.placeholders["money_lost"] = lost
	_rebooted = true
	_job = {}
	_job_snapshot = {}
	_trace("reboot: %s" % _store.to_dict())


func _show_card() -> void:
	_mode = Mode.CARD
	_box.hide()
	_card.show()
	_card_shown_msec = Time.get_ticks_msec()


func _leave_card() -> void:
	if Time.get_ticks_msec() - _card_shown_msec < int(card_input_delay_sec * 1000.0):
		return
	_sound.play(&"confirm")
	_trace("end card -> title, store %s" % _store.to_dict())
	get_tree().change_scene_to_file(_flow.title_scene)


## Shows the texture of the first id that matches a flow.json `backdrops`
## pattern (exact id or glob); none matching shows the palette background.
func _show_backdrop(ids: Array) -> void:
	for id: String in ids:
		if id.is_empty():
			continue
		for pattern: String in _flow.backdrops:
			if id.match(pattern):
				_backdrop.texture = load(_flow.backdrops[pattern])
				return
	_backdrop.texture = null


## Prints flow progress while `--choices=` drives it (headless checks).
func _trace(message: String) -> void:
	if _auto_timer != null:
		print("story_flow: ", message)


func _show_toast(text: String) -> void:
	_toast_label.text = text
	_toast.show()
	_toast_timer.start(toast_sec)


func _parse_args() -> String:
	var start: String = ""
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(ARG_CHOICES):
			for part in arg.trim_prefix(ARG_CHOICES).split(",", false):
				_auto_choices.append(part.to_int())
			_auto_timer = Timer.new()
			_auto_timer.wait_time = auto_step_sec
			_auto_timer.timeout.connect(_auto_step)
			add_child(_auto_timer)
			_auto_timer.start()
		elif arg.begins_with(ARG_START):
			start = arg.trim_prefix(ARG_START)
		elif arg == ARG_FAST:
			_auto_fast = true
	return start


## One step of `--choices=`: the same calls a key press or tap makes.
func _auto_step() -> void:
	match _mode:
		Mode.DIALOGUE:
			var list: ChoiceList = _box.open_choices()
			if list != null:
				_auto_pick(list)
			elif _box.is_waiting() or (_auto_fast and _box.is_typing()):
				_box.activate()
		Mode.MAP:
			_auto_pick(_map_list)
		Mode.BATTLE:
			if _battle_over:
				var press := InputEventAction.new()
				press.action = &"ui_accept"
				press.pressed = true
				Input.parse_input_event(press)
		Mode.CARD:
			_leave_card()


## Moves the cursor to the next scripted index on one step, confirms on the next.
func _auto_pick(list: ChoiceList) -> void:
	if _auto_target >= 0:
		_auto_target = -1
		list.confirm()
		return
	if _auto_choices.is_empty():
		print("story_flow: --choices used up; the player has control")
		_auto_timer.stop()
		return
	_auto_target = _auto_choices.pop_front()
	list.set_cursor(_auto_target)


func _build_ui() -> void:
	var fill := ColorRect.new()
	fill.color = palette.background
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	move_child(fill, 0)
	_backdrop = UiStyle.make_backdrop(null)
	add_child(_backdrop)
	move_child(_backdrop, 1)

	_box = $DialogueBox
	_box.sound = _sound
	_box.hide()

	_map_panel = PanelContainer.new()
	_map_panel.set_anchors_preset(Control.PRESET_CENTER)
	_map_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_map_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_map_panel.custom_minimum_size = Vector2(480, 0)
	_map_panel.hide()
	add_child(_map_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 8)
	_map_panel.add_child(column)
	_map_title = Label.new()
	_map_title.add_theme_font_override(&"font", UiStyle.crisp(palette.font_bold))
	_map_title.add_theme_color_override(&"font_color", palette.reward)
	column.add_child(_map_title)
	_map_list = ChoiceList.new()
	_map_list.palette = palette
	_map_list.sound = _sound
	_map_list.picked.connect(_on_map_picked)
	column.add_child(_map_list)

	_toast = PanelContainer.new()
	_toast.add_theme_stylebox_override(&"panel", UiStyle.caption_style(palette))
	_toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_toast.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_toast.offset_top = palette.screen_margin
	_toast.hide()
	add_child(_toast)
	_toast_label = Label.new()
	_toast.add_child(_toast_label)
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.timeout.connect(_toast.hide)
	add_child(_toast_timer)

	_card = ColorRect.new()
	(_card as ColorRect).color = palette.background
	_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	_card.hide()
	add_child(_card)
	var card_column := VBoxContainer.new()
	card_column.set_anchors_preset(Control.PRESET_CENTER)
	card_column.grow_horizontal = Control.GROW_DIRECTION_BOTH
	card_column.grow_vertical = Control.GROW_DIRECTION_BOTH
	card_column.add_theme_constant_override(&"separation", 24)
	_card.add_child(card_column)
	var card_text := Label.new()
	card_text.text = _flow.end_card.text
	card_text.add_theme_font_size_override(&"font_size", palette.size_emphasis)
	card_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_column.add_child(card_text)
	var card_hint := Label.new()
	card_hint.text = _flow.end_card.hint
	card_hint.add_theme_color_override(&"font_color", palette.text_secondary)
	card_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card_column.add_child(card_hint)
