extends Node

const CLASSIC_SKIN_ID: String = "classic_blue"

var _skins: Array[Dictionary] = []


func _init() -> void:
	_skins = [
		{
			"id": CLASSIC_SKIN_ID,
			"name": "Classic Blue",
			"description": "The original clean-cut arena runner.",
			"price": 0,
			"shape": "rectangle",
			"color": Color(0.2, 0.65, 1.0),
		},
		{
			"id": "crimson",
			"name": "Crimson",
			"description": "A bold red square with softened corners.",
			"price": 100,
			"shape": "rounded_square",
			"color": Color("#ed5261"),
		},
		{
			"id": "toxic",
			"name": "Toxic",
			"description": "A sharp green hazard triangle.",
			"price": 200,
			"shape": "triangle",
			"color": Color("#8be05a"),
		},
		{
			"id": "phantom",
			"name": "Phantom",
			"description": "A purple six-sided spectral mark.",
			"price": 350,
			"shape": "hexagon",
			"color": Color("#a77bfa"),
		},
		{
			"id": "superstar",
			"name": "Superstar",
			"description": "A bright golden star made for center stage.",
			"price": 500,
			"shape": "star",
			"color": Color("#ffd34f"),
		},
		{
			"id": "aqua",
			"name": "Aqua",
			"description": "A smooth cyan circle with a cool glow.",
			"price": 650,
			"shape": "circle",
			"color": Color("#42dce0"),
		},
		{
			"id": "inferno",
			"name": "Inferno",
			"description": "Black spikes with a dark-red core.",
			"price": 1000,
			"shape": "spikes",
			"color": Color("#17121a"),
		},
	]


func get_all_skins() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(_skins)
	return result


func get_skin(skin_id: String) -> Dictionary:
	for skin in _skins:
		if skin["id"] == skin_id:
			return skin
	return {}


func has_skin(skin_id: String) -> bool:
	return not get_skin(skin_id).is_empty()


func get_color(skin_id: String) -> Color:
	var skin := get_skin(skin_id)
	var skin_color: Variant = skin.get("color", Color(0.2, 0.65, 1.0))
	if skin_color is Color:
		return skin_color
	return Color(0.2, 0.65, 1.0)


func get_polygon(skin_id: String) -> PackedVector2Array:
	var skin := get_skin(skin_id)
	match str(skin.get("shape", "rectangle")):
		"rectangle":
			return PackedVector2Array([
				Vector2(-18.0, -14.0), Vector2(18.0, -14.0),
				Vector2(18.0, 14.0), Vector2(-18.0, 14.0),
			])
		"rounded_square":
			return _rounded_square_polygon(14.0, 4.0, 5)
		"triangle":
			return _regular_polygon(3, 18.0, -PI * 0.5)
		"hexagon":
			return _regular_polygon(6, 18.0, -PI * 0.5)
		"star":
			return _star_polygon(18.0, 8.0, 10, -PI * 0.5)
		"circle":
			return _regular_polygon(24, 17.0, -PI * 0.5)
		"spikes":
			return _star_polygon(18.0, 11.0, 24, -PI * 0.5)
		_:
			return _regular_polygon(4, 18.0, -PI * 0.25)


func get_accent_color(skin_id: String) -> Color:
	if skin_id == "inferno":
		return Color("#8c2028")
	return Color.TRANSPARENT


func get_accent_polygon(skin_id: String) -> PackedVector2Array:
	if skin_id == "inferno":
		return _star_polygon(12.0, 6.0, 12, -PI * 0.5)
	return PackedVector2Array()


func _regular_polygon(sides: int, radius: float, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(sides):
		var angle := rotation + TAU * float(point_index) / float(sides)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _star_polygon(outer_radius: float, inner_radius: float, point_count: int, rotation: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for point_index in range(point_count):
		var angle := rotation + TAU * float(point_index) / float(point_count)
		var radius := outer_radius if point_index % 2 == 0 else inner_radius
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


func _rounded_square_polygon(half_extent: float, corner_radius: float, points_per_corner: int) -> PackedVector2Array:
	var centers: Array[Vector2] = [
		Vector2(half_extent - corner_radius, -half_extent + corner_radius),
		Vector2(half_extent - corner_radius, half_extent - corner_radius),
		Vector2(-half_extent + corner_radius, half_extent - corner_radius),
		Vector2(-half_extent + corner_radius, -half_extent + corner_radius),
	]
	var start_angles: Array[float] = [-PI * 0.5, 0.0, PI * 0.5, PI]
	var points := PackedVector2Array()
	for corner_index in range(centers.size()):
		for step in range(points_per_corner + 1):
			var angle := start_angles[corner_index] + PI * 0.5 * float(step) / float(points_per_corner)
			points.append(centers[corner_index] + Vector2(cos(angle), sin(angle)) * corner_radius)
	return points
