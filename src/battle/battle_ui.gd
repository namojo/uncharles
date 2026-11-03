extends Control
## Battle screen. Presentation only: it feeds Charles' command choices into
## BattleState and shows what the rules report. Implements Story 001
## (production/epics/uncharles/story-001-battle-persuade.md); the look follows
## design/art/art-bible.md section 7.
##
## Keyboard: ui_up / ui_down move the cursor, ui_accept picks a command. Mouse
## and touch: hovering a command row moves the cursor, clicking or tapping it
## picks. On the result screen ui_accept or a click/tap restarts the scene and
## ui_cancel quits (quit is not offered in a web build). This is the standalone
## test harness; a caller embedding the scene listens to `battle_ended` instead.
##
## Debug hook: pass `--commands=id1,id2,...` after `--` to play those command
## ids automatically through the same choice path, e.g.
##   godot --path . --windowed --resolution 1280x720 res://src/battle/battle_scene.tscn -- --commands=a,b,c
## Without the argument the battle is interactive. If the ids run out before the
## battle ends, control returns to the player.

## Re-emits BattleState.battle_ended for whoever hosts this scene (Story 002).
signal battle_ended(result: BattleState.Result)

const SCRIPT_ARG_PREFIX: String = "--commands="
const CURSOR_MARK: String = "▶"
const KIND_TAGS: Dictionary = {
	BattleCommand.Kind.ATTACK: "공격",
	BattleCommand.Kind.PERSUADE: "설득",
	BattleCommand.Kind.DEFEND: "방어",
}
const RESULT_TITLES: Dictionary = {
	BattleState.Result.DEFEATED: "제압 승리",
	BattleState.Result.PERSUADED: "설득 승리",
	BattleState.Result.DEPLETED: "방전 패배",
}
## Sprites are drawn at twice their source pixels (art bible 7.1: 1 px = 2 screen px).
const SPRITE_SCALE: int = 2
## Gap between each screen edge and the sprite standing nearest it.
const STAGE_INSET: int = 200

## Enemy for this fight.
@export var enemy: BattleEnemy
## Charles' battle sprite. Empty shows a gray box instead.
@export var charles_portrait: Texture2D
## Charles' commands, in menu order.
@export var commands: Array[BattleCommand] = []
## Colours, fonts and sizes shared with every screen.
@export var palette: UiPalette
## Where the fight happens. Empty shows the palette background colour.
@export var background: Texture2D
@export var battery_max: int = 100
@export var battery_start: int = 100
## Pause between Charles' action and the enemy's reply.
@export var enemy_turn_delay_sec: float = 0.9
## Pause before each `--commands=` step.
@export var auto_step_delay_sec: float = 1.2
## How long the result screen ignores restart input, so a double tap on the
## winning command does not skip the result.
@export var result_input_delay_sec: float = 0.5

var _state: BattleState
var _cursor: int = 0
var _busy: bool = false
var _scripted: bool = false
var _ended_at_msec: int = 0

var _menu_rows: Array[PanelContainer] = []
var _menu_cursors: Array[Label] = []
var _menu_names: Array[Label] = []
var _result_label: Label
var _result_hint: Label
var _turn_label: Label
var _battery_label: Label
var _battery_bar: ProgressBar
var _hp_label: Label
var _hp_bar: ProgressBar
var _persuade_label: Label
var _persuade_bar: ProgressBar
var _log: RichTextLabel


func _ready() -> void:
	assert(enemy != null and not commands.is_empty(), "battle scene needs an enemy and at least one command")
	assert(palette != null, "battle scene needs a UiPalette")
	_state = BattleState.new(enemy, battery_max, battery_start)
	_state.line_logged.connect(_on_line_logged)
	_state.battle_ended.connect(_on_battle_ended)
	theme = UiStyle.make_theme(palette)
	_build_ui()
	_refresh()
	_on_line_logged(enemy.intro_line)
	var script_ids: PackedStringArray = _parse_script_ids()
	if not script_ids.is_empty():
		_run_script(script_ids)


## A tap anywhere on the result screen restarts. Read here rather than in
## _unhandled_input because the panels under the finger consume mouse events.
func _input(event: InputEvent) -> void:
	if _can_restart() and _is_left_press(event):
		get_tree().reload_current_scene()


func _unhandled_input(event: InputEvent) -> void:
	if _busy or _scripted:
		return
	if _state.is_ended():
		if not _can_restart():
			return
		if event.is_action_pressed(&"ui_accept"):
			get_tree().reload_current_scene()
		elif event.is_action_pressed(&"ui_cancel") and not OS.has_feature("web"):
			get_tree().quit()
		return
	if event.is_action_pressed(&"ui_down", true):
		_move_cursor(1)
	elif event.is_action_pressed(&"ui_up", true):
		_move_cursor(-1)
	elif event.is_action_pressed(&"ui_accept"):
		_choose(_cursor)


