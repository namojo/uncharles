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
## Audio event id -> sound ("hit", "persuade", ...). Empty plays no effects.
@export var sound_bank: SoundBank
## Looping battle music. Empty plays none.
@export var music: AudioStream
## Battery at or below this percent blinks its gauge (art bible 7.9: low power).
@export var low_battery_percent: int = 25

## Low-battery gauge blink half-period (art bible 7.9: 400 ms).
const LOW_BATTERY_BLINK_SEC: float = 0.4
## Persuade-full blink before the result banner (art bible 7.9: twice).
const PERSUADE_FULL_BLINKS: int = 2
const PERSUADE_FULL_BLINK_SEC: float = 0.1

var _state: BattleState
var _cursor: int = 0
var _busy: bool = false
var _scripted: bool = false
var _ended_at_msec: int = 0
var _result_shown: bool = false
var _result: BattleState.Result = BattleState.Result.DEFEATED
var _sound: SoundPlayer

var _menu_rows: Array[PanelContainer] = []
var _menu_cursors: Array[Label] = []
var _menu_names: Array[Label] = []
var _result_box: Control
var _result_label: Label
var _result_hint: Label
var _turn_label: Label
var _battery_label: Label
var _battery_bar: SteppedGauge
var _hp_label: Label
var _hp_bar: SteppedGauge
var _persuade_label: Label
var _persuade_bar: SteppedGauge
var _log: RichTextLabel
var _charles_sprite: Control
var _enemy_sprite: Control
## Floating damage numbers draw here, above everything else.
var _fx_layer: Control


func _ready() -> void:
	assert(enemy != null and not commands.is_empty(), "battle scene needs an enemy and at least one command")
	assert(palette != null, "battle scene needs a UiPalette")
	_state = BattleState.new(enemy, battery_max, battery_start)
	_state.line_logged.connect(_on_line_logged)
	_state.battle_ended.connect(_on_battle_ended)
	_sound = SoundPlayer.new()
	_sound.bank = sound_bank
	_sound.music = music
	add_child(_sound)
	theme = UiStyle.make_theme(palette)
	_build_ui()
	_refresh(false)
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


## The single path every command takes, from the keyboard, a tap or `--commands=`.
## The rules resolve at once; the screen then plays the turn out in steps.
func _choose(index: int) -> void:
	_busy = true
	_sound.play(&"confirm")
	var command: BattleCommand = commands[index]
	var before: Dictionary = _snapshot()
	_state.player_act(command)
	await _play_player_action(command, before)
	if not _state.is_ended():
		await get_tree().create_timer(enemy_turn_delay_sec).timeout
		before = _snapshot()
		_state.enemy_act()
		await _play_enemy_action(before)
	if _state.is_ended():
		await _show_result()
	_busy = false


func _snapshot() -> Dictionary:
	return {hp = _state.enemy_hp, persuade = _state.persuade_gauge, battery = _state.battery}


func _play_player_action(command: BattleCommand, before: Dictionary) -> void:
	match command.kind:
		BattleCommand.Kind.ATTACK:
			_sound.play(&"swing")
			await BattleFx.lunge_out(_charles_sprite, 1)
			_sound.play(&"hit")
			_pop(_enemy_sprite, "-%d" % (before.hp - _state.enemy_hp), palette.gauge_enemy_hp)
			_refresh()
			await BattleFx.hit(_enemy_sprite)
			await BattleFx.lunge_back(_charles_sprite, 1)
		BattleCommand.Kind.PERSUADE:
			_sound.play(&"persuade")
			await BattleFx.hop(_charles_sprite)
			_pop(_enemy_sprite, "설득 +%d" % (_state.persuade_gauge - before.persuade), palette.gauge_persuade)
			_refresh()
			await BattleFx.hop(_enemy_sprite)
		BattleCommand.Kind.DEFEND:
			_sound.play(&"guard")
			_pop(_charles_sprite, "방어 %d%%" % _state.guard_percent, palette.gauge_battery)
			_refresh()
			await BattleFx.bow(_charles_sprite)


func _play_enemy_action(before: Dictionary) -> void:
	_sound.play(&"enemy_attack")
	await BattleFx.lunge_out(_enemy_sprite, -1)
	_sound.play(&"hurt")
	_pop(_charles_sprite, "-%d%%" % (before.battery - _state.battery), palette.gauge_battery)
	_refresh()
	await BattleFx.hit(_charles_sprite)
	await BattleFx.lunge_back(_enemy_sprite, -1)


## Plays the ending for `_result`, shows the banner, then tells the host.
func _show_result() -> void:
	for row in _menu_rows:
		row.hide()
	_sound.stop_music()
	match _result:
		BattleState.Result.PERSUADED:
			await _persuade_bar.flash(PERSUADE_FULL_BLINKS, PERSUADE_FULL_BLINK_SEC)
			_sound.play(&"victory")
		BattleState.Result.DEFEATED:
			_sound.play(&"enemy_down")
			await BattleFx.blink_out(_enemy_sprite)
			_sound.play(&"victory")
		BattleState.Result.DEPLETED:
			_sound.play(&"power_down")
			await BattleFx.power_down(_charles_sprite)
	_result_label.text = RESULT_TITLES[_result]
	_result_label.add_theme_color_override(&"font_color", palette.danger if _result == BattleState.Result.DEPLETED else palette.reward)
	_result_box.show()
	_result_label.hide()
	# Let the menu column re-lay out without the rows before the banner drops.
	await get_tree().process_frame
	await BattleFx.drop_in(_result_label)
	_result_hint.show()
	_result_shown = true
	_ended_at_msec = Time.get_ticks_msec()
	battle_ended.emit(_result)


