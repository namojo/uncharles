class_name ChoiceList
extends VBoxContainer
## A vertical list of options with the ▶ cursor (art bible 7.5). Used for
## dialogue choices and for the story flow's map menu. Display and input only:
## it reports the picked index through `picked` and changes nothing else.
## Implements Story 002 (production/epics/uncharles/story-002-dialogue-affinity.md).
##
## Keyboard: ui_up / ui_down move the cursor, ui_accept picks. Mouse and touch:
## hovering a row moves the cursor, clicking or tapping it picks. After a pick
## the list ignores input until `show_options()` is called again.

## The player picked option `index` (position in the labels last shown).
signal picked(index: int)

const CURSOR_MARK: String = "▶"
## Cursor blink half-period (art bible 7.9: 400 ms on / 400 ms off).
const BLINK_SEC: float = 0.4

## Injected by the owner before `show_options()`.
var palette: UiPalette
## Plays `cursor` / `confirm`. Injected by the owner.
var sound: SoundPlayer
## Index of the row under the cursor.
var cursor: int = 0

var _active: bool = false
var _blink_on: bool = true
var _rows: Array[PanelContainer] = []
var _cursor_labels: Array[Label] = []
var _labels: Array[Label] = []


func _ready() -> void:
	add_theme_constant_override(&"separation", 0)
	var blink := Timer.new()
	blink.wait_time = BLINK_SEC
	blink.timeout.connect(_on_blink)
	add_child(blink, false, Node.INTERNAL_MODE_FRONT)
	blink.start()


## Replaces the rows with `labels` and takes input, cursor on the first row.
func show_options(labels: PackedStringArray) -> void:
	for row in _rows:
		remove_child(row)
		row.queue_free()
	_rows.clear()
	_cursor_labels.clear()
	_labels.clear()
	for text: String in labels:
		_add_row(text)
	cursor = 0
	_active = true
	_blink_on = true
	_refresh()


## Moves the cursor to `index` (also used by the story flow's debug driver).
func set_cursor(index: int) -> void:
	if index == cursor or index < 0 or index >= _rows.size():
		return
	cursor = index
	_blink_on = true
	sound.play(&"cursor")
	_refresh()


## Picks the row under the cursor.
func confirm() -> void:
	if not _active:
		return
	_active = false
	sound.play(&"confirm")
	picked.emit(cursor)


func _unhandled_input(event: InputEvent) -> void:
	if not _active or not is_visible_in_tree():
		return
	if event.is_action_pressed(&"ui_down", true):
		set_cursor(posmod(cursor + 1, _rows.size()))
	elif event.is_action_pressed(&"ui_up", true):
		set_cursor(posmod(cursor - 1, _rows.size()))
	elif event.is_action_pressed(&"ui_accept"):
		confirm()
	else:
		return
	get_viewport().set_input_as_handled()


func _add_row(text: String) -> void:
	var row := PanelContainer.new()
	var index: int = _rows.size()
	row.mouse_entered.connect(func() -> void:
		if _active:
			set_cursor(index))
	row.gui_input.connect(_on_row_input.bind(index))
	add_child(row)
	var line := HBoxContainer.new()
	line.add_theme_constant_override(&"separation", 8)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(line)
	var mark := Label.new()
	mark.text = CURSOR_MARK
	mark.add_theme_color_override(&"font_color", palette.accent)
	line.add_child(mark)
	var label := Label.new()
	label.text = text
	line.add_child(label)
	_rows.append(row)
	_cursor_labels.append(mark)
	_labels.append(label)


func _on_row_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if _active and click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		cursor = index
		_refresh()
		confirm()
		accept_event()


func _on_blink() -> void:
	_blink_on = not _blink_on
	if cursor < _cursor_labels.size():
		_cursor_labels[cursor].modulate.a = 1.0 if _blink_on else 0.0


func _refresh() -> void:
	for i in _rows.size():
		var selected: bool = i == cursor
		_rows[i].add_theme_stylebox_override(&"panel", UiStyle.row_style(palette, selected))
		_cursor_labels[i].modulate.a = 1.0 if selected and _blink_on else 0.0
		_labels[i].add_theme_font_override(&"font", UiStyle.crisp(palette.font_bold if selected else palette.font_regular))
		_labels[i].add_theme_color_override(&"font_color", palette.text_body if selected else palette.text_secondary)
