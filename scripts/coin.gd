extends Area2D

signal coin_collected

@onready var visual: Polygon2D = $Visual

var idle_time := 0.0
var starting_y := 0.0
var is_spawning := true
var is_collecting := false


func _ready() -> void:
	add_to_group("coins")
	body_entered.connect(_on_body_entered)
	starting_y = visual.position.y
	visual.scale = Vector2.ONE * 0.72
	var spawn_tween := create_tween()
	spawn_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	spawn_tween.tween_property(visual, "scale", Vector2.ONE, 0.24)
	spawn_tween.tween_callback(func() -> void: is_spawning = false)


func _process(delta: float) -> void:
	if is_collecting:
		return
	idle_time += delta
	visual.position.y = starting_y + sin(idle_time * 2.8) * 3.0
	visual.rotation = sin(idle_time * 1.5) * 0.08
	if not is_spawning:
		visual.scale = Vector2.ONE * (1.0 + sin(idle_time * 2.8) * 0.035)


func _on_body_entered(body: Node2D) -> void:
	if not body is CharacterBody2D or is_collecting:
		return

	is_collecting = true
	remove_from_group("coins")
	set_deferred("monitoring", false)
	$CollisionShape2D.set_deferred("disabled", true)
	coin_collected.emit()
	var collect_tween := create_tween()
	collect_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	collect_tween.set_parallel(true)
	collect_tween.tween_property(visual, "scale", Vector2.ZERO, 0.18)
	collect_tween.tween_property(visual, "modulate:a", 0.0, 0.18)
	collect_tween.tween_property(visual, "rotation", visual.rotation + TAU * 0.25, 0.18)
	collect_tween.chain().tween_callback(queue_free)
