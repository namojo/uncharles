extends Control
## Title screen: the first thing the game shows. Logo over the night job-agency
## backdrop, and a two-item menu (new game / quit). Layout and motion follow
## design/art/art-bible.md section 7.8.
##
## Keyboard: ui_up / ui_down move the cursor, ui_accept picks. Mouse and touch:
## hovering a row moves the cursor, clicking or tapping it picks. In a web build
## the quit item is left out, since a browser tab cannot be closed from the game.

const CURSOR_MARK: String = "▶"
## Cursor blink half-period (art bible 7.9: 400 ms on / 400 ms off).
const BLINK_SEC: float = 0.4
## Delay before the logo appears (art bible 7.8: about 600 ms).
const LOGO_DELAY_SEC: float = 0.6

@export var palette: UiPalette
@export var background: Texture2D
@export var logo: Texture2D
## Scene "새 게임" opens. Until the agency hub exists (Story 003) it is the battle.
@export_file("*.tscn") var new_game_scene: String = ""
@export var tagline: String = "버림받은 집사 로봇의 구직 RPG"
@export var footer: String = "v0.1 프로토타입"

var _items: PackedStringArray = ["새 게임", "종료"]
var _cursor: int = 0
var _rows: Array[PanelContainer] = []
var _cursor_labels: Array[Label] = []
var _item_labels: Array[Label] = []
var _blink_on: bool = true


func _ready() -> void:
	assert(palette != null, "title screen needs a UiPalette")
	if OS.has_feature("web"):
		_items.remove_at(_items.find("종료"))
	theme = UiStyle.make_theme(palette)
	_build_ui()
	_refresh()
	var blink := Timer.new()
	blink.wait_time = BLINK_SEC
	blink.timeout.connect(_on_blink)
	add_child(blink)
	blink.start()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"ui_down", true):
		_move(1)
	elif event.is_action_pressed(&"ui_up", true):
		_move(-1)
	elif event.is_action_pressed(&"ui_accept"):
		_choose()


func _move(step: int) -> void:
	_cursor = posmod(_cursor + step, _items.size())
	# Moving keeps the cursor lit (art bible 7.9).
	_blink_on = true
	_refresh()


func _point_at(index: int) -> void:
	if index != _cursor:
		_move(index - _cursor)


func _on_row_input(event: InputEvent, index: int) -> void:
	var click := event as InputEventMouseButton
	if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT:
		_cursor = index
		_choose()


func _choose() -> void:
	match _items[_cursor]:
		"새 게임":
			get_tree().change_scene_to_file(new_game_scene)
		"종료":
			get_tree().quit()


func _on_blink() -> void:
	_blink_on = not _blink_on
	_cursor_labels[_cursor].modulate.a = 1.0 if _blink_on else 0.0


func _refresh() -> void:
	for i in _items.size():
		var selected: bool = i == _cursor
		_rows[i].add_theme_stylebox_override(&"panel", UiStyle.row_style(palette, selected))
		_cursor_labels[i].modulate.a = 1.0 if selected and _blink_on else 0.0
		_item_labels[i].add_theme_font_override(&"font", UiStyle.crisp(palette.font_bold if selected else palette.font_regular))
		_item_labels[i].add_theme_color_override(&"font_color", palette.text_body if selected else palette.text_secondary)


func _build_ui() -> void:
	var fill := ColorRect.new()
	fill.color = palette.background
	fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(fill)
	if background != null:
		add_child(UiStyle.make_backdrop(background))

	var column := VBoxContainer.new()
	column.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(column)

	var top_gap := Control.new()
	top_gap.custom_minimum_size = Vector2(0, 88)
	column.add_child(top_gap)

	var logo_rect := TextureRect.new()
	logo_rect.texture = logo
	logo_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	logo_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	# Twice the source pixels: 356x116 art drawn at 712x232.
	logo_rect.custom_minimum_size = Vector2(712, 232)
	logo_rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	logo_rect.modulate.a = 0.0
	column.add_child(logo_rect)
	# Stepped reveal, no easing (art bible 7.9: stepped motion).
	var reveal := create_tween()
	reveal.tween_interval(LOGO_DELAY_SEC)
	reveal.tween_property(logo_rect, "modulate:a", 1.0, 0.0)

	var tagline_strip := PanelContainer.new()
	tagline_strip.add_theme_stylebox_override(&"panel", UiStyle.caption_style(palette))
	tagline_strip.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(tagline_strip)
	tagline_strip.add_child(_make_label(tagline, palette.size_body, palette.text_body))

	var menu_gap := Control.new()
	menu_gap.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(menu_gap)

	var menu := VBoxContainer.new()
	menu.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	menu.add_theme_constant_override(&"separation", 8)
	column.add_child(menu)
	for item: String in _items:
		var row := PanelContainer.new()
		row.custom_minimum_size = Vector2(320, 0)
		var index: int = _rows.size()
		row.mouse_entered.connect(_point_at.bind(index))
		row.gui_input.connect(_on_row_input.bind(index))
		menu.add_child(row)
		var line := HBoxContainer.new()
		line.add_theme_constant_override(&"separation", 12)
		line.mouse_filter = Control.MOUSE_FILTER_IGNORE
		row.add_child(line)
		var cursor := _make_label(CURSOR_MARK, palette.size_emphasis, palette.accent)
		line.add_child(cursor)
		var label := _make_label(item, palette.size_emphasis, palette.text_secondary)
		line.add_child(label)
		_rows.append(row)
		_cursor_labels.append(cursor)
		_item_labels.append(label)

	var footer_gap := Control.new()
	footer_gap.custom_minimum_size = Vector2(0, 72)
	column.add_child(footer_gap)

	var footer_label := _make_label(footer, palette.size_body, palette.text_secondary)
	footer_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	footer_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	footer_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	footer_label.offset_right = -palette.screen_margin
	footer_label.offset_bottom = -palette.screen_margin
	add_child(footer_label)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override(&"font_size", font_size)
	label.add_theme_color_override(&"font_color", color)
	# Ink outline keeps text readable over the backdrop (art bible 7.10).
	label.add_theme_color_override(&"font_outline_color", palette.border_ink)
	label.add_theme_constant_override(&"outline_size", palette.text_outline)
	return label
