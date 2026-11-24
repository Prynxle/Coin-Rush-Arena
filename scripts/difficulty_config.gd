extends Node

const EASY_ID: String = "easy"
const MEDIUM_ID: String = "medium"
const HARD_ID: String = "hard"
const DOOMSDAY_ID: String = "doomsday"

var _modes: Array[Dictionary] = []


func _init() -> void:
	_modes = [
		{
			"id": EASY_ID,
			"name": "Easy",
			"description": "Slower pursuers and a gentle enemy growth rate.",
			"run_requirement": 0,
			"purchase_price": 0,
			"implemented": true,
			"enemy_health_multiplier": 1.0,
			"enemy_speed_multiplier": 0.65,
			"enemy_aggression_multiplier": 0.7,
			"enemy_spawn_interval": 10.0,
			"enemies_per_spawn": 1,
			"initial_enemy_count": 3,
			"coin_reward_multiplier": 1,
		},
		{
			"id": MEDIUM_ID,
			"name": "Medium",
			"description": "Faster, tougher enemies with a quicker growth rate.",
			"run_requirement": 75,
			"purchase_price": 75,
			"implemented": true,
			"enemy_health_multiplier": 2.0,
			"enemy_speed_multiplier": 0.95,
			"enemy_aggression_multiplier": 1.1,
			"enemy_spawn_interval": 7.0,
			"enemies_per_spawn": 2,
			"initial_enemy_count": 4,
			"coin_reward_multiplier": 1,
		},
		{
			"id": HARD_ID,
			"name": "Hard",
			"description": "Fast, resilient enemies and a 2x coin reward.",
			"run_requirement": 150,
			"purchase_price": 150,
			"implemented": true,
			"enemy_health_multiplier": 3.0,
			"enemy_speed_multiplier": 1.4,
			"enemy_aggression_multiplier": 1.5,
			"enemy_spawn_interval": 5.0,
			"enemies_per_spawn": 3,
			"initial_enemy_count": 5,
			"coin_reward_multiplier": 2,
		},
		{
			"id": DOOMSDAY_ID,
			"name": "Doomsday",
			"description": "Relentless red enemies and a projectile-firing boss after 60 seconds.",
			"run_requirement": 200,
			"purchase_price": 200,
			"implemented": true,
			"enemy_health_multiplier": 3.0,
			"enemy_speed_multiplier": 1.8,
			"enemy_aggression_multiplier": 1.9,
			"enemy_spawn_interval": 4.0,
			"enemies_per_spawn": 3,
			"initial_enemy_count": 6,
			"large_enemy_every": 3,
			"large_enemy_speed_multiplier": 2.0,
			"large_enemy_aggression_multiplier": 2.2,
			"large_enemy_size_multiplier": 1.5,
			"coin_reward_multiplier": 1,
			"boss_spawn_after_seconds": 60.0,
			"boss_fire_interval": 4.0,
			"boss_projectile_count": 8,
			"boss_projectile_speed": 300.0,
		},
	]


func get_all_modes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	result.assign(_modes)
	return result


func get_mode(difficulty_id: String) -> Dictionary:
	for mode in _modes:
		if mode["id"] == difficulty_id:
			return mode
	return {}


func get_enemy_settings(difficulty_id: String, is_large: bool = false) -> Dictionary:
	var mode := get_mode(difficulty_id)
	if mode.is_empty():
		return {}

	var settings := mode.duplicate(true)
	if difficulty_id == DOOMSDAY_ID and is_large:
		var hard_mode := get_mode(HARD_ID)
		settings["enemy_health_multiplier"] = float(hard_mode.get("enemy_health_multiplier", 1.0)) * 4.0
		settings["enemy_speed_multiplier"] = float(mode.get("large_enemy_speed_multiplier", 2.0))
		settings["enemy_aggression_multiplier"] = float(mode.get("large_enemy_aggression_multiplier", 2.2))
		settings["size_multiplier"] = float(mode.get("large_enemy_size_multiplier", 1.5))
	else:
		settings["size_multiplier"] = 0.7 if difficulty_id == DOOMSDAY_ID else 1.0
	return settings


func is_implemented(difficulty_id: String) -> bool:
	var mode := get_mode(difficulty_id)
	return not mode.is_empty() and bool(mode.get("implemented", false))


func get_coin_reward(base_value: int, difficulty_id: String) -> int:
	var mode := get_mode(difficulty_id)
	var multiplier := maxi(int(mode.get("coin_reward_multiplier", 1)), 1)
	return maxi(base_value, 0) * multiplier
