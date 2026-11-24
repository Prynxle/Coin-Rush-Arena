extends CharacterBody2D

@export var move_speed: float = 300.0
@export var shot_cooldown: float = 0.45

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")

var shooting_direction: Vector2 = Vector2.RIGHT
var shot_cooldown_remaining: float = 0.0

@onready var visual: Polygon2D = $Visual
@onready var accent_visual: Polygon2D = $SkinAccent


func _ready() -> void:
	_apply_equipped_skin()


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * move_speed
	move_and_slide()

	var arena_size := get_viewport_rect().size
	global_position.x = clampf(global_position.x, 18.0, arena_size.x - 18.0)
	global_position.y = clampf(global_position.y, 18.0, arena_size.y - 18.0)


func _process(delta: float) -> void:
	shot_cooldown_remaining = maxf(shot_cooldown_remaining - delta, 0.0)
	if Input.is_action_just_pressed("shoot") and shot_cooldown_remaining <= 0.0:
		_fire_projectile()


func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_UP:
			shooting_direction = Vector2.UP
		KEY_DOWN:
			shooting_direction = Vector2.DOWN
		KEY_LEFT:
			shooting_direction = Vector2.LEFT
		KEY_RIGHT:
			shooting_direction = Vector2.RIGHT


func _fire_projectile() -> void:
	var projectile := PROJECTILE_SCENE.instantiate() as Area2D
	projectile.global_position = global_position + shooting_direction * 24.0
	projectile.set("direction", shooting_direction)
	get_parent().add_child(projectile)
	shot_cooldown_remaining = shot_cooldown


func _apply_equipped_skin() -> void:
	var skin_id := PlayerStats.equipped_skin_id
	if not SkinCatalog.has_skin(skin_id):
		skin_id = SkinCatalog.CLASSIC_SKIN_ID

	visual.color = SkinCatalog.get_color(skin_id)
	visual.polygon = SkinCatalog.get_polygon(skin_id)
	accent_visual.color = SkinCatalog.get_accent_color(skin_id)
	accent_visual.polygon = SkinCatalog.get_accent_polygon(skin_id)
	accent_visual.visible = not accent_visual.polygon.is_empty()