## The single path every command takes, from the keyboard or from `--commands=`.
func _choose(index: int) -> void:
	_busy = true
	_state.player_act(commands[index])
	_refresh()
	if not _state.is_ended():
		await get_tree().create_timer(enemy_turn_delay_sec).timeout
		_state.enemy_act()
		_refresh()
	_busy = false


func _run_script(ids: PackedStringArray) -> void:
	_scripted = true
	for id: String in ids:
		if _state.is_ended():
			break
		var index: int = commands.find_custom(func(c: BattleCommand) -> bool: return c.id == StringName(id))
		if index < 0:
			push_error("--commands: unknown command id '%s'" % id)
			break
		await get_tree().create_timer(auto_step_delay_sec).timeout
		_cursor = index
		_refresh_menu()
		await get_tree().create_timer(auto_step_delay_sec * 0.5).timeout
		await _choose(index)
	_scripted = false


func _parse_script_ids() -> PackedStringArray:
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with(SCRIPT_ARG_PREFIX):
			return arg.trim_prefix(SCRIPT_ARG_PREFIX).split(",", false)
	return PackedStringArray()


func _move_cursor(step: int) -> void:
	_cursor = posmod(_cursor + step, commands.size())
	_refresh_menu()


func _point_at(index: int) -> void:
	if _busy or _scripted or _state.is_ended():
		return
	_cursor = index
	_refresh_menu()


func _on_row_input(event: InputEvent, index: int) -> void:
	if _busy or _scripted or _state.is_ended() or not _is_left_press(event):
		return
	_cursor = index
	_choose(index)


func _can_restart() -> bool:
	return _state.is_ended() and not _scripted \
			and Time.get_ticks_msec() - _ended_at_msec >= int(result_input_delay_sec * 1000.0)


func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT


func _on_line_logged(text: String) -> void:
	_log.add_text(text + "\n")


func _on_battle_ended(result: BattleState.Result) -> void:
	for row in _menu_rows:
		row.hide()
	_result_label.text = RESULT_TITLES[result]
	_result_label.add_theme_color_override(&"font_color", palette.danger if result == BattleState.Result.DEPLETED else palette.reward)
	_result_label.show()
	_result_hint.show()
	_ended_at_msec = Time.get_ticks_msec()
	battle_ended.emit(result)


func _refresh() -> void:
	_turn_label.text = "턴 %d" % _state.turn_number
	_battery_label.text = "배터리 %d%%" % _state.battery
	if _state.guard_percent > 0:
		_battery_label.text += "   방어 %d%%" % _state.guard_percent
	_battery_bar.value = _state.battery
	_hp_label.text = "HP %d / %d" % [_state.enemy_hp, enemy.max_hp]
	_hp_bar.value = _state.enemy_hp
	_persuade_label.text = "설득 %d / %d" % [_state.persuade_gauge, enemy.persuade_max]
	_persuade_bar.value = _state.persuade_gauge
	_refresh_menu()


func _refresh_menu() -> void:
	for i in commands.size():
		var selected: bool = i == _cursor
		_menu_rows[i].add_theme_stylebox_override(&"panel", UiStyle.row_style(palette, selected))
		_menu_cursors[i].modulate.a = 1.0 if selected else 0.0
		_menu_names[i].add_theme_font_override(&"font", UiStyle.crisp(palette.font_bold if selected else palette.font_regular))
		_menu_names[i].add_theme_color_override(&"font_color", palette.text_body if selected else palette.text_secondary)


func _kind_color(kind: BattleCommand.Kind) -> Color:
	match kind:
		BattleCommand.Kind.ATTACK:
			return palette.gauge_enemy_hp
		BattleCommand.Kind.PERSUADE:
			return palette.gauge_persuade
	return palette.gauge_battery


