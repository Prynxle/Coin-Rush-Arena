extends CharacterBody2D

@export var move_speed: float = 300.0
@export var shot_cooldown: float = 0.45

const PROJECTILE_SCENE: PackedScene = preload("res://scenes/Projectile.tscn")

var shooting_direction: Vector2 = Vector2.RIGHT
var shot_cooldown_remaining: float = 0.0
var shoot_feedback_remaining: float = 0.0
var animation_clock: float = 0.0
var is_dying: bool = false

@onready var visual: Polygon2D = $Visual
@onready var accent_visual: Polygon2D = $SkinAccent
@onready var player_stats: Node = get_node("/root/PlayerStats")
@onready var skin_catalog: Node = get_node("/root/SkinCatalog")


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
	animation_clock += delta
	shot_cooldown_remaining = maxf(shot_cooldown_remaining - delta, 0.0)
	shoot_feedback_remaining = maxf(shoot_feedback_remaining - delta, 0.0)
	if not is_dying:
		var movement_ratio := clampf(velocity.length() / maxf(move_speed, 1.0), 0.0, 1.0)
		var bob := sin(animation_clock * (5.5 if movement_ratio > 0.0 else 2.6)) * (0.025 if movement_ratio > 0.0 else 0.012)
		var shot_burst := clampf(shoot_feedback_remaining / 0.12, 0.0, 1.0) * 0.16
		visual.scale = Vector2(1.0 + bob + shot_burst, 1.0 - bob + shot_burst)
		visual.rotation = clampf(velocity.x / maxf(move_speed, 1.0), -1.0, 1.0) * 0.08
		if accent_visual.visible:
			accent_visual.rotation = sin(animation_clock * 1.7) * 0.08
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
	shoot_feedback_remaining = 0.12


func play_death_feedback() -> void:
	if is_dying:
		return
	is_dying = true
	set_process(false)
	var death_tween := create_tween()
	death_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	death_tween.set_parallel(true)
	death_tween.tween_property(visual, "scale", Vector2.ONE * 0.25, 0.28)
	death_tween.tween_property(visual, "modulate", Color(1.0, 0.28, 0.4, 0.0), 0.28)


func _apply_equipped_skin() -> void:
	var skin_id := str(player_stats.get("equipped_skin_id"))
	if not bool(skin_catalog.call("has_skin", skin_id)):
		skin_id = "classic_blue"

	var skin_color: Color = skin_catalog.call("get_color", skin_id)
	var skin_polygon: PackedVector2Array = skin_catalog.call("get_polygon", skin_id)
	var accent_color: Color = skin_catalog.call("get_accent_color", skin_id)
	var accent_polygon: PackedVector2Array = skin_catalog.call("get_accent_polygon", skin_id)
	visual.color = skin_color
	visual.polygon = skin_polygon
	accent_visual.color = accent_color
	accent_visual.polygon = accent_polygon
	accent_visual.visible = not accent_visual.polygon.is_empty()
