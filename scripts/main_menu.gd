extends Control

const GAME_SCENE_PATH: String = "res://scenes/Main.tscn"

const BACKGROUND_COLOR: Color = Color("#0a1422")
const PANEL_COLOR: Color = Color("#101f32")
const CARD_COLOR: Color = Color("#172b42")
const ACCENT_COLOR: Color = Color("#63d6c3")
const MUTED_COLOR: Color = Color("#9bb0c5")
const BUTTON_COLOR: Color = Color("#1b3550")
const BUTTON_HOVER_COLOR: Color = Color("#294a65")
const BUTTON_PRESSED_COLOR: Color = Color("#245e5b")
const SKIN_PREVIEW_SCRIPT: Script = preload("res://scripts/skin_preview.gd")

var menu_panel: PanelContainer
var credits_panel: PanelContainer
var shop_panel: PanelContainer
var difficulty_panel: PanelContainer
var menu_total_coins_value: Label
var menu_best_score_value: Label
var skin_list: VBoxContainer
var skin_row_buttons: Dictionary = {}
var shop_balance_label: Label
var shop_selected_name: Label
var shop_description: Label
var shop_preview: Control
var shop_status_label: Label
var shop_feedback_label: Label
var shop_action_button: Button
var selected_skin_id: String = "classic_blue"
var difficulty_balance_label: Label
var difficulty_feedback_label: Label
var unlimited_time_toggle: CheckButton
var difficulty_status_labels: Dictionary = {}
var difficulty_action_buttons: Dictionary = {}
var player_stats: Node
var skin_catalog: Node
var difficulty_config: Node


func _ready() -> void:
	player_stats = get_node("/root/PlayerStats")
	skin_catalog = get_node("/root/SkinCatalog")
	difficulty_config = get_node("/root/DifficultyConfig")
	_build_interface()


func _build_interface() -> void:
	var background := ColorRect.new()
	background.color = BACKGROUND_COLOR
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	menu_panel = _make_panel(500.0)
	center.add_child(menu_panel)
	var menu_margin := _make_margin(menu_panel)
	var menu_layout := VBoxContainer.new()
	menu_layout.add_theme_constant_override("separation", 14)
	menu_margin.add_child(menu_layout)

	var title := _make_label("COIN RUSH ARENA", 38, ACCENT_COLOR)
	menu_layout.add_child(title)
	var subtitle := _make_label("COLLECT  /  SURVIVE  /  KEEP MOVING", 13, MUTED_COLOR)
	menu_layout.add_child(subtitle)

	var divider := HSeparator.new()
	menu_layout.add_child(divider)

	var stats_row := HBoxContainer.new()
	stats_row.add_theme_constant_override("separation", 12)
	menu_layout.add_child(stats_row)
	menu_total_coins_value = _make_label(str(_stats_int("total_coins")), 28, Color.WHITE)
	menu_best_score_value = _make_label(str(_stats_int("best_score")), 28, Color.WHITE)
	stats_row.add_child(_make_stat_card("LIFETIME COINS", menu_total_coins_value))
	stats_row.add_child(_make_stat_card("BEST SCORE", menu_best_score_value))

	menu_layout.add_child(_make_button("START", _start_game, ACCENT_COLOR))
	menu_layout.add_child(_make_button("DIFFICULTY MODES", _show_difficulty_panel))
	menu_layout.add_child(_make_button("SKINS", _show_shop))
	menu_layout.add_child(_make_button("CREDITS", _show_credits))
	menu_layout.add_child(_make_button("QUIT GAME", _quit_game))

	credits_panel = _make_panel(420.0)
	credits_panel.visible = false
	center.add_child(credits_panel)
	var credits_margin := _make_margin(credits_panel)
	var credits_layout := VBoxContainer.new()
	credits_layout.add_theme_constant_override("separation", 18)
	credits_margin.add_child(credits_layout)
	credits_layout.add_child(_make_label("CREDITS", 32, ACCENT_COLOR))
	credits_layout.add_child(_make_label("Zedrick Espiritu", 22, Color.WHITE))
	credits_layout.add_child(_make_label("AI", 18, MUTED_COLOR))
	credits_layout.add_child(_make_button("BACK TO MENU", _show_menu, ACCENT_COLOR))

	_build_difficulty_panel(center)
	_build_shop(center)


