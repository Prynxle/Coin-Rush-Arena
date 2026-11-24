extends Control

const GRID_COLOR := Color(0.18, 0.42, 0.62, 0.13)
const CYAN := Color(0.18, 0.88, 0.95, 0.12)
const PURPLE := Color(0.56, 0.31, 0.95, 0.10)
const BACKGROUND := Color("#07111f")

var elapsed := 0.0
var particles: Array[Vector2] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for index in range(24):
		particles.append(Vector2(randf(), randf()))


func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()


func _draw() -> void:
	var bounds := Rect2(Vector2.ZERO, size)
	draw_rect(bounds, BACKGROUND, true)
	var grid_step := 64.0
	var scroll := fmod(elapsed * 3.0, grid_step)
	var x := -scroll
	while x < size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, size.y), GRID_COLOR, 1.0)
		x += grid_step
	var y := -scroll
	while y < size.y:
		draw_line(Vector2(0.0, y), Vector2(size.x, y), GRID_COLOR, 1.0)
		y += grid_step

	draw_circle(Vector2(size.x * 0.18, size.y * 0.24), minf(size.x, size.y) * 0.22, Color(0.05, 0.34, 0.55, 0.10))
	draw_circle(Vector2(size.x * 0.86, size.y * 0.78), minf(size.x, size.y) * 0.28, Color(0.29, 0.12, 0.55, 0.10))
	for index in range(particles.size()):
		var origin := particles[index]
		var drift := Vector2(sin(elapsed * 0.28 + float(index)) * 0.018, fposmod(elapsed * (0.012 + float(index % 4) * 0.003), 1.0))
		var point := Vector2(origin.x, fposmod(origin.y + drift.y, 1.0)) * size
		point.x = fposmod(point.x + drift.x * size.x, maxf(size.x, 1.0))
		var tint := CYAN if index % 3 != 0 else PURPLE
		var pulse := 0.45 + 0.35 * sin(elapsed * 1.2 + float(index))
		draw_circle(point, 1.3 + float(index % 3) * 0.45, Color(tint.r, tint.g, tint.b, tint.a * pulse * 4.0))

	var inset := minf(24.0, minf(size.x, size.y) * 0.1)
	var accent_rect := Rect2(Vector2(inset, inset), bounds.size - Vector2.ONE * inset * 2.0)
	draw_rect(accent_rect, Color(0.20, 0.69, 0.86, 0.16), false, 1.0)
