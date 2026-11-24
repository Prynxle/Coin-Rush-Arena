extends Area2D

signal player_caught

@export var move_speed: float = 70.0
@export var max_health: int = 1
@export var separation_margin: float = 14.0
@export var separation_strength: float = 2.0

var target: Node2D
var current_health: int = 1
var pursuit_aggression_multiplier: float = 1.0
var pursuit_velocity: Vector2 = Vector2.ZERO
var difficulty_settings: Dictionary = {}
var hit_flash_remaining: float = 0.0

@onready var visual: Polygon2D = $Visual


func _ready() -> void:
	add_to_group("enemies")
	body_entered.connect(_on_body_entered)
	current_health = maxi(max_health, 1)
	_apply_difficulty_settings()


func _process(delta: float) -> void:
	if hit_flash_remaining <= 0.0:
		return
	hit_flash_remaining = maxf(hit_flash_remaining - delta, 0.0)
	if hit_flash_remaining == 0.0:
		visual.color = Color(0.9, 0.2, 0.25, 1.0)


func _physics_process(delta: float) -> void:
	if target == null:
		return

	var direction := global_position.direction_to(target.global_position)
	var separation_direction := _get_separation_direction()
	var desired_direction := direction + separation_direction * separation_strength
	if desired_direction.length_squared() > 0.0001:
		desired_direction = desired_direction.normalized()
	else:
		desired_direction = direction
	var desired_velocity := desired_direction * move_speed
	var acceleration := move_speed * 4.0 * pursuit_aggression_multiplier
	pursuit_velocity = pursuit_velocity.move_toward(desired_velocity, acceleration * delta)
	global_position += pursuit_velocity * delta


func _get_separation_direction() -> Vector2:
	var separation := Vector2.ZERO
	var own_radius := 16.0 * absf(global_scale.x)
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other) or other.is_queued_for_deletion():
			continue

		var other_enemy := other as Node2D
		if other_enemy == null:
			continue

		var offset := global_position - other_enemy.global_position
		var distance := offset.length()
		var other_radius := 16.0 * absf(other_enemy.global_scale.x)
		var minimum_distance := own_radius + other_radius + separation_margin
		if distance >= minimum_distance:
			continue

		if distance < 0.01:
			var direction_sign := 1.0 if get_instance_id() < other_enemy.get_instance_id() else -1.0
			offset = Vector2.RIGHT * direction_sign
		else:
			offset /= distance

		var overlap_ratio := (minimum_distance - distance) / minimum_distance
		separation += offset * overlap_ratio

	return separation


func _on_body_entered(body: Node2D) -> void:
	if body == target:
		player_caught.emit()


func eliminate() -> void:
	queue_free()


func take_damage(amount: int) -> void:
	if amount <= 0 or is_queued_for_deletion():
		return

	current_health = maxi(current_health - amount, 0)
	if current_health == 0:
		eliminate()
		return

	visual.color = Color.WHITE
	hit_flash_remaining = 0.1


func _apply_difficulty_settings() -> void:
	var base_move_speed := move_speed
	var health_multiplier := maxf(float(difficulty_settings.get("enemy_health_multiplier", 1.0)), 0.1)
	var speed_multiplier := maxf(float(difficulty_settings.get("enemy_speed_multiplier", 1.0)), 0.0)
	max_health = maxi(roundi(float(max_health) * health_multiplier), 1)
	current_health = max_health
	move_speed = base_move_speed * speed_multiplier
	pursuit_aggression_multiplier = maxf(float(difficulty_settings.get("enemy_aggression_multiplier", 1.0)), 0.0)
