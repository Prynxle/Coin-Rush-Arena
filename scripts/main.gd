extends Node2D

const COIN_SCENE: PackedScene = preload("res://scenes/Coin.tscn")
const ENEMY_SCENE: PackedScene = preload("res://scenes/Enemy.tscn")
const DOOMSDAY_BOSS_SCENE: PackedScene = preload("res://scenes/DoomsdayBoss.tscn")
const MAIN_SCENE_PATH: String = "res://scenes/Main.tscn"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/MainMenu.tscn"
const INITIAL_COIN_COUNT: int = 8
const INITIAL_ENEMY_COUNT: int = 3
const MAX_SPAWN_ATTEMPTS: int = 50
const COIN_SPAWN_RADIUS: float = 16.0
const ENEMY_SPAWN_RADIUS: float = 18.0
const BOSS_SPAWN_RADIUS: float = 34.0

@export var round_duration_seconds: float = 180.0
@export var coin_spawn_interval: float = 1.0
@export var max_coins: int = 20
@export var enemy_multiplication_interval: float = 8.0
@export var max_enemies: int = 100
@export var enemies_per_reproduction: int = 4

var score: int = 0
var time_remaining: float = 180.0
var round_ended: bool = false
var is_paused: bool = false
var is_loading_scene: bool = false
var wait_one_loading_frame: bool = false
var coin_spawn_elapsed: float = 0.0
var enemy_multiplication_elapsed: float = 0.0
var initial_spawn_pending: bool = true
var last_coin_reward: int = 0
var run_elapsed_seconds: float = 0.0
var doomsday_enemy_spawn_index: int = 0
var doomsday_boss_spawned: bool = false
var boss_spawn_retry_remaining: float = 0.0
var best_score_at_start: int = 0
var new_best_achieved: bool = false
var coin_feedback_remaining: float = 0.0
var score_bump_tween: Tween
var pause_overlay: Control
var pause_card: PanelContainer
var hud_button_tweens: Dictionary = {}

@onready var arena: Node2D = $Arena
@onready var player: CharacterBody2D = $Arena/Player
@onready var player_stats: Node = get_node("/root/PlayerStats")
@onready var difficulty_config: Node = get_node("/root/DifficultyConfig")
@onready var score_label: Label = $HUD/ScoreLabel
@onready var timer_label: Label = $HUD/TimerLabel
@onready var best_score_label: Label = $HUD/BestScoreLabel
@onready var game_over_panel: Control = $HUD/GameOverPanel
@onready var game_over_label: Label = $HUD/GameOverPanel/GameOverLabel
@onready var final_score_label: Label = $HUD/GameOverPanel/FinalScoreLabel
@onready var pause_button: Button = $HUD/PauseButton
@onready var pause_label: Label = $HUD/PauseLabel
@onready var restart_button: Button = $HUD/GameOverPanel/RestartButton
@onready var main_menu_button: Button = $HUD/GameOverPanel/MainMenuButton
@onready var loading_panel: Control = $HUD/LoadingPanel
@onready var loading_label: Label = $HUD/LoadingPanel/LoadingLabel


func _ready() -> void:
	pause_button.pressed.connect(_toggle_pause)
	restart_button.pressed.connect(_begin_threaded_restart)
	main_menu_button.pressed.connect(_return_to_main_menu)
	best_score_at_start = int(player_stats.get("best_score"))
	player.position = get_viewport_rect().size * 0.5
	_style_game_hud()
	_build_pause_overlay()
	_update_score_labels()
	time_remaining = round_duration_seconds
	_update_timer_label()


func _physics_process(delta: float) -> void:
	if round_ended or is_paused:
		return

	run_elapsed_seconds += delta
	_try_spawn_doomsday_boss(delta)

	if initial_spawn_pending:
		initial_spawn_pending = false
		_spawn_coins()
		_spawn_enemies()

	_update_spawning(delta)


func _process(delta: float) -> void:
	coin_feedback_remaining = maxf(coin_feedback_remaining - delta, 0.0)
	_update_score_labels()

	if is_loading_scene:
		if wait_one_loading_frame:
			wait_one_loading_frame = false
			return
		_check_threaded_scene_load()
		return

	if round_ended or is_paused:
		return

	if bool(player_stats.get("unlimited_time_enabled")):
		_update_timer_label()
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
	pause_label.visible = false
	if is_instance_valid(pause_overlay):
		pause_overlay.visible = is_paused
		if is_paused:
			pause_overlay.modulate.a = 0.0
			var pause_tween := create_tween()
			pause_tween.tween_property(pause_overlay, "modulate:a", 1.0, 0.16)


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
	if bool(player_stats.get("unlimited_time_enabled")):
		timer_label.text = "TIME: Unlimited"
	else:
		timer_label.text = "TIME: %d" % ceili(time_remaining)


