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

var total_coins: int = 0
var best_score: int = 0
var owned_skin_ids: Array[String] = ["classic_blue"]
var equipped_skin_id: String = "classic_blue"


func _ready() -> void:
	_load_stats()


func record_coin(session_score: int) -> void:
	total_coins += 1
	best_score = maxi(best_score, session_score)
	_save_stats()


func owns_skin(skin_id: String) -> bool:
	return owned_skin_ids.has(skin_id)


func purchase_skin(skin_id: String) -> bool:
	if owns_skin(skin_id):
		return false

	var skin := SkinCatalog.get_skin(skin_id)
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
	if not owns_skin(skin_id) or not SkinCatalog.has_skin(skin_id):
		return false
	if equipped_skin_id == skin_id:
		return true

	var previous_skin_id := equipped_skin_id
	equipped_skin_id = skin_id
	if not _save_stats():
		equipped_skin_id = previous_skin_id
		return false
	return true


func _load_stats() -> void:
	var config := ConfigFile.new()
	var load_error := config.load(STATS_PATH)
	if load_error == OK:
		total_coins = _safe_non_negative_int(config.get_value(STATS_SECTION, TOTAL_COINS_KEY, 0))
		best_score = _safe_non_negative_int(config.get_value(STATS_SECTION, BEST_SCORE_KEY, 0))
		_load_owned_skins(config.get_value(STATS_SECTION, OWNED_SKINS_KEY, PackedStringArray(["classic_blue"])))
		var saved_equipped: Variant = config.get_value(STATS_SECTION, EQUIPPED_SKIN_KEY, "classic_blue")
		if saved_equipped is String and owns_skin(saved_equipped) and SkinCatalog.has_skin(saved_equipped):
			equipped_skin_id = str(saved_equipped)
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


func _add_owned_skin_if_valid(skin_id: String) -> void:
	if SkinCatalog.has_skin(skin_id) and not owned_skin_ids.has(skin_id):
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
	config.set_value(STATS_SECTION, OWNED_SKINS_KEY, PackedStringArray(owned_skin_ids))
	config.set_value(STATS_SECTION, EQUIPPED_SKIN_KEY, equipped_skin_id)

	var save_error := config.save(STATS_PATH)
	if save_error != OK:
		push_error("Could not save player stats: " + error_string(save_error))
		return false
	return true
