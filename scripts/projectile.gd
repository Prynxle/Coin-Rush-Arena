extends Area2D

@export var speed: float = 520.0
@export var max_range: float = 420.0

var direction: Vector2 = Vector2.RIGHT
var distance_travelled: float = 0.0


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	var travel_distance := speed * delta
	global_position += direction * travel_distance
	distance_travelled += travel_distance
	if distance_travelled >= max_range:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("enemies"):
		area.call("take_damage", 1)
		queue_free()