func _make_panel(width: float) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.x = width
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_COLOR
	style.border_color = Color("#29445d")
	style.set_border_width_all(1)
	style.set_corner_radius_all(18)
	style.content_margin_left = 1.0
	style.content_margin_right = 1.0
	style.content_margin_top = 1.0
	style.content_margin_bottom = 1.0
	panel.add_theme_stylebox_override("panel", style)
	return panel


func _make_margin(panel: PanelContainer) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 30)
	margin.add_theme_constant_override("margin_right", 30)
	margin.add_theme_constant_override("margin_top", 28)
	margin.add_theme_constant_override("margin_bottom", 28)
	panel.add_child(margin)
	return margin


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_stat_card(caption: String, value: Label) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var style := StyleBoxFlat.new()
	style.bg_color = CARD_COLOR
	style.set_corner_radius_all(12)
	style.content_margin_left = 10.0
	style.content_margin_right = 10.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	card.add_theme_stylebox_override("panel", style)

	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 4)
	card.add_child(layout)
	layout.add_child(_make_label(caption, 12, MUTED_COLOR))
	layout.add_child(value)
	return card


func _make_button(text: String, callback: Callable, font_color: Color = Color.WHITE) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0.0, 48.0)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _button_style(BUTTON_COLOR))
	button.add_theme_stylebox_override("hover", _button_style(BUTTON_HOVER_COLOR))
	button.add_theme_stylebox_override("pressed", _button_style(BUTTON_PRESSED_COLOR))
	button.add_theme_stylebox_override("focus", _button_style(BUTTON_HOVER_COLOR))
	button.pressed.connect(callback)
	return button


func _stats_int(property_name: String) -> int:
	return int(player_stats.get(property_name))


func _stats_string(property_name: String) -> String:
	return str(player_stats.get(property_name))


func _stats_bool(property_name: String) -> bool:
	return bool(player_stats.get(property_name))


func _stats_call_bool(method_name: String, argument: String) -> bool:
	return bool(player_stats.call(method_name, argument))


func _all_difficulty_modes() -> Array[Dictionary]:
	var modes: Array[Dictionary] = []
	modes.assign(difficulty_config.call("get_all_modes"))
	return modes


func _difficulty_mode(difficulty_id: String) -> Dictionary:
	var mode: Dictionary = difficulty_config.call("get_mode", difficulty_id)
	return mode


func _all_skins() -> Array[Dictionary]:
	var skins: Array[Dictionary] = []
	skins.assign(skin_catalog.call("get_all_skins"))
	return skins


func _skin_definition(skin_id: String) -> Dictionary:
	var skin: Dictionary = skin_catalog.call("get_skin", skin_id)
	return skin


func _stats_skin_action(method_name: String, skin_id: String) -> bool:
	return bool(player_stats.call(method_name, skin_id))


func _button_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(10)
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style


func _start_game() -> void:
	var change_error := get_tree().change_scene_to_file(GAME_SCENE_PATH)
	if change_error != OK:
		push_error("Could not start the game: " + error_string(change_error))


func _show_credits() -> void:
	menu_panel.visible = false
	shop_panel.visible = false
	difficulty_panel.visible = false
	credits_panel.visible = true


func _show_menu() -> void:
	credits_panel.visible = false
	shop_panel.visible = false
	difficulty_panel.visible = false
	menu_panel.visible = true
	menu_total_coins_value.text = str(_stats_int("total_coins"))
	menu_best_score_value.text = str(_stats_int("best_score"))


