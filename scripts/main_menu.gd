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
var menu_total_coins_value: Label
var menu_best_score_value: Label
var difficulty_notice: Label
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


func _ready() -> void:
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
	menu_total_coins_value = _make_label(str(PlayerStats.total_coins), 28, Color.WHITE)
	menu_best_score_value = _make_label(str(PlayerStats.best_score), 28, Color.WHITE)
	stats_row.add_child(_make_stat_card("LIFETIME COINS", menu_total_coins_value))
	stats_row.add_child(_make_stat_card("BEST SCORE", menu_best_score_value))

	difficulty_notice = _make_label("Difficulty selection is coming soon.", 14, MUTED_COLOR)
	difficulty_notice.visible = false
	menu_layout.add_child(difficulty_notice)

	menu_layout.add_child(_make_button("START", _start_game, ACCENT_COLOR))
	menu_layout.add_child(_make_button("DIFFICULTY MODE  -  COMING SOON", _show_difficulty_notice))
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


func _show_difficulty_notice() -> void:
	difficulty_notice.visible = true


func _show_credits() -> void:
	menu_panel.visible = false
	shop_panel.visible = false
	credits_panel.visible = true


func _show_menu() -> void:
	credits_panel.visible = false
	shop_panel.visible = false
	menu_panel.visible = true
	menu_total_coins_value.text = str(PlayerStats.total_coins)
	menu_best_score_value.text = str(PlayerStats.best_score)


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

	for skin in SkinCatalog.get_all_skins():
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
	selected_skin_id = PlayerStats.equipped_skin_id
	shop_feedback_label.text = ""
	_refresh_shop()


func _select_skin(skin_id: String) -> void:
	selected_skin_id = skin_id
	shop_feedback_label.text = ""
	_refresh_shop()


func _refresh_shop() -> void:
	shop_balance_label.text = "Lifetime coins: %d" % PlayerStats.total_coins

	for skin in SkinCatalog.get_all_skins():
		var skin_id: String = skin["id"]
		var status := _skin_status(skin_id)
		var row_button := skin_row_buttons[skin_id] as Button
		row_button.text = "%s\n%d coins  |  %s" % [skin["name"], skin["price"], status]
		row_button.add_theme_stylebox_override(
			"normal",
			_button_style(BUTTON_HOVER_COLOR if skin_id == selected_skin_id else BUTTON_COLOR)
		)

	var selected_skin := SkinCatalog.get_skin(selected_skin_id)
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
	if PlayerStats.equipped_skin_id == skin_id:
		return "EQUIPPED"
	if PlayerStats.owns_skin(skin_id):
		return "OWNED"
	return "LOCKED"


func _perform_skin_action() -> void:
	var skin := SkinCatalog.get_skin(selected_skin_id)
	if skin.is_empty():
		return

	if PlayerStats.owns_skin(selected_skin_id):
		if PlayerStats.equip_skin(selected_skin_id):
			shop_feedback_label.text = "%s equipped. It will be used in your next game." % skin["name"]
		else:
			shop_feedback_label.text = "Could not equip this skin."
	else:
		if PlayerStats.purchase_skin(selected_skin_id):
			shop_feedback_label.text = "%s purchased. You can equip it now." % skin["name"]
		elif PlayerStats.total_coins < int(skin["price"]):
			shop_feedback_label.text = "Not enough lifetime coins to purchase this skin."
		else:
			shop_feedback_label.text = "Purchase could not be saved. Please try again."

	_refresh_shop()


func _quit_game() -> void:
	get_tree().quit()
