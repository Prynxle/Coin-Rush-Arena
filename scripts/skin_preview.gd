extends Control

@export var skin_id: String = "classic_blue":
	set(value):
		skin_id = value
		queue_redraw()

var skin_catalog: Node


func _ready() -> void:
	skin_catalog = get_node("/root/SkinCatalog")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if not bool(skin_catalog.call("has_skin", skin_id)):
		return

	var scale_factor := minf(size.x, size.y) / 42.0
	var center := size * 0.5
	var shape: PackedVector2Array = skin_catalog.call("get_polygon", skin_id)
	var skin_color: Color = skin_catalog.call("get_color", skin_id)
	_draw_shape(shape, skin_color, center, scale_factor)

	var accent_polygon: PackedVector2Array = skin_catalog.call("get_accent_polygon", skin_id)
	if not accent_polygon.is_empty():
		var accent_color: Color = skin_catalog.call("get_accent_color", skin_id)
		_draw_shape(accent_polygon, accent_color, center, scale_factor)


func _draw_shape(polygon: PackedVector2Array, color: Color, center: Vector2, scale_factor: float) -> void:
	var points := PackedVector2Array()
	for point in polygon:
		points.append(center + point * scale_factor)
	draw_colored_polygon(points, color)
	if points.size() > 2:
		var outline := points.duplicate()
		outline.append(points[0])
		draw_polyline(outline, Color(0.86, 0.94, 1.0, 0.85), maxf(1.0, scale_factor * 1.6), true)