func _update_score_labels() -> void:
	if last_coin_reward > 0 and coin_feedback_remaining > 0.0:
		score_label.text = "COINS  %d   +%d" % [score, last_coin_reward]
	else:
		score_label.text = "COINS  %d" % score
	best_score_label.text = "BEST  %d" % int(player_stats.get("best_score"))


func _spawn_coins() -> void:
	for _coin_index in range(mini(INITIAL_COIN_COUNT, max_coins)):
		_spawn_coin()


func _spawn_enemies() -> void:
	var mode := _active_difficulty()
	var initial_enemy_count := int(mode.get("initial_enemy_count", INITIAL_ENEMY_COUNT))
	for _enemy_index in range(mini(initial_enemy_count, max_enemies)):
		_spawn_enemy()


func _update_spawning(delta: float) -> void:
	if coin_spawn_interval > 0.0 and active_group_count("coins") < max_coins:
		coin_spawn_elapsed += delta
		if coin_spawn_elapsed >= coin_spawn_interval:
			coin_spawn_elapsed = 0.0
			_spawn_coin()

	var mode := _active_difficulty()
	var enemy_spawn_interval := float(mode.get("enemy_spawn_interval", enemy_multiplication_interval))
	if enemy_spawn_interval > 0.0 and active_group_count("enemies") < max_enemies:
		enemy_multiplication_elapsed += delta
		if enemy_multiplication_elapsed >= enemy_spawn_interval:
			enemy_multiplication_elapsed = 0.0
			var enemies_per_spawn := int(mode.get("enemies_per_spawn", enemies_per_reproduction))
			for _offspring_index in range(enemies_per_spawn):
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

	var mode := _active_difficulty()
	var difficulty_id := str(mode["id"])
	var is_large_doomsday_enemy := false
	var next_doomsday_spawn_index := doomsday_enemy_spawn_index + 1
	if difficulty_id == "doomsday":
		var large_enemy_every := maxi(int(mode.get("large_enemy_every", 3)), 1)
		is_large_doomsday_enemy = next_doomsday_spawn_index % large_enemy_every == 0

	var enemy_settings: Dictionary = difficulty_config.call(
		"get_enemy_settings",
		difficulty_id,
		is_large_doomsday_enemy
	)
	var size_multiplier := maxf(float(enemy_settings.get("size_multiplier", 1.0)), 0.1)
	var spawn_position: Vector2 = _find_valid_spawn_position(ENEMY_SPAWN_RADIUS * size_multiplier)
	if spawn_position == Vector2.ZERO:
		return false

	var enemy := ENEMY_SCENE.instantiate() as Area2D
	enemy.position = spawn_position
	enemy.set("target", player)
	enemy.set("difficulty_settings", enemy_settings)
	enemy.scale = Vector2.ONE * size_multiplier
	enemy.connect("player_caught", _on_player_caught)
	arena.add_child(enemy)
	if difficulty_id == "doomsday":
		doomsday_enemy_spawn_index = next_doomsday_spawn_index
	return true


func _try_spawn_doomsday_boss(delta: float) -> void:
	if doomsday_boss_spawned:
		return

	var mode := _active_difficulty()
	var spawn_delay := float(mode.get("boss_spawn_after_seconds", -1.0))
	if spawn_delay < 0.0 or run_elapsed_seconds < spawn_delay:
		return

	if boss_spawn_retry_remaining > 0.0:
		boss_spawn_retry_remaining = maxf(boss_spawn_retry_remaining - delta, 0.0)
		return

	var spawn_position := _find_valid_spawn_position(BOSS_SPAWN_RADIUS)
	if spawn_position == Vector2.ZERO:
		boss_spawn_retry_remaining = 1.0
		return

	var boss := DOOMSDAY_BOSS_SCENE.instantiate() as Area2D
	boss.position = spawn_position
	boss.set("fire_interval", float(mode.get("boss_fire_interval", 4.0)))
	boss.set("projectile_count", int(mode.get("boss_projectile_count", 8)))
	boss.set("projectile_speed", float(mode.get("boss_projectile_speed", 300.0)))
	var hard_mode: Dictionary = difficulty_config.call("get_mode", "hard")
	var hard_health := maxi(roundi(float(hard_mode.get("enemy_health_multiplier", 1.0))), 1)
	boss.set("projectile_damage", hard_health * 4)
	arena.add_child(boss)
	doomsday_boss_spawned = true