func _build_ui() -> void:
	var fill := ColorRect.new()
	fill.color = palette.background
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	if background != null:
		add_child(UiStyle.make_backdrop(background))

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, palette.screen_margin)
	add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override(&"separation", palette.panel_gap)
	margin.add_child(root)

	# Top HUD row: Charles left, enemy right.
	var hud := HBoxContainer.new()
	hud.add_theme_constant_override(&"separation", palette.panel_gap)
	root.add_child(hud)

	var charles_box := _add_panel(hud)
	var charles_head := HBoxContainer.new()
	charles_box.add_child(charles_head)
	var charles_name := _add_label(charles_head, "찰스", palette.font_bold)
	charles_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_turn_label = _add_label(charles_head, "", palette.font_regular, palette.text_secondary)
	_battery_label = _add_label(charles_box, "", palette.font_regular)
	_battery_bar = UiStyle.make_gauge(palette, battery_max, palette.gauge_battery)
	charles_box.add_child(_battery_bar)

	var enemy_box := _add_panel(hud)
	_add_label(enemy_box, enemy.display_name, palette.font_bold)
	_hp_label = _add_label(enemy_box, "", palette.font_regular)
	_hp_bar = UiStyle.make_gauge(palette, enemy.max_hp, palette.gauge_enemy_hp)
	enemy_box.add_child(_hp_bar)
	_persuade_label = _add_label(enemy_box, "", palette.font_regular)
	_persuade_bar = UiStyle.make_gauge(palette, enemy.persuade_max, palette.gauge_persuade)
	enemy_box.add_child(_persuade_bar)

	# Stage: the two sprites stand on the kitchen floor.
	var stage := HBoxContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stage)
	# Inset from the edges so both stand in the lit middle of the floor, clear of props.
	var inset_left := Control.new()
	inset_left.custom_minimum_size = Vector2(STAGE_INSET, 0)
	stage.add_child(inset_left)
	_add_actor(stage, "찰스", Color(0.55, 0.60, 0.65), charles_portrait)
	var stage_gap := Control.new()
	stage_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_child(stage_gap)
	_add_actor(stage, enemy.display_name, Color(0.65, 0.55, 0.55), enemy.portrait)
	var inset_right := Control.new()
	inset_right.custom_minimum_size = Vector2(STAGE_INSET, 0)
	stage.add_child(inset_right)

	# Bottom row: commands left (440 wide), log right.
	var bottom := HBoxContainer.new()
	bottom.custom_minimum_size = Vector2(0, 216)
	bottom.add_theme_constant_override(&"separation", palette.panel_gap)
	root.add_child(bottom)

	var menu_box := _add_panel(bottom)
	menu_box.get_parent().size_flags_horizontal = Control.SIZE_FILL
	menu_box.get_parent().custom_minimum_size = Vector2(440, 0)
	menu_box.add_theme_constant_override(&"separation", 0)
	for command in commands:
		var row := PanelContainer.new()
		var index: int = _menu_rows.size()
		row.mouse_entered.connect(_point_at.bind(index))
		row.gui_input.connect(_on_row_input.bind(index))
		menu_box.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 8)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(line)
		var cursor := _add_label(line, CURSOR_MARK, palette.font_regular, palette.accent)
		var tag := _add_label(line, KIND_TAGS[command.kind], palette.font_bold, _kind_color(command.kind))
		tag.custom_minimum_size = Vector2(56, 0)
		var command_name := _add_label(line, command.display_name, palette.font_regular)
		_menu_rows.append(row)
		_menu_cursors.append(cursor)
		_menu_names.append(command_name)
	_result_label = _add_label(menu_box, "", palette.font_bold)
	_result_label.add_theme_font_size_override(&"font_size", palette.size_banner)
	_result_label.hide()
	var hint: String = "탭 또는 Enter: 다시 하기" if OS.has_feature("web") else "클릭 또는 Enter: 다시 하기    Esc: 종료"
	_result_hint = _add_label(menu_box, hint, palette.font_regular, palette.text_secondary)
	_result_hint.hide()

	var log_box := _add_panel(bottom)
	_log = RichTextLabel.new()
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# Keep focus off the log so ui_up/ui_down always reach _unhandled_input.
	_log.focus_mode = Control.FOCUS_NONE
	log_box.add_child(_log)


## A panel that expands sideways; returns the column inside it.
func _add_panel(parent: Control) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override(&"separation", 4)
	panel.add_child(column)
	return column


## Shows `portrait` at twice its pixels, standing on the stage floor, or a
## named gray box when there is no portrait yet.
func _add_actor(parent: Control, actor_name: String, color: Color, portrait: Texture2D) -> void:
	if portrait == null:
		var box := ColorRect.new()
		box.color = color
		box.custom_minimum_size = Vector2(200, 200)
		box.size_flags_vertical = Control.SIZE_SHRINK_END
		parent.add_child(box)
		var name_label := _add_label(box, actor_name, palette.font_regular)
		name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return
	var sprite := TextureRect.new()
	sprite.texture = portrait
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.custom_minimum_size = portrait.get_size() * SPRITE_SCALE
	sprite.size_flags_vertical = Control.SIZE_SHRINK_END
	parent.add_child(sprite)


func _add_label(parent: Control, text: String, font: Font, color: Color = palette.text_body) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", UiStyle.crisp(font))
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", palette.border_ink)
	label.add_theme_constant_override(&"outline_size", palette.text_outline)
	parent.add_child(label)
	return label