func _build_difficulty_panel(center: CenterContainer) -> void:
	difficulty_panel = _make_panel(900.0)
	difficulty_panel.custom_minimum_size.y = 560.0
	difficulty_panel.visible = false
	center.add_child(difficulty_panel)
	var panel_margin := _make_margin(difficulty_panel)
	var layout := VBoxContainer.new()
	layout.add_theme_constant_override("separation", 8)
	panel_margin.add_child(layout)
	layout.add_child(_make_label("DIFFICULTY MODES", 30, ACCENT_COLOR))
	difficulty_balance_label = _make_label("Lifetime coins: 0  |  Best run: 0", 16, MUTED_COLOR)
	layout.add_child(difficulty_balance_label)
	layout.add_child(_make_label("Run records qualify purchases. Lifetime coins pay for unlocks.", 13, MUTED_COLOR))
	unlimited_time_toggle = CheckButton.new()
	unlimited_time_toggle.text = "Unlimited time (disable the round countdown)"
	unlimited_time_toggle.set_pressed_no_signal(_stats_bool("unlimited_time_enabled"))
	unlimited_time_toggle.toggled.connect(_on_unlimited_time_toggled)
	layout.add_child(unlimited_time_toggle)
	layout.add_child(HSeparator.new())

	for mode in _all_difficulty_modes():
		var difficulty_id: String = mode["id"]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 74.0
		row.add_theme_constant_override("separation", 14)
		layout.add_child(row)

		var mode_info := VBoxContainer.new()
		mode_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mode_info.add_theme_constant_override("separation", 2)
		row.add_child(mode_info)
		var name_label := _make_label(str(mode["name"]), 18, Color.WHITE)
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mode_info.add_child(name_label)
		var description_label := _make_label(str(mode["description"]), 12, MUTED_COLOR)
		description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		mode_info.add_child(description_label)
		var requirement_label := _make_label(_difficulty_requirement_text(mode), 12, MUTED_COLOR)
		requirement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		mode_info.add_child(requirement_label)

		var action_button := _make_button("", _on_difficulty_action.bind(difficulty_id))
		action_button.custom_minimum_size.x = 210.0
		row.add_child(action_button)
		difficulty_action_buttons[difficulty_id] = action_button
		difficulty_status_labels[difficulty_id] = name_label

	difficulty_feedback_label = _make_label("", 14, ACCENT_COLOR)
	layout.add_child(difficulty_feedback_label)
	layout.add_child(_make_button("BACK TO MENU", _show_menu))
	_refresh_difficulty_panel()


func _difficulty_requirement_text(mode: Dictionary) -> String:
	var requirement := int(mode.get("run_requirement", 0))
	var price := int(mode.get("purchase_price", 0))
	if requirement == 0:
		return "Run record: none  |  Price: free"
	return "Run record: %d coins  |  Price: %d lifetime coins" % [requirement, price]


func _difficulty_status(difficulty_id: String, mode: Dictionary) -> String:
	if not bool(mode.get("implemented", false)):
		return "Coming Soon"
	if _stats_string("selected_difficulty_id") == difficulty_id:
		return "Currently Selected"
	if _stats_call_bool("owns_difficulty", difficulty_id):
		if difficulty_id == "easy":
			return "Available"
		return "Purchased"
	if _stats_int("highest_run_coins") >= int(mode.get("run_requirement", 0)):
		return "Eligible for Purchase"
	return "Locked"


func _refresh_difficulty_panel() -> void:
	if not is_instance_valid(difficulty_balance_label):
		return
	difficulty_balance_label.text = "Lifetime coins: %d  |  Best run: %d" % [
		_stats_int("total_coins"),
		_stats_int("highest_run_coins"),
	]

	for mode in _all_difficulty_modes():
		var difficulty_id: String = mode["id"]
		var status := _difficulty_status(difficulty_id, mode)
		var status_label := difficulty_status_labels[difficulty_id] as Label
		status_label.text = "%s  -  %s" % [mode["name"], status]
		var action_button := difficulty_action_buttons[difficulty_id] as Button
		if status == "Coming Soon":
			action_button.text = "COMING SOON"
			action_button.disabled = true
		elif status == "Currently Selected":
			action_button.text = "CURRENTLY SELECTED"
			action_button.disabled = true
		elif status == "Purchased" or status == "Available":
			action_button.text = "SELECT"
			action_button.disabled = false
		elif status == "Eligible for Purchase":
			action_button.text = "PURCHASE - %d COINS" % int(mode["purchase_price"])
			action_button.disabled = false
		else:
			action_button.text = "LOCKED"
			action_button.disabled = true


