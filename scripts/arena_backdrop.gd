extends Node2D

const BACKGROUND := Color("#07111f")
const GRID := Color(0.18, 0.49, 0.68, 0.12)
const BORDER := Color(0.14, 0.63, 0.82, 0.32)


func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)


func _draw() -> void:
	var bounds := get_viewport_rect()
	draw_rect(bounds, BACKGROUND, true)
	var step := 48.0
	var x := 0.0
	while x <= bounds.size.x:
		draw_line(Vector2(x, 0.0), Vector2(x, bounds.size.y), GRID, 1.0)
		x += step
	var y := 0.0
	while y <= bounds.size.y:
		draw_line(Vector2(0.0, y), Vector2(bounds.size.x, y), GRID, 1.0)
		y += step
	draw_rect(Rect2(Vector2(12.0, 12.0), bounds.size - Vector2(24.0, 24.0)), BORDER, false, 1.0)
	for index in range(4):
		var side_x := 36.0 if index % 2 == 0 else bounds.size.x - 36.0
		var side_y := 36.0 if index < 2 else bounds.size.y - 36.0
		draw_circle(Vector2(side_x, side_y), 2.5, Color(0.25, 0.85, 0.98, 0.45))
