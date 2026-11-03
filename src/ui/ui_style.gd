class_name UiStyle
extends RefCounted
## Builds the shared pixel UI look (theme, panels, gauges) from a UiPalette, so
## every screen reads the same data. See design/art/art-bible.md section 7.


## A Theme with the palette's regular font, body size and text colours.
static func make_theme(palette: UiPalette) -> Theme:
	var theme := Theme.new()
	theme.default_font = crisp(palette.font_regular)
	theme.default_font_size = palette.size_body
	theme.set_color(&"font_color", &"Label", palette.text_body)
	# Ink outline keeps text readable over background art (art bible 7.10).
	theme.set_color(&"font_outline_color", &"Label", palette.border_ink)
	theme.set_constant(&"outline_size", &"Label", palette.text_outline)
	theme.set_color(&"default_color", &"RichTextLabel", palette.text_body)
	theme.set_stylebox(&"panel", &"PanelContainer", panel_style(palette))
	return theme


## Turns off smoothing so a pixel font keeps hard edges at integer sizes.
static func crisp(font: Font) -> Font:
	var file := font as FontFile
	if file != null:
		file.antialiasing = TextServer.FONT_ANTIALIASING_NONE
		file.hinting = TextServer.HINTING_NONE
		file.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	return font


## Opaque panel: flat fill, steel border, square corners, unblurred drop shadow.
static func panel_style(palette: UiPalette) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = palette.panel_fill
	box.set_border_width_all(palette.border_width)
	box.border_color = palette.border_steel
	box.anti_aliasing = false
	box.shadow_color = palette.hard_shadow
	box.shadow_size = 1
	box.shadow_offset = Vector2(palette.shadow_offset, palette.shadow_offset)
	box.content_margin_left = palette.panel_padding_x
	box.content_margin_right = palette.panel_padding_x
	box.content_margin_top = palette.panel_padding_y
	box.content_margin_bottom = palette.panel_padding_y
	return box


## Flat band behind a selected row, or an empty style when not selected.
static func row_style(palette: UiPalette, selected: bool) -> StyleBox:
	if not selected:
		return StyleBoxEmpty.new()
	var band := StyleBoxFlat.new()
	band.bg_color = palette.selected_band
	band.anti_aliasing = false
	return band


## Dark ink strip behind text laid directly over background art.
static func caption_style(palette: UiPalette) -> StyleBoxFlat:
	var strip := StyleBoxFlat.new()
	strip.bg_color = Color(palette.border_ink, 0.85)
	strip.anti_aliasing = false
	strip.content_margin_left = 12
	strip.content_margin_right = 12
	strip.content_margin_top = 4
	strip.content_margin_bottom = 4
	return strip


## A gauge: ink outline, dark track, solid fill in `fill_color`.
static func make_gauge(palette: UiPalette, max_value: int, fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = max_value
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(0, palette.gauge_height)
	var track := StyleBoxFlat.new()
	track.bg_color = palette.gauge_track
	track.set_border_width_all(2)
	track.border_color = palette.border_ink
	track.anti_aliasing = false
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_border_width_all(2)
	fill.border_color = palette.border_ink
	fill.anti_aliasing = false
	bar.add_theme_stylebox_override(&"background", track)
	bar.add_theme_stylebox_override(&"fill", fill)
	return bar


## Full-screen art drawn with nearest filtering (pixel art stays crisp).
static func make_backdrop(texture: Texture2D) -> TextureRect:
	var rect := TextureRect.new()
	rect.texture = texture
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	return rect