func _show_difficulty_panel() -> void:
	menu_panel.visible = false
	credits_panel.visible = false
	shop_panel.visible = false
	difficulty_panel.visible = true
	difficulty_feedback_label.text = ""
	unlimited_time_toggle.button_pressed = _stats_bool("unlimited_time_enabled")
	_refresh_difficulty_panel()


func _on_unlimited_time_toggled(enabled: bool) -> void:
	if not bool(player_stats.call("set_unlimited_time_enabled", enabled)):
		unlimited_time_toggle.set_pressed_no_signal(_stats_bool("unlimited_time_enabled"))
		difficulty_feedback_label.text = "Could not save the unlimited-time setting."


func _on_difficulty_action(difficulty_id: String) -> void:
	var mode := _difficulty_mode(difficulty_id)
	if mode.is_empty():
		return
	if not bool(mode.get("implemented", false)):
		difficulty_feedback_label.text = "Doomsday is coming soon and cannot be selected or purchased yet."
		return

	if _stats_call_bool("owns_difficulty", difficulty_id):
		if _stats_call_bool("select_difficulty", difficulty_id):
			difficulty_feedback_label.text = "%s selected." % mode["name"]
		else:
			difficulty_feedback_label.text = "Could not save this selection."
	elif _stats_int("highest_run_coins") < int(mode.get("run_requirement", 0)):
		difficulty_feedback_label.text = "Reach %d coins in one run to qualify." % int(mode["run_requirement"])
	elif _stats_int("total_coins") < int(mode.get("purchase_price", 0)):
		difficulty_feedback_label.text = "Not enough lifetime coins to purchase this mode."
	elif _stats_call_bool("purchase_difficulty", difficulty_id):
		difficulty_feedback_label.text = "%s purchased. Select it to use this mode." % mode["name"]
	else:
		difficulty_feedback_label.text = "Could not save this purchase."

	_refresh_difficulty_panel()


func _build_shop(center: CenterContainer) -> void:
	shop_panel = _make_panel(960.0)
	shop_panel.custom_minimum_size.y = 540.0
	shop_panel.visible = false
	center.add_child(shop_panel)
	var panel_margin := _make_margin(shop_panel)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 24)
	panel_margin.add_child(columns)

	var list_column := VBoxContainer.new()
	list_column.custom_minimum_size.x = 340.0
	list_column.add_theme_constant_override("separation", 10)
	columns.add_child(list_column)
	list_column.add_child(_make_label("SKIN COLLECTION", 22, ACCENT_COLOR))
	shop_balance_label = _make_label("Lifetime coins: 0", 16, MUTED_COLOR)
	list_column.add_child(shop_balance_label)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(340.0, 400.0)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_column.add_child(scroll)
	skin_list = VBoxContainer.new()
	skin_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_list.add_theme_constant_override("separation", 8)
	scroll.add_child(skin_list)

	for skin in _all_skins():
		var skin_id: String = skin["id"]
		var row := HBoxContainer.new()
		row.custom_minimum_size.y = 58.0
		row.add_theme_constant_override("separation", 8)
		skin_list.add_child(row)
		row.add_child(_make_skin_preview(skin_id, Vector2(52.0, 52.0)))
		var row_button := _make_button("", _select_skin.bind(skin_id))
		row_button.custom_minimum_size.y = 58.0
		row_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(row_button)
		skin_row_buttons[skin_id] = row_button

	var detail_column := VBoxContainer.new()
	detail_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_column.add_theme_constant_override("separation", 12)
	columns.add_child(detail_column)
	shop_selected_name = _make_label("", 28, Color.WHITE)
	detail_column.add_child(shop_selected_name)
	shop_description = _make_label("", 15, MUTED_COLOR)
	detail_column.add_child(shop_description)
	var preview_center := CenterContainer.new()
	preview_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_center.custom_minimum_size.y = 200.0
	detail_column.add_child(preview_center)
	shop_preview = _make_skin_preview(selected_skin_id, Vector2(190.0, 190.0))
	preview_center.add_child(shop_preview)
	shop_status_label = _make_label("", 16, ACCENT_COLOR)
	detail_column.add_child(shop_status_label)
	shop_feedback_label = _make_label("", 14, MUTED_COLOR)
	detail_column.add_child(shop_feedback_label)
	shop_action_button = _make_button("", _perform_skin_action, ACCENT_COLOR)
	detail_column.add_child(shop_action_button)
	detail_column.add_child(_make_button("BACK TO MENU", _show_menu))
	_refresh_shop()


