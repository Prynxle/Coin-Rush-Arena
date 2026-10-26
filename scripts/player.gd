extends CharacterBody2D

@export var move_speed: float = 300.0


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()

	var arena_size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 18.0, arena_size.x - 18.0)
	global_position.y = clampf(global_position.y, 18.0, arena_size.y - 18.0)
