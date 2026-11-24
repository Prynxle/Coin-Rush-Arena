extends Area2D

@export var speed: float = 300.0
@export var max_range: float = 1400.0
@export var damage: int = 12

var direction: Vector2 = Vector2.RIGHT
var distance_travelled: float = 0.0


func _ready() -> void:
	add_to_group("doomsday_projectiles")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	var travel_distance := speed * delta
	global_position += direction * travel_distance
	distance_travelled += travel_distance
	if distance_travelled >= max_range:
		queue_free()


func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemies"):
		return

	area.call("take_damage", damage)
	queue_free()


func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		var current_scene := get_tree().current_scene
		if current_scene != null:
			current_scene.call("on_doomsday_projectile_hit", body)
	queue_free()