func _make_skin_preview(skin_id: String, minimum_size: Vector2) -> Control:
	var preview := Control.new()
	preview.set_script(SKIN_PREVIEW_SCRIPT)
	preview.set("skin_id", skin_id)
	preview.custom_minimum_size = minimum_size
	return preview


func _show_shop() -> void:
	menu_panel.visible = false
	credits_panel.visible = false
	shop_panel.visible = true
	selected_skin_id = _stats_string("equipped_skin_id")
	shop_feedback_label.text = ""
	_refresh_shop()


func _select_skin(skin_id: String) -> void:
	selected_skin_id = skin_id
	shop_feedback_label.text = ""
	_refresh_shop()


func _refresh_shop() -> void:
	shop_balance_label.text = "Lifetime coins: %d" % _stats_int("total_coins")

	for skin in _all_skins():
		var skin_id: String = skin["id"]
		var status := _skin_status(skin_id)
		var row_button := skin_row_buttons[skin_id] as Button
		row_button.text = "%s\n%d coins  |  %s" % [skin["name"], skin["price"], status]
		row_button.add_theme_stylebox_override(
			"normal",
			_button_style(BUTTON_HOVER_COLOR if skin_id == selected_skin_id else BUTTON_COLOR)
		)

	var selected_skin := _skin_definition(selected_skin_id)
	if selected_skin.is_empty():
		return

	shop_selected_name.text = selected_skin["name"]
	shop_description.text = selected_skin["description"]
	shop_preview.set("skin_id", selected_skin_id)
	shop_preview.queue_redraw()
	var status := _skin_status(selected_skin_id)
	shop_status_label.text = "%s  |  %d coins" % [status, selected_skin["price"]]
	shop_action_button.disabled = status == "EQUIPPED"
	if status == "EQUIPPED":
		shop_action_button.text = "EQUIPPED"
	elif status == "OWNED":
		shop_action_button.text = "EQUIP"
	else:
		shop_action_button.text = "PURCHASE FOR %d COINS" % selected_skin["price"]


func _skin_status(skin_id: String) -> String:
	if _stats_string("equipped_skin_id") == skin_id:
		return "EQUIPPED"
	if _stats_call_bool("owns_skin", skin_id):
		return "OWNED"
	return "LOCKED"


func _perform_skin_action() -> void:
	var skin := _skin_definition(selected_skin_id)
	if skin.is_empty():
		return

	if _stats_call_bool("owns_skin", selected_skin_id):
		if _stats_skin_action("equip_skin", selected_skin_id):
			shop_feedback_label.text = "%s equipped. It will be used in your next game." % skin["name"]
		else:
			shop_feedback_label.text = "Could not equip this skin."
	else:
		if _stats_skin_action("purchase_skin", selected_skin_id):
			shop_feedback_label.text = "%s purchased. You can equip it now." % skin["name"]
		elif _stats_int("total_coins") < int(skin["price"]):
			shop_feedback_label.text = "Not enough lifetime coins to purchase this skin."
		else:
			shop_feedback_label.text = "Purchase could not be saved. Please try again."

	_refresh_shop()


func _quit_game() -> void:
	get_tree().quit()
