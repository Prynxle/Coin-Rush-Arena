extends Area2D

signal player_caught

@export var move_speed: float = 70.0

var target: Node2D


func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var direction := global_position.direction_to(target.global_position)
	global_position += direction * move_speed * delta


func _on_body_entered(body: Node2D) -> void:
	if body == target:
		player_caught.emit()
