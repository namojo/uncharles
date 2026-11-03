class_name BattleFx
extends RefCounted
## Stepped battle motion from design/art/art-bible.md section 7.9: no easing,
## 12 fps "tooth" steps, a slightly creaky machine. Every function moves a
## sprite's offset inside its holder (never the holder, which a container
## lays out) and awaits its own steps, so callers can chain them.
##
## Shake and flash respect `effects_enabled`: the art bible requires an option
## to turn screen shake and flashing off (7.9 accessibility).

## One motion step at 12 fps.
const STEP_SEC: float = 1.0 / 12.0
## Hit shake: horizontal offsets, 40 ms each (art bible 7.9).
const SHAKE_OFFSETS: Array[int] = [6, -6, 4, -4, 2, 0]
const SHAKE_STEP_SEC: float = 0.04
## White flash length (art bible 7.9: one frame, about 80 ms).
const FLASH_SEC: float = 0.08
## Lunge toward the opponent: offsets per step, then back the same way.
const LUNGE_STEPS: Array[int] = [24, 56, 96]
## Persuade "talk" hop and defend bow: vertical offsets per step.
const HOP_STEPS: Array[int] = [-6, -12, -6, 0]
const BOW_STEPS: Array[int] = [6, 12, 12, 6, 0]
## Floating number: rises this many pixels per step, then holds.
const POP_RISE: int = 10
const POP_STEPS: int = 3
const POP_HOLD_SEC: float = 0.45
## Result banner drops in from this far above, in 3 steps (art bible 7.9).
const BANNER_DROP: int = 36

const FLASH_SHADER: Shader = preload("res://assets/shaders/canvas_fx_hit_flash.gdshader")

## Off turns shake and flash into no-ops (motion accessibility option).
static var effects_enabled: bool = true


## Gives `sprite` the flash material so flash() can whiten it.
static func prepare(sprite: CanvasItem) -> void:
	var material := ShaderMaterial.new()
	material.shader = FLASH_SHADER
	sprite.material = material


## Steps `sprite` toward the opponent; `direction` +1 is right, -1 left.
static func lunge_out(sprite: Control, direction: int) -> void:
	for x in LUNGE_STEPS:
		if not await _step(sprite, Vector2(x * direction, 0), STEP_SEC):
			return


## Steps `sprite` back from a lunge to where it stands.
static func lunge_back(sprite: Control, direction: int) -> void:
	var back: Array[int] = LUNGE_STEPS.duplicate()
	back.reverse()
	back.pop_front()
	for x in back:
		if not await _step(sprite, Vector2(x * direction, 0), STEP_SEC):
			return
	await _step(sprite, Vector2.ZERO, STEP_SEC)


## Persuade: a short hop, as if leaning in to talk.
static func hop(sprite: Control) -> void:
	for y in HOP_STEPS:
		if not await _step(sprite, Vector2(0, y), STEP_SEC):
			return


## Defend: a stiff butler's bow.
static func bow(sprite: Control) -> void:
	for y in BOW_STEPS:
		if not await _step(sprite, Vector2(0, y), STEP_SEC):
			return


## Hit reaction: a white flash and the horizontal shake together.
static func hit(sprite: Control) -> void:
	flash(sprite)
	await shake(sprite)


## Shakes `sprite` sideways (art bible 7.9). No-op when effects are off.
static func shake(sprite: Control) -> void:
	if not effects_enabled:
		return
	for x in SHAKE_OFFSETS:
		if not await _step(sprite, Vector2(x, sprite.position.y), SHAKE_STEP_SEC):
			return


## Flashes `sprite` white for one frame. No-op when effects are off.
static func flash(sprite: CanvasItem) -> void:
	var material := sprite.material as ShaderMaterial
	if not effects_enabled or material == null:
		return
	material.set_shader_parameter(&"flash_amount", 1.0)
	await sprite.get_tree().create_timer(FLASH_SEC).timeout
	if is_instance_valid(sprite):
		material.set_shader_parameter(&"flash_amount", 0.0)


## Fades `sprite` out in stepped blinks (enemy defeated).
static func blink_out(sprite: CanvasItem) -> void:
	for alpha: float in [0.2, 1.0, 0.2, 0.7, 0.35, 0.0]:
		if not is_instance_valid(sprite):
			return
		sprite.modulate.a = alpha
		await sprite.get_tree().create_timer(STEP_SEC).timeout


## Dims `sprite` to gray in steps (Charles' battery runs out).
static func power_down(sprite: CanvasItem) -> void:
	for level: float in [0.8, 0.6, 0.65, 0.45, 0.35]:
		if not is_instance_valid(sprite):
			return
		sprite.modulate = Color(level, level, level * 1.05, 1.0)
		await sprite.get_tree().create_timer(STEP_SEC * 1.5).timeout


## Pops `text` above `anchor` on `layer`, rising in steps, then removes it.
## Does not wait: numbers float while the next motion plays.
static func pop_number(layer: Control, anchor: Control, text: String, color: Color, font: Font, size: int, outline: Color) -> void:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override(&"font", font)
	label.add_theme_font_size_override(&"font_size", size)
	label.add_theme_color_override(&"font_color", color)
	label.add_theme_color_override(&"font_outline_color", outline)
	label.add_theme_constant_override(&"outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(label)
	var rect: Rect2 = anchor.get_global_rect()
	var start := Vector2(rect.get_center().x - label.get_minimum_size().x / 2.0, rect.position.y - label.get_minimum_size().y)
	label.global_position = start
	for i in range(1, POP_STEPS + 1):
		await layer.get_tree().create_timer(STEP_SEC).timeout
		if not is_instance_valid(label):
			return
		label.global_position = start - Vector2(0, POP_RISE * i)
	await layer.get_tree().create_timer(POP_HOLD_SEC).timeout
	if is_instance_valid(label):
		label.queue_free()


## Shows `label` dropping in from above in 3 steps (result banner).
static func drop_in(label: Control) -> void:
	label.show()
	for i in 3:
		label.position.y = -BANNER_DROP + BANNER_DROP * (i + 1) / 3.0
		await label.get_tree().create_timer(STEP_SEC).timeout
		if not is_instance_valid(label):
			return


## Moves `sprite` to `offset`, waits `sec`. False if the sprite was freed meanwhile.
static func _step(sprite: Control, offset: Vector2, sec: float) -> bool:
	if not is_instance_valid(sprite):
		return false
	sprite.position = offset
	await sprite.get_tree().create_timer(sec).timeout
	return is_instance_valid(sprite)