func _active_difficulty() -> Dictionary:
	var difficulty_id := str(player_stats.get("selected_difficulty_id"))
	var mode: Dictionary = difficulty_config.call("get_mode", difficulty_id)
	if mode.is_empty() or not bool(mode.get("implemented", false)):
		mode = difficulty_config.call("get_mode", "easy")
	return mode


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

	var active_difficulty := _active_difficulty()
	var coin_reward := int(difficulty_config.call("get_coin_reward", 1, str(active_difficulty["id"])))
	score += coin_reward
	last_coin_reward = coin_reward
	coin_feedback_remaining = 0.9
	if score > best_score_at_start:
		new_best_achieved = true
	player_stats.call("record_coin", coin_reward, score)
	_bump_score_display()

	await get_tree().process_frame
	var active_coins_after: int = get_tree().get_nodes_in_group("coins").size()
	print("Active coins after collection: ", active_coins_after)


func _on_player_caught() -> void:
	_end_round("An enemy caught you!")


func on_doomsday_projectile_hit(body: Node2D) -> void:
	if body == player:
		_end_round("A Doomsday projectile hit you!")


func _return_to_main_menu() -> void:
	get_tree().paused = false
	is_paused = false
	var change_error := get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if change_error != OK:
		push_error("Could not return to the main menu: " + error_string(change_error))


func _end_round(reason: String) -> void:
	if round_ended:
		return

	round_ended = true
	print("Round ended: ", reason)
	player.set_physics_process(false)
	player.call("play_death_feedback")
	game_over_label.text = reason
	final_score_label.text = "RUN COINS  %d\nBEST SCORE  %d%s" % [
		score,
		int(player_stats.get("best_score")),
		"  |  NEW RECORD!" if new_best_achieved else "",
	]
	final_score_label.add_theme_color_override("font_color", Color("#ffd479") if new_best_achieved else Color("#e4f2ff"))
	final_score_label.offset_top = -4.0
	final_score_label.offset_bottom = 62.0
	final_score_label.offset_left = -240.0
	final_score_label.offset_right = 240.0
	restart_button.offset_top = 88.0
	restart_button.offset_bottom = 132.0
	main_menu_button.offset_top = 144.0
	main_menu_button.offset_bottom = 188.0
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	var game_over_tween := create_tween()
	game_over_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	game_over_tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.24)
	pause_button.disabled = true
	pause_button.visible = false
	main_menu_button.visible = true

	for coin in get_tree().get_nodes_in_group("coins"):
		coin.queue_free()

	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.queue_free()
	for boss in get_tree().get_nodes_in_group("doomsday_bosses"):
		boss.queue_free()
	for projectile in get_tree().get_nodes_in_group("doomsday_projectiles"):
		projectile.queue_free()


func _style_game_hud() -> void:
	var hud_panel := Panel.new()
	hud_panel.position = Vector2(14.0, 12.0)
	hud_panel.size = Vector2(330.0, 132.0)
	hud_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.025, 0.07, 0.13, 0.88)
	panel_style.border_color = Color(0.18, 0.78, 0.92, 0.38)
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(12)
	panel_style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	panel_style.shadow_size = 8
	hud_panel.add_theme_stylebox_override("panel", panel_style)
	$HUD.add_child(hud_panel)
	$HUD.move_child(hud_panel, 0)
	_style_hud_label(score_label, Color("#ffd479"), 23)
	_style_hud_label(timer_label, Color("#63e7df"), 18)
	_style_hud_label(best_score_label, Color("#a9c6e4"), 18)
	_style_game_button(pause_button, Color("#1c5168"))
	_style_game_button(restart_button, Color("#16635e"))
	_style_game_button(main_menu_button, Color("#263b59"))
	$HUD/LoadingPanel/Shade.color = Color(0.01, 0.025, 0.06, 0.86)
	loading_label.add_theme_color_override("font_color", Color("#63e7df"))
	loading_label.add_theme_font_size_override("font_size", 26)
	var game_over_card := PanelContainer.new()
	game_over_card.anchor_left = 0.5
	game_over_card.anchor_top = 0.5
	game_over_card.anchor_right = 0.5
	game_over_card.anchor_bottom = 0.5
	game_over_card.offset_left = -280.0
	game_over_card.offset_top = -220.0
	game_over_card.offset_right = 280.0
	game_over_card.offset_bottom = 220.0
	game_over_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var card_style := StyleBoxFlat.new()
	card_style.bg_color = Color("#0e1c30")
	card_style.border_color = Color("#3c8299")
	card_style.set_border_width_all(1)
	card_style.set_corner_radius_all(20)
	card_style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	card_style.shadow_size = 18
	game_over_card.add_theme_stylebox_override("panel", card_style)
	game_over_panel.add_child(game_over_card)
	game_over_panel.move_child(game_over_card, 1)
	game_over_label.add_theme_color_override("font_color", Color("#63e7df"))
	game_over_label.add_theme_font_size_override("font_size", 30)
	game_over_label.offset_left = -240.0
	game_over_label.offset_right = 240.0
	final_score_label.add_theme_font_size_override("font_size", 21)
	final_score_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _style_hud_label(label: Label, color: Color, font_size: int) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_shadow_color", Color(0.1, 0.65, 0.9, 0.35))
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_constant_override("outline_size", 0)


