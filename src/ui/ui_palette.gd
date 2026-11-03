class_name UiPalette
extends Resource
## Screen-space UI colours, fonts and sizes, as data (.tres). Values follow
## design/art/art-bible.md sections 4 and 7; change them there first.

@export_group("Fonts")
@export var font_regular: Font
@export var font_bold: Font
## Galmuri11 sits on a 12px grid, so sizes stay integer multiples of 12.
@export var size_body: int = 24
@export var size_emphasis: int = 36
@export var size_banner: int = 48

@export_group("Surfaces")
## Behind everything when a screen has no background art.
@export var background: Color = Color("14121a")
@export var panel_fill: Color = Color("1b1a24")
## Band behind the selected menu row.
@export var selected_band: Color = Color("2e2c40")
@export var border_ink: Color = Color("14121a")
@export var border_steel: Color = Color("8a90a6")
@export var hard_shadow: Color = Color("0b0a10")
@export var border_width: int = 4
@export var shadow_offset: int = 4

@export_group("Text")
@export var text_body: Color = Color("e8e6f0")
@export var text_secondary: Color = Color("9a9cb0")
@export var text_disabled: Color = Color("5c5e70")
## Ink outline around label text, in screen px (even, per the 2 px UI grid).
@export var text_outline: int = 6
## Cursor and focus: the one "switched on" colour.
@export var accent: Color = Color("3fe0e8")
@export var reward: Color = Color("f2c94c")
@export var danger: Color = Color("ff4d6d")

@export_group("Gauges")
@export var gauge_track: Color = Color("2a2838")
@export var gauge_battery: Color = Color("43e0c0")
@export var gauge_enemy_hp: Color = Color("d9583a")
@export var gauge_persuade: Color = Color("b58cff")
@export var gauge_height: int = 20

@export_group("Layout")
@export var screen_margin: int = 16
@export var panel_gap: int = 16
@export var panel_padding_x: int = 16
@export var panel_padding_y: int = 12
