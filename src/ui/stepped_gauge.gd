class_name SteppedGauge
extends Control
## Gauge from design/art/art-bible.md section 7.4: a solid fill over a dark
## track. A drop leaves a gray "afterimage" that holds for 300 ms, then steps
## down to the new value; a rise snaps up. Can blink (low battery, full
## persuade). All motion is stepped, never eased (section 7.9).

## Afterimage hold before it follows the fill down (art bible 7.4).
const GHOST_HOLD_SEC: float = 0.3
## One motion step at 12 fps (art bible 7.9).
const STEP_SEC: float = 1.0 / 12.0
## Steps the afterimage takes to catch up.
const GHOST_STEPS: int = 3

var _bar: ProgressBar
var _ghost: ProgressBar
var _ghost_target: float = 0.0
var _ghost_serial: int = 0
var _blink_timer: Timer


## A gauge sized to the palette's gauge height, filled with `fill_color`.
static func create(palette: UiPalette, max_value: int, fill_color: Color) -> SteppedGauge:
	var gauge := SteppedGauge.new()
	gauge.custom_minimum_size = Vector2(0, palette.gauge_height)
	gauge._ghost = _make_bar(palette, max_value, palette.text_secondary, true)
	gauge.add_child(gauge._ghost)
	gauge._bar = _make_bar(palette, max_value, fill_color, false)
	gauge.add_child(gauge._bar)
	return gauge


## Sets the value. A drop leaves the afterimage behind unless `animate` is false.
func set_value(value: float, animate: bool = true) -> void:
	_bar.value = value
	if not animate or value >= _ghost.value:
		_ghost.value = value
		_ghost_target = value
		return
	_ghost_target = value
	_ghost_serial += 1
	_follow(_ghost_serial)


## Blinks the fill `times` times (off/on each `half_period_sec`), then leaves it lit.
func flash(times: int, half_period_sec: float) -> void:
	for i in times:
		_bar.modulate.a = 0.0
		await get_tree().create_timer(half_period_sec).timeout
		if not is_instance_valid(self):
			return
		_bar.modulate.a = 1.0
		await get_tree().create_timer(half_period_sec).timeout
		if not is_instance_valid(self):
			return


## Keeps blinking every `half_period_sec` while `on` (low battery warning).
func set_warning(on: bool, half_period_sec: float) -> void:
	if on and _blink_timer == null:
		_blink_timer = Timer.new()
		_blink_timer.wait_time = half_period_sec
		_blink_timer.timeout.connect(func() -> void: _bar.modulate.a = 1.0 - _bar.modulate.a)
		add_child(_blink_timer)
		_blink_timer.start()
	elif not on and _blink_timer != null:
		_blink_timer.queue_free()
		_blink_timer = null
		_bar.modulate.a = 1.0


func _follow(serial: int) -> void:
	await get_tree().create_timer(GHOST_HOLD_SEC).timeout
	var start: float = _ghost.value
	for i in range(1, GHOST_STEPS + 1):
		if not is_instance_valid(self) or serial != _ghost_serial:
			return
		_ghost.value = lerpf(start, _ghost_target, float(i) / GHOST_STEPS)
		await get_tree().create_timer(STEP_SEC).timeout


static func _make_bar(palette: UiPalette, max_value: int, fill_color: Color, with_track: bool) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.max_value = max_value
	bar.show_percentage = false
	bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_border_width_all(2)
	fill.border_color = palette.border_ink
	fill.anti_aliasing = false
	bar.add_theme_stylebox_override(&"fill", fill)
	if with_track:
		var track := StyleBoxFlat.new()
		track.bg_color = palette.gauge_track
		track.set_border_width_all(2)
		track.border_color = palette.border_ink
		track.anti_aliasing = false
		bar.add_theme_stylebox_override(&"background", track)
	else:
		bar.add_theme_stylebox_override(&"background", StyleBoxEmpty.new())
	return bar