func _style_game_button(button: Button, color: Color) -> void:
	button.custom_minimum_size = Vector2(150.0, 46.0)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color("#e6f6ff"))
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _game_button_style(color))
	button.add_theme_stylebox_override("hover", _game_button_style(color.lightened(0.18)))
	button.add_theme_stylebox_override("pressed", _game_button_style(color.darkened(0.12)))
	button.mouse_entered.connect(_animate_hud_button.bind(button, true))
	button.mouse_exited.connect(_animate_hud_button.bind(button, false))
	button.focus_entered.connect(_animate_hud_button.bind(button, true))
	button.focus_exited.connect(_animate_hud_button.bind(button, false))
	button.button_down.connect(_animate_hud_button_press.bind(button, true))
	button.button_up.connect(_animate_hud_button_press.bind(button, false))


func _game_button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = color.lightened(0.2)
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.2)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0.0, 3.0)
	return style


func _build_pause_overlay() -> void:
	pause_overlay = Control.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pause_overlay.visible = false
	pause_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	$HUD.add_child(pause_overlay)

	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.01, 0.025, 0.06, 0.78)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_overlay.add_child(shade)

	pause_card = PanelContainer.new()
	pause_card.custom_minimum_size = Vector2(360.0, 250.0)
	pause_card.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	pause_card.offset_left = -180.0
	pause_card.offset_top = -125.0
	pause_card.offset_right = 180.0
	pause_card.offset_bottom = 125.0
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0f1f34")
	style.border_color = Color("#45b9d2")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.4)
	style.shadow_size = 18
	pause_card.add_theme_stylebox_override("panel", style)
	pause_overlay.add_child(pause_card)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 28)
	margin.add_theme_constant_override("margin_right", 28)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 22)
	pause_card.add_child(margin)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 12)
	margin.add_child(layout)
	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	title.add_theme_color_override("font_color", Color("#61e7df"))
	layout.add_child(title)
	layout.add_child(_make_game_button("RESUME", _toggle_pause, Color("#17665f")))
	layout.add_child(_make_game_button("MAIN MENU", _return_to_main_menu, Color("#263b59")))


func _make_game_button(text: String, callback: Callable, color: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 46.0
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.pressed.connect(callback)
	_style_game_button(button, color)
	return button


func _animate_hud_button(button: Button, highlighted: bool) -> void:
	if not is_instance_valid(button) or button.disabled:
		return
	var key := button.get_instance_id()
	var previous: Variant = hud_button_tweens.get(key)
	if previous is Tween and is_instance_valid(previous):
		previous.kill()
	button.pivot_offset = button.size * 0.5
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.set_parallel(true)
	tween.tween_property(button, "scale", Vector2.ONE * (1.025 if highlighted else 1.0), 0.12)
	tween.tween_property(button, "modulate", Color(1.06, 1.1, 1.13, 1.0) if highlighted else Color.WHITE, 0.12)
	hud_button_tweens[key] = tween


func _animate_hud_button_press(button: Button, pressed: bool) -> void:
	if pressed:
		var key := button.get_instance_id()
		var previous: Variant = hud_button_tweens.get(key)
		if previous is Tween and is_instance_valid(previous):
			previous.kill()
		var tween := create_tween()
		tween.tween_property(button, "scale", Vector2.ONE * 0.97, 0.07)
		hud_button_tweens[key] = tween
	else:
		_animate_hud_button(button, button.is_hovered() or button.has_focus())


func _bump_score_display() -> void:
	if score_bump_tween != null and score_bump_tween.is_running():
		score_bump_tween.kill()
	score_label.pivot_offset = score_label.size * 0.5
	score_label.scale = Vector2.ONE * 1.12
	score_label.modulate = Color("#fff2ca")
	score_bump_tween = create_tween()
	score_bump_tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	score_bump_tween.set_parallel(true)
	score_bump_tween.tween_property(score_label, "scale", Vector2.ONE, 0.22)
	score_bump_tween.tween_property(score_label, "modulate", Color.WHITE, 0.22)
