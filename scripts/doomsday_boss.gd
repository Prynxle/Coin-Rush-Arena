extends Area2D

const BOSS_PROJECTILE_SCENE: PackedScene = preload("res://scenes/BossProjectile.tscn")

@export var fire_interval: float = 4.0
@export var projectile_count: int = 8
@export var projectile_speed: float = 300.0
@export var projectile_damage: int = 12

var fire_elapsed: float = 0.0


func _ready() -> void:
	add_to_group("doomsday_bosses")


func _physics_process(delta: float) -> void:
	if fire_interval <= 0.0:
		return

	fire_elapsed += delta
	if fire_elapsed < fire_interval:
		return
	fire_elapsed = 0.0
	_fire_radial_burst()


func _fire_radial_burst() -> void:
	var count := maxi(projectile_count, 1)
	for projectile_index in range(count):
		var direction := Vector2.RIGHT.rotated(TAU * float(projectile_index) / float(count))
		var projectile := BOSS_PROJECTILE_SCENE.instantiate() as Area2D
		projectile.global_position = global_position + direction * 38.0
		projectile.set("direction", direction)
		projectile.set("speed", projectile_speed)
		projectile.set("damage", projectile_damage)
		get_parent().add_child(projectile)
