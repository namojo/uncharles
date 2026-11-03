// canvas_fx_hit_flash — hit flash for battle sprites (design/art/art-bible.md 7.9).
// Author: Uncharles team. Mixes the sprite toward white by `flash_amount`
// (0 = normal, 1 = solid white), keeping alpha so the silhouette stays.
// Driven by src/battle/battle_fx.gd.
// Target: Compatibility (web/mobile) and Forward+; one texture sample, no branches.
shader_type canvas_item;

group_uniforms flash;
// How far the sprite is pushed toward white this frame.
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
// Flash colour; white per the art bible.
uniform vec4 flash_color : source_color = vec4(1.0);
group_uniforms;

void fragment() {
	lowp vec4 base = texture(TEXTURE, UV) * COLOR;
	COLOR = vec4(mix(base.rgb, flash_color.rgb, flash_amount), base.a);
}
