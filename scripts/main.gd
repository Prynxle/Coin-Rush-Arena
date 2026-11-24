extends Node2D

const COIN_SCENE: PackedScene = preload("res://scenes/Coin.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
const HIGH_SCORE_PATH: String = "user://high_score.cfg"
const HIGH_SCORE_SECTION: String = "scores"
const HIGH_SCORE_KEY: String = "best"
const INITIAL_COIN_COUNT: int = 8
const INITIAL_ENEMY_COUNT: int = 7
const MAX_SPAWN_ATTEMPTS: int = 20
const COIN_SPAWN_RADIUS: float = 16.0
const ENEMY_SPAWN_RADIUS: float = 18.0

@export var round_duration_seconds: float = 60.0
@export var coin_spawn_interval: float = 2.0
@export var max_coins: int = 20
@export var enemy_multiplication_interval: float = 8.0
@export var max_enemies: int = 30
@export var enemies_per_reproduction: int = 4

var score: int = 0
var best_score: int = 0
var time_remaining: float = 60.0
var round_ended: bool = false
var is_paused: bool = false
var is_loading_scene: bool = false
var wait_one_loading_frame: bool = false
var coin_spawn_elapsed: float = 0.0
var enemy_multiplication_elapsed: float = 0.0
var initial_spawn_pending: bool = true

@onready var arena: Node2D = $Arena
@onready var player: CharacterBody2D = $Arena/Player
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var best_score_label: Label = $HUD/BestScoreLabel
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var game_over_label: Label = $HUD/GameOverPanel/GameOverLabel
@onready var final_score_label: Label = $HUD/GameOverPanel/FinalScoreLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_label: Label = $HUD/PauseLabel
@onready var restart_button: Button = $HUD/GameOverPanel/RestartButton
@onready var loading_panel: Control = $HUD/LoadingPanel
@onready var loading_label: Label = $HUD/LoadingPanel/LoadingLabel


func _ready() -> void:
	pause_button.pressed.connect(_toggle_pause)
	restart_button.pressed.connect(_begin_threaded_restart)
	player.position = get_viewport_rect().size * 0.5
	_load_best_score()
	_update_score_labels()
	time_remaining = round_duration_seconds
	_update_timer_label()


func _physics_process(delta: float) -> void:
	if round_ended or is_paused:
		return

	if initial_spawn_pending:
		initial_spawn_pending = false
		_spawn_coins()
		_spawn_enemies()

	_update_spawning(delta)


func _process(delta: float) -> void:
	_update_score_labels()

	if is_loading_scene:
		if wait_one_loading_frame:
			wait_one_loading_frame = false
			return
		_check_threaded_scene_load()
		return

	if round_ended or is_paused:
		return

	time_remaining = maxf(time_remaining - delta, 0.0)
	_update_timer_label()

	if time_remaining <= 0.0:
		_end_round("Time's up!")


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.keycode == KEY_ESCAPE and event.pressed and not event.echo:
		_toggle_pause()


func _toggle_pause() -> void:
	if round_ended:
		return

	is_paused = not is_paused
	get_tree().paused = is_paused
	pause_button.text = "Resume" if is_paused else "Pause"
	pause_label.visible = is_paused


func _begin_threaded_restart() -> void:
	if is_loading_scene:
		return

	is_loading_scene = true
	wait_one_loading_frame = true
	restart_button.disabled = true
	game_over_panel.visible = false
	loading_label.text = "Loading arena..."
	loading_panel.visible = true

	var request_error := ResourceLoader.load_threaded_request(
		MAIN_SCENE_PATH,
		"PackedScene",
		false,
		ResourceLoader.CACHE_MODE_IGNORE
	)
	if request_error != OK:
		_show_threaded_load_error("Request failed: " + error_string(request_error))


func _check_threaded_scene_load() -> void:
	var progress: Array = []
	var load_status := ResourceLoader.load_threaded_get_status(MAIN_SCENE_PATH, progress)

	if load_status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
		if not progress.is_empty():
			var percent_complete := roundi(progress[0] * 100.0)
			loading_label.text = "Loading arena... %d%%" % percent_complete
		return

	if load_status == ResourceLoader.THREAD_LOAD_FAILED:
		_show_threaded_load_error("Godot reported that the scene could not be loaded.")
		return

	if load_status == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
		_show_threaded_load_error("Godot could not find the requested loading operation.")
		return

	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var loaded_resource := ResourceLoader.load_threaded_get(MAIN_SCENE_PATH)
		var loaded_scene := loaded_resource as PackedScene
		if loaded_scene == null:
			_show_threaded_load_error("The loaded resource was not a PackedScene.")
			return

		var change_error := get_tree().change_scene_to_packed(loaded_scene)
		if change_error != OK:
			_show_threaded_load_error("Scene change failed: " + error_string(change_error))


func _show_threaded_load_error(message: String) -> void:
	is_loading_scene = false
	wait_one_loading_frame = false
	loading_panel.visible = false
	game_over_panel.visible = true
	game_over_label.text = "Restart failed"
	final_score_label.text = message
	restart_button.disabled = false
	push_error("Threaded scene loading failed: " + message)


func _update_timer_label() -> void:
	timer_label.text = "Time: %d" % ceili(time_remaining)


func _load_best_score() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(HIGH_SCORE_PATH)

	if load_error == ERR_FILE_NOT_FOUND:
		best_score = 0
		return

	if load_error != OK:
		best_score = 0
		push_error("Could not load the best score: " + error_string(load_error))
		return

	best_score = maxi(int(config.get_value(HIGH_SCORE_SECTION, HIGH_SCORE_KEY, 0)), 0)


func _save_best_score() -> void:
	var config := ConfigFile.new()
	config.set_value(HIGH_SCORE_SECTION, HIGH_SCORE_KEY, best_score)

	var save_error := config.save(HIGH_SCORE_PATH)
	if save_error != OK:
		push_error("Could not save the best score: " + error_string(save_error))


func _update_score_labels() -> void:
	score_label.text = "Score: %d" % score
	best_score_label.text = "Best: %d" % best_score


func _spawn_coins() -> void:
	for _coin_index in range(mini(INITIAL_COIN_COUNT, max_coins)):
		_spawn_coin()


func _spawn_enemies() -> void:
	for _enemy_index in range(mini(INITIAL_ENEMY_COUNT, max_enemies)):
		_spawn_enemy()


func _update_spawning(delta: float) -> void:
	if coin_spawn_interval > 0.0 and active_group_count("coins") < max_coins:
		coin_spawn_elapsed += delta
		if coin_spawn_elapsed >= coin_spawn_interval:
			coin_spawn_elapsed = 0.0
			_spawn_coin()

	if enemy_multiplication_interval > 0.0 and active_group_count("enemies") < max_enemies:
		enemy_multiplication_elapsed += delta
		if enemy_multiplication_elapsed >= enemy_multiplication_interval:
			enemy_multiplication_elapsed = 0.0
			for _offspring_index in range(enemies_per_reproduction):
				if not _spawn_enemy():
					break


func _spawn_coin() -> bool:
	if active_group_count("coins") >= max_coins:
		return false

	var spawn_position: Vector2 = _find_valid_spawn_position(COIN_SPAWN_RADIUS)
	if spawn_position == Vector2.ZERO:
		return false

	var coin := COIN_SCENE.instantiate() as Area2D
	coin.position = spawn_position
	coin.coin_collected.connect(_on_coin_collected)
	arena.add_child(coin)
	return true


func _spawn_enemy() -> bool:
	if active_group_count("enemies") >= max_enemies:
		return false

	var spawn_position: Vector2 = _find_valid_spawn_position(ENEMY_SPAWN_RADIUS)
	if spawn_position == Vector2.ZERO:
		return false

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	enemy.position = spawn_position
	enemy.set("target", player)
	enemy.connect("player_caught", _on_player_caught)
	arena.add_child(enemy)
	return true


func _find_valid_spawn_position(radius: float) -> Vector2:
	var viewport_size := get_viewport_rect().size
	var left_bound := 40.0
	var right_bound := viewport_size.x - 40.0
	var top_bound := 140.0
	var bottom_bound := viewport_size.y - 40.0
	if right_bound <= left_bound or bottom_bound <= top_bound:
		return Vector2.ZERO

	var space_state := get_world_2d().direct_space_state
	var shape := CircleShape2D.new()
	shape.radius = radius

	for _attempt in range(MAX_SPAWN_ATTEMPTS):
		var candidate := Vector2(
			randf_range(left_bound, right_bound),
			randf_range(top_bound, bottom_bound)
		)
		var query := PhysicsShapeQueryParameters2D.new()
		query.shape = shape
		query.transform = Transform2D(0.0, arena.to_global(candidate))
		query.collision_mask = 1
		query.collide_with_areas = true
		query.collide_with_bodies = true
		if space_state.intersect_shape(query, 1).is_empty():
			return candidate

	return Vector2.ZERO


func active_group_count(group_name: String) -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group(group_name):
		if is_instance_valid(node) and not node.is_queued_for_deletion():
			count += 1
	return count


func _on_coin_collected() -> void:
	if round_ended:
		return

	var active_coins_before: int = get_tree().get_nodes_in_group("coins").size()
	print("Active coins before collection: ", active_coins_before)

	score += 1
	if score > best_score:
		best_score = score
		_save_best_score()

	await get_tree().process_frame
	var active_coins_after: int = get_tree().get_nodes_in_group("coins").size()
	print("Active coins after collection: ", active_coins_after)


func _on_player_caught() -> void:
	_end_round("An enemy caught you!")


func _end_round(reason: String) -> void:
	if round_ended:
		return

	round_ended = true
	print("Round ended: ", reason)
	player.set_physics_process(false)
	game_over_label.text = reason
	final_score_label.text = "Final score: %d" % score
	game_over_panel.visible = true
	pause_button.disabled = true
	pause_button.visible = false

	for coin in get_tree().get_nodes_in_group("coins"):
		coin.queue_free()

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
