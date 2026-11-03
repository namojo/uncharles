class_name DialogueBox
extends Control
## The non-battle dialogue window (art bible 7.5-7.6): bottom of the screen,
## 216 px high, a name tab above it, the body typed out at about 40 characters
## per second in single-character steps, and a blinking ▼ when the line is
## complete. Choices appear in a list above the window's right end.
## Display and input only: it never touches dialogue state; it reports
## `advance_requested` and `choice_picked` and the owner drives the runner.
## Implements Story 002 (production/epics/uncharles/story-002-dialogue-affinity.md).
##
## Input: ui_accept, a mouse click or a touch tap anywhere on screen first
## completes the line, then asks to advance. Choices take ui_up / ui_down /
## ui_accept, hover, click and tap (ChoiceList). The window is a full-screen
## Control so a tap outside the panel still counts; the panels themselves
## ignore the mouse so the tap reaches it.

## The player wants the next line (the current one was complete).
signal advance_requested
## The player picked choice `index` of the labels passed to `show_choices()`.
signal choice_picked(index: int)

enum Mode { IDLE, TYPING, WAITING, CHOOSING }

const MARKER: String = "▼"
const BOX_HEIGHT: int = 216
## Gap between the window and the choice list above it.
const CHOICE_GAP: int = 8

@export var palette: UiPalette
## Typewriter speed (art bible 7.6: about 40 per second).
@export var chars_per_sec: float = 40.0
## ▼ blink half-period (art bible 7.9: 400 ms).
@export var blink_sec: float = 0.4
## Speakers shown without a name tab.
@export var nameless_speakers: PackedStringArray = ["내레이션", "환경"]
## Speakers whose body text uses the secondary text colour (environment text).
@export var secondary_speakers: PackedStringArray = ["환경"]

## Plays `cursor` / `confirm`. Injected by the owner before the first line.
var sound: SoundPlayer:
	set(value):
		sound = value
		if _choices != null:
			_choices.sound = value

var _mode: Mode = Mode.IDLE
var _elapsed: float = 0.0
var _pending_choices: PackedStringArray = PackedStringArray()
var _name_tab: PanelContainer
var _name_label: Label
var _body: Label
var _marker: Label
var _choice_panel: PanelContainer
var _choices: ChoiceList
var _blink: Timer


func _ready() -> void:
	assert(palette != null, "dialogue box needs a UiPalette")
	theme = UiStyle.make_theme(palette)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	gui_input.connect(_on_gui_input)


## Starts typing `text` under `speaker`'s name tab. Any choices shown before are cleared.
func show_line(speaker: String, text: String) -> void:
	show()
	_name_tab.visible = not speaker in nameless_speakers
	_name_label.text = speaker
	_body.text = text
	_body.add_theme_color_override(&"font_color", palette.text_secondary if speaker in secondary_speakers else palette.text_body)
	_body.visible_characters = 0
	_elapsed = 0.0
	_pending_choices = PackedStringArray()
	_choice_panel.hide()
	_set_marker(false)
	_mode = Mode.TYPING


## Offers `labels` once the current line is fully shown.
func show_choices(labels: PackedStringArray) -> void:
	_pending_choices = labels
	if _mode == Mode.WAITING:
		_open_choices()


## Same as a press of the confirm key: completes the line, or asks to advance.
func activate() -> void:
	match _mode:
		Mode.TYPING:
			_finish_line()
		Mode.WAITING:
			_mode = Mode.IDLE
			_set_marker(false)
			advance_requested.emit()


## True while the line is still being typed.
func is_typing() -> bool:
	return _mode == Mode.TYPING


## True when the line is complete and the box waits for a confirm.
func is_waiting() -> bool:
	return _mode == Mode.WAITING


## The choice list while choices are offered, else null (debug driver).
func open_choices() -> ChoiceList:
	return _choices if _mode == Mode.CHOOSING else null


func _process(delta: float) -> void:
	if _mode != Mode.TYPING:
		return
	_elapsed += delta
	var count: int = int(_elapsed * chars_per_sec)
	if count >= _body.text.length():
		_finish_line()
	else:
		_body.visible_characters = count


func _unhandled_input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed(&"ui_accept") and _mode != Mode.CHOOSING:
		activate()
		get_viewport().set_input_as_handled()


func _on_gui_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and _mode != Mode.CHOOSING:
		activate()
		accept_event()


func _finish_line() -> void:
	_body.visible_characters = -1
	if _pending_choices.is_empty():
		_mode = Mode.WAITING
		_set_marker(true)
	else:
		_open_choices()


func _open_choices() -> void:
	_mode = Mode.CHOOSING
	_set_marker(false)
	_choices.show_options(_pending_choices)
	_choice_panel.show()


func _on_choice_picked(index: int) -> void:
	_choice_panel.hide()
	_mode = Mode.IDLE
	choice_picked.emit(index)


func _set_marker(on: bool) -> void:
	_marker.modulate.a = 1.0 if on else 0.0
	if on:
		_blink.start()
	else:
		_blink.stop()


func _build_ui() -> void:
	var margin: int = palette.screen_margin
	var panel := PanelContainer.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = margin
	panel.offset_right = -margin
	panel.offset_top = -(margin + BOX_HEIGHT)
	panel.offset_bottom = -margin
	add_child(panel)
	var content := Control.new()
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(content)
	_body = Label.new()
	_body.set_anchors_preset(Control.PRESET_FULL_RECT)
	_body.offset_right = -palette.size_body * 2
	_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_body.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	content.add_child(_body)
	_marker = Label.new()
	_marker.text = MARKER
	_marker.add_theme_color_override(&"font_color", palette.accent)
	_marker.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	_marker.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_marker.grow_vertical = Control.GROW_DIRECTION_BEGIN
	content.add_child(_marker)
	_blink = Timer.new()
	_blink.wait_time = blink_sec
	_blink.timeout.connect(func() -> void: _marker.modulate.a = 1.0 - _marker.modulate.a)
	add_child(_blink)

	_name_tab = PanelContainer.new()
	_name_tab.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_anchor_above(_name_tab, 0.0, margin, -(margin + BOX_HEIGHT) + palette.border_width)
	add_child(_name_tab)
	_name_label = Label.new()
	_name_label.add_theme_font_override(&"font", UiStyle.crisp(palette.font_bold))
	_name_tab.add_child(_name_label)

	_choice_panel = PanelContainer.new()
	_anchor_above(_choice_panel, 1.0, -margin, -(margin + BOX_HEIGHT + CHOICE_GAP))
	_choice_panel.hide()
	add_child(_choice_panel)
	_choices = ChoiceList.new()
	_choices.palette = palette
	_choices.sound = sound
	_choices.picked.connect(_on_choice_picked)
	_choice_panel.add_child(_choices)


## Pins `control`'s bottom edge at `bottom` px from the screen bottom and its
## left (anchor_x 0) or right (anchor_x 1) edge at `side` px; it grows upward
## and inward to fit its content.
func _anchor_above(control: Control, anchor_x: float, side: int, bottom: int) -> void:
	control.anchor_left = anchor_x
	control.anchor_right = anchor_x
	control.anchor_top = 1.0
	control.anchor_bottom = 1.0
	control.offset_left = side
	control.offset_right = side
	control.offset_top = bottom
	control.offset_bottom = bottom
	control.grow_horizontal = Control.GROW_DIRECTION_END if anchor_x == 0.0 else Control.GROW_DIRECTION_BEGIN
	control.grow_vertical = Control.GROW_DIRECTION_BEGIN