func _pop(anchor: Control, text: String, color: Color) -> void:
	BattleFx.pop_number(_fx_layer, anchor, text, color, UiStyle.crisp(palette.font_bold), palette.size_emphasis, palette.border_ink)


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
	_sound.play(&"cursor")
	_refresh_menu()


func _point_at(index: int) -> void:
	if _busy or _scripted or _state.is_ended() or index == _cursor:
		return
	_cursor = index
	_sound.play(&"cursor")
	_refresh_menu()


func _on_row_input(event: InputEvent, index: int) -> void:
	if _busy or _scripted or _state.is_ended() or not _is_left_press(event):
		return
	_cursor = index
	_choose(index)


func _can_restart() -> bool:
	return _result_shown and not _scripted \
			and Time.get_ticks_msec() - _ended_at_msec >= int(result_input_delay_sec * 1000.0)


func _is_left_press(event: InputEvent) -> bool:
	var click := event as InputEventMouseButton
	return click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT


func _on_line_logged(text: String) -> void:
	_log.add_text(text + "\n")


## The rules ended the fight; the screen shows it once the turn has played out
## (_show_result), and only then emits `battle_ended`.
func _on_battle_ended(result: BattleState.Result) -> void:
	_result = result


## Copies the rules' numbers onto the HUD. `animate` false skips the gauge afterimage.
func _refresh(animate: bool = true) -> void:
	_turn_label.text = "턴 %d" % _state.turn_number
	_battery_label.text = "배터리 %d%%" % _state.battery
	if _state.guard_percent > 0:
		_battery_label.text += "   방어 %d%%" % _state.guard_percent
	_battery_bar.set_value(_state.battery, animate)
	_battery_bar.set_warning(_state.battery > 0 and _state.battery * 100 <= low_battery_percent * battery_max, LOW_BATTERY_BLINK_SEC)
	_hp_label.text = "HP %d / %d" % [_state.enemy_hp, enemy.max_hp]
	_hp_bar.set_value(_state.enemy_hp, animate)
	_persuade_label.text = "설득 %d / %d" % [_state.persuade_gauge, enemy.persuade_max]
	_persuade_bar.set_value(_state.persuade_gauge, animate)
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
	_battery_bar = SteppedGauge.create(palette, battery_max, palette.gauge_battery)
	charles_box.add_child(_battery_bar)

	var enemy_box := _add_panel(hud)
	_add_label(enemy_box, enemy.display_name, palette.font_bold)
	_hp_label = _add_label(enemy_box, "", palette.font_regular)
	_hp_bar = SteppedGauge.create(palette, enemy.max_hp, palette.gauge_enemy_hp)
	enemy_box.add_child(_hp_bar)
	_persuade_label = _add_label(enemy_box, "", palette.font_regular)
	_persuade_bar = SteppedGauge.create(palette, enemy.persuade_max, palette.gauge_persuade)
	enemy_box.add_child(_persuade_bar)

	# Stage: the two sprites stand on the kitchen floor.
	var stage := HBoxContainer.new()
	stage.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(stage)
	# Inset from the edges so both stand in the lit middle of the floor, clear of props.
	var inset_left := Control.new()
	inset_left.custom_minimum_size = Vector2(STAGE_INSET, 0)
	stage.add_child(inset_left)
	_charles_sprite = _add_actor(stage, "찰스", Color(0.55, 0.60, 0.65), charles_portrait)
	var stage_gap := Control.new()
	stage_gap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.add_child(stage_gap)
	_enemy_sprite = _add_actor(stage, enemy.display_name, Color(0.65, 0.55, 0.55), enemy.portrait)
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
	# The banner sits in a plain Control so it can drop in by offset; a
	# container would snap it back into place.
	_result_box = Control.new()
	_result_box.custom_minimum_size = Vector2(0, palette.size_banner + 16)
	_result_box.hide()
	menu_box.add_child(_result_box)
	_result_label = _add_label(_result_box, "", palette.font_bold)
	_result_label.add_theme_font_size_override(&"font_size", palette.size_banner)
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

	_fx_layer = Control.new()
	_fx_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fx_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fx_layer)


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
## named gray box when there is no portrait yet. Returns the sprite, which
## sits inside a plain holder so BattleFx can move it without the stage
## container snapping it back.
func _add_actor(parent: Control, actor_name: String, color: Color, portrait: Texture2D) -> Control:
	var size: Vector2 = portrait.get_size() * SPRITE_SCALE if portrait != null else Vector2(200, 200)
	var holder := Control.new()
	holder.custom_minimum_size = size
	holder.size_flags_vertical = Control.SIZE_SHRINK_END
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(holder)
	if portrait == null:
		var box := ColorRect.new()
		box.color = color
		box.size = size
		holder.add_child(box)
		var name_label := _add_label(box, actor_name, palette.font_regular)
		name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		return box
	var sprite := TextureRect.new()
	sprite.texture = portrait
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	sprite.size = size
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	BattleFx.prepare(sprite)
	holder.add_child(sprite)
	return sprite


func _add_label(parent: Control, text: String, font: Font, color: Color = palette.text_body) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", UiStyle.crisp(font))
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", palette.border_ink)
	label.add_theme_constant_override(&"outline_size", palette.text_outline)
	parent.add_child(label)
	return label
