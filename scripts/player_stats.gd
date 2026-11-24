extends Node

const STATS_PATH: String = "user://player_stats.cfg"
const STATS_SECTION: String = "stats"
const TOTAL_COINS_KEY: String = "total_coins"
const BEST_SCORE_KEY: String = "best_score"
const LEGACY_SCORE_PATH: String = "user://high_score.cfg"
const LEGACY_SCORE_SECTION: String = "scores"
const LEGACY_SCORE_KEY: String = "best"
const OWNED_SKINS_KEY: String = "owned_skins"
const EQUIPPED_SKIN_KEY: String = "equipped_skin"
const HIGHEST_RUN_COINS_KEY: String = "highest_run_coins"
const OWNED_DIFFICULTIES_KEY: String = "owned_difficulties"
const SELECTED_DIFFICULTY_KEY: String = "selected_difficulty"
const UNLIMITED_TIME_KEY: String = "unlimited_time"

var total_coins: int = 0
var best_score: int = 0
var highest_run_coins: int = 0
var owned_skin_ids: Array[String] = ["classic_blue"]
var equipped_skin_id: String = "classic_blue"
var owned_difficulty_ids: Array[String] = ["easy"]
var selected_difficulty_id: String = "easy"
var unlimited_time_enabled: bool = false

@onready var skin_catalog: Node = get_node("/root/SkinCatalog")
@onready var difficulty_config: Node = get_node("/root/DifficultyConfig")


func _ready() -> void:
	_load_stats()


func record_coin(reward: int, session_coins: int) -> void:
	var safe_reward := maxi(reward, 0)
	var safe_session_coins := maxi(session_coins, 0)
	total_coins += safe_reward
	best_score = maxi(best_score, safe_session_coins)
	highest_run_coins = maxi(highest_run_coins, safe_session_coins)
	_save_stats()


func owns_skin(skin_id: String) -> bool:
	return owned_skin_ids.has(skin_id)


func purchase_skin(skin_id: String) -> bool:
	if owns_skin(skin_id):
		return false

	var skin: Dictionary = skin_catalog.call("get_skin", skin_id)
	if skin.is_empty():
		return false

	var price := int(skin.get("price", 0))
	if price < 0 or total_coins < price:
		return false

	total_coins -= price
	owned_skin_ids.append(skin_id)
	if not _save_stats():
		total_coins += price
		owned_skin_ids.erase(skin_id)
		return false
	return true


func equip_skin(skin_id: String) -> bool:
	if not owns_skin(skin_id) or not bool(skin_catalog.call("has_skin", skin_id)):
		return false
	if equipped_skin_id == skin_id:
		return true

	var previous_skin_id := equipped_skin_id
	equipped_skin_id = skin_id
	if not _save_stats():
		equipped_skin_id = previous_skin_id
		return false
	return true


func owns_difficulty(difficulty_id: String) -> bool:
	return owned_difficulty_ids.has(difficulty_id)


func can_purchase_difficulty(difficulty_id: String) -> bool:
	var mode: Dictionary = difficulty_config.call("get_mode", difficulty_id)
	if mode.is_empty() or not bool(mode.get("implemented", false)) or owns_difficulty(difficulty_id):
		return false
	return (
		highest_run_coins >= int(mode.get("run_requirement", 0))
		and total_coins >= int(mode.get("purchase_price", 0))
	)


func purchase_difficulty(difficulty_id: String) -> bool:
	if not can_purchase_difficulty(difficulty_id):
		return false

	var mode: Dictionary = difficulty_config.call("get_mode", difficulty_id)
	var price := maxi(int(mode.get("purchase_price", 0)), 0)
	total_coins -= price
	owned_difficulty_ids.append(difficulty_id)
	if not _save_stats():
		total_coins += price
		owned_difficulty_ids.erase(difficulty_id)
		return false
	return true


func select_difficulty(difficulty_id: String) -> bool:
	if not bool(difficulty_config.call("is_implemented", difficulty_id)) or not owns_difficulty(difficulty_id):
		return false
	if selected_difficulty_id == difficulty_id:
		return true

	var previous_difficulty_id := selected_difficulty_id
	selected_difficulty_id = difficulty_id
	if not _save_stats():
		selected_difficulty_id = previous_difficulty_id
		return false
	return true


func set_unlimited_time_enabled(enabled: bool) -> bool:
	if unlimited_time_enabled == enabled:
		return true

	var previous_value := unlimited_time_enabled
	unlimited_time_enabled = enabled
	if not _save_stats():
		unlimited_time_enabled = previous_value
		return false
	return true


func _load_stats() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(STATS_PATH)
	if load_error == OK:
		total_coins = _safe_non_negative_int(config.get_value(STATS_SECTION, TOTAL_COINS_KEY, 0))
		best_score = _safe_non_negative_int(config.get_value(STATS_SECTION, BEST_SCORE_KEY, 0))
		highest_run_coins = _safe_non_negative_int(
			config.get_value(STATS_SECTION, HIGHEST_RUN_COINS_KEY, config.get_value(STATS_SECTION, BEST_SCORE_KEY, 0))
		)
		_load_owned_skins(config.get_value(STATS_SECTION, OWNED_SKINS_KEY, PackedStringArray(["classic_blue"])))
		_load_owned_difficulties(config.get_value(STATS_SECTION, OWNED_DIFFICULTIES_KEY, PackedStringArray(["easy"])))
		var saved_equipped: Variant = config.get_value(STATS_SECTION, EQUIPPED_SKIN_KEY, "classic_blue")
		if saved_equipped is String and owns_skin(saved_equipped) and bool(skin_catalog.call("has_skin", saved_equipped)):
			equipped_skin_id = str(saved_equipped)
		var saved_difficulty: Variant = config.get_value(STATS_SECTION, SELECTED_DIFFICULTY_KEY, "easy")
		if saved_difficulty is String and owns_difficulty(saved_difficulty) and bool(difficulty_config.call("is_implemented", saved_difficulty)):
			selected_difficulty_id = str(saved_difficulty)
		unlimited_time_enabled = bool(config.get_value(STATS_SECTION, UNLIMITED_TIME_KEY, false))
		return

	if load_error != ERR_FILE_NOT_FOUND:
		push_warning("Could not load player stats; using safe defaults: " + error_string(load_error))
	_load_legacy_best_score()


func _load_legacy_best_score() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(LEGACY_SCORE_PATH)
	if load_error == ERR_FILE_NOT_FOUND:
		return
	if load_error != OK:
		push_warning("Could not load the previous best score: " + error_string(load_error))
		return

	best_score = _safe_non_negative_int(config.get_value(LEGACY_SCORE_SECTION, LEGACY_SCORE_KEY, 0))
	highest_run_coins = maxi(highest_run_coins, best_score)


func _load_owned_skins(saved_skins: Variant) -> void:
	owned_skin_ids.clear()
	owned_skin_ids.append("classic_blue")

	if saved_skins is PackedStringArray:
		for skin_id in saved_skins:
			_add_owned_skin_if_valid(skin_id)
	elif saved_skins is Array:
		for skin_id in saved_skins:
			if skin_id is String:
				_add_owned_skin_if_valid(skin_id)


func _load_owned_difficulties(saved_difficulties: Variant) -> void:
	owned_difficulty_ids.clear()
	owned_difficulty_ids.append("easy")

	if saved_difficulties is PackedStringArray:
		for difficulty_id in saved_difficulties:
			_add_owned_difficulty_if_valid(difficulty_id)
	elif saved_difficulties is Array:
		for difficulty_id in saved_difficulties:
			if difficulty_id is String:
				_add_owned_difficulty_if_valid(difficulty_id)


func _add_owned_difficulty_if_valid(difficulty_id: String) -> void:
	if (
		bool(difficulty_config.call("is_implemented", difficulty_id))
		and not owned_difficulty_ids.has(difficulty_id)
	):
		owned_difficulty_ids.append(difficulty_id)


func _add_owned_skin_if_valid(skin_id: String) -> void:
	if bool(skin_catalog.call("has_skin", skin_id)) and not owned_skin_ids.has(skin_id):
		owned_skin_ids.append(skin_id)


func _safe_non_negative_int(value: Variant) -> int:
	match typeof(value):
		TYPE_INT:
			return maxi(int(value), 0)
		TYPE_FLOAT:
			return maxi(int(value), 0)
		TYPE_STRING:
			return maxi(int(value), 0)
		_:
			return 0


func _save_stats() -> bool:
	var config := ConfigFile.new()
	config.set_value(STATS_SECTION, TOTAL_COINS_KEY, total_coins)
	config.set_value(STATS_SECTION, BEST_SCORE_KEY, best_score)
	config.set_value(STATS_SECTION, HIGHEST_RUN_COINS_KEY, highest_run_coins)
	config.set_value(STATS_SECTION, OWNED_SKINS_KEY, PackedStringArray(owned_skin_ids))
	config.set_value(STATS_SECTION, EQUIPPED_SKIN_KEY, equipped_skin_id)
	config.set_value(STATS_SECTION, OWNED_DIFFICULTIES_KEY, PackedStringArray(owned_difficulty_ids))
	config.set_value(STATS_SECTION, SELECTED_DIFFICULTY_KEY, selected_difficulty_id)
	config.set_value(STATS_SECTION, UNLIMITED_TIME_KEY, unlimited_time_enabled)

	var save_error := config.save(STATS_PATH)
	if save_error != OK:
		push_error("Could not save player stats: " + error_string(save_error))
		return false
	return true
