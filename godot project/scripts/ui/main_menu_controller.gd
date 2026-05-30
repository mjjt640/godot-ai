class_name MainMenuController
extends Control

const GameText = preload("res://scripts/ui/game_text.gd")

@export_file("*.tscn") var game_scene_path: String = "res://scenes/main/game_root.tscn"
@export var character_data: Resource = preload("res://resources/characters/character_core_runner.tres")
@export var weapon_data: Resource = preload("res://resources/weapons/core_bolt.tres")

var _start_button: Button
var _quit_button: Button
var _pulse_time: float = 0.0
var _pilot_preview: ColorRect
var _status_strip: ColorRect
var _title_label: Label
var _subtitle_label: Label
var _tagline_label: Label
var _mission_title_label: Label
var _mission_body_label: Label
var _controls_title_label: Label
var _controls_body_label: Label
var _loadout_title_label: Label
var _character_label: Label
var _weapon_label: Label
var _module_label: Label
var _description_label: Label
var _root_margin: MarginContainer
var _layout: HBoxContainer
var _left_panel: PanelContainer
var _right_panel: PanelContainer
var _preview_frame: PanelContainer
var _preview_box: Control
var _mission_block: PanelContainer
var _controls_block: PanelContainer


func _ready() -> void:
	_build_layout()
	_refresh_text()
	_apply_responsive_layout()
	_start_button.pressed.connect(_on_start_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	_start_button.grab_focus()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _layout != null:
		_apply_responsive_layout()


func _process(delta: float) -> void:
	_pulse_time += delta
	if _pilot_preview != null:
		_pilot_preview.position.y = 14.0 + sin(_pulse_time * 2.2) * 5.0
	if _status_strip != null:
		_status_strip.modulate.a = 0.5 + sin(_pulse_time * 3.0) * 0.18


func _build_layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var background := ColorRect.new()
	background.color = Color(0.035, 0.045, 0.065, 1.0)
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)

	var grid := _make_grid_background()
	add_child(grid)

	var scanline := ColorRect.new()
	scanline.color = Color(0.0, 0.85, 0.95, 0.08)
	scanline.anchor_left = 0.0
	scanline.anchor_right = 1.0
	scanline.offset_top = 74.0
	scanline.offset_bottom = 76.0
	add_child(scanline)
	_status_strip = scanline

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 56)
	root_margin.add_theme_constant_override("margin_top", 42)
	root_margin.add_theme_constant_override("margin_right", 56)
	root_margin.add_theme_constant_override("margin_bottom", 42)
	add_child(root_margin)
	_root_margin = root_margin

	var layout := HBoxContainer.new()
	layout.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 34)
	root_margin.add_child(layout)
	_layout = layout

	var left_panel := _make_panel()
	left_panel.custom_minimum_size = Vector2(500, 0)
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(left_panel)
	_left_panel = left_panel

	var left_margin := _make_margin(34, 30, 34, 30)
	left_panel.add_child(left_margin)

	var left_stack := VBoxContainer.new()
	left_stack.add_theme_constant_override("separation", 18)
	left_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_margin.add_child(left_stack)

	var subtitle := _make_label("", 20, Color(0.47, 0.94, 1.0, 1.0))
	subtitle.name = "SubtitleLabel"
	left_stack.add_child(subtitle)
	_subtitle_label = subtitle

	var title := _make_label("", 72, Color(0.96, 0.98, 0.92, 1.0))
	title.name = "TitleLabel"
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left_stack.add_child(title)
	_title_label = title

	var tagline := _make_label("", 24, Color(0.76, 0.84, 0.86, 1.0))
	_setup_tagline(tagline)
	left_stack.add_child(tagline)
	_tagline_label = tagline

	var button_row := HBoxContainer.new()
	button_row.add_theme_constant_override("separation", 14)
	left_stack.add_child(button_row)

	_start_button = _make_button()
	_start_button.name = "StartButton"
	_start_button.custom_minimum_size = Vector2(220, 58)
	button_row.add_child(_start_button)

	_quit_button = _make_button()
	_quit_button.name = "QuitButton"
	_quit_button.custom_minimum_size = Vector2(160, 58)
	button_row.add_child(_quit_button)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(1, 26)
	left_stack.add_child(spacer)

	var mission_block := _make_info_block("MissionBlock", "", "")
	left_stack.add_child(mission_block)
	_mission_block = mission_block
	_mission_title_label = mission_block.get_node("Margin/Stack/Title")
	_mission_body_label = mission_block.get_node("Margin/Stack/Body")

	var controls_block := _make_info_block("ControlsBlock", "", "")
	left_stack.add_child(controls_block)
	_controls_block = controls_block
	_controls_title_label = controls_block.get_node("Margin/Stack/Title")
	_controls_body_label = controls_block.get_node("Margin/Stack/Body")

	var flex := Control.new()
	flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_stack.add_child(flex)

	var right_panel := _make_panel()
	right_panel.custom_minimum_size = Vector2(340, 0)
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_child(right_panel)
	_right_panel = right_panel

	var right_margin := _make_margin(26, 26, 26, 26)
	right_panel.add_child(right_margin)

	var right_stack := VBoxContainer.new()
	right_stack.add_theme_constant_override("separation", 16)
	right_stack.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_margin.add_child(right_stack)

	var loadout_title := _make_label("", 26, Color(0.96, 0.98, 0.92, 1.0))
	loadout_title.name = "LoadoutTitleLabel"
	right_stack.add_child(loadout_title)
	_loadout_title_label = loadout_title

	var preview_frame := PanelContainer.new()
	preview_frame.custom_minimum_size = Vector2(260, 250)
	preview_frame.add_theme_stylebox_override("panel", _make_style(Color(0.015, 0.025, 0.04, 0.92), Color(0.1, 0.8, 0.92, 0.45), 2, 8))
	right_stack.add_child(preview_frame)
	_preview_frame = preview_frame

	var preview_box := Control.new()
	preview_box.custom_minimum_size = Vector2(260, 250)
	preview_frame.add_child(preview_box)
	_preview_box = preview_box

	var preview_glow := ColorRect.new()
	preview_glow.color = Color(0.05, 0.75, 0.9, 0.18)
	preview_glow.anchor_left = 0.14
	preview_glow.anchor_top = 0.67
	preview_glow.anchor_right = 0.86
	preview_glow.anchor_bottom = 0.75
	preview_box.add_child(preview_glow)

	_pilot_preview = ColorRect.new()
	_pilot_preview.color = Color(0.36, 0.78, 0.68, 1.0)
	_pilot_preview.custom_minimum_size = Vector2(96, 124)
	_pilot_preview.position = Vector2(82, 44)
	_pilot_preview.size = Vector2(96, 124)
	preview_box.add_child(_pilot_preview)

	var loadout_box := VBoxContainer.new()
	loadout_box.name = "LoadoutBox"
	loadout_box.add_theme_constant_override("separation", 10)
	right_stack.add_child(loadout_box)

	for label_name in ["CharacterLabel", "WeaponLabel", "ModuleLabel", "DescriptionLabel"]:
		var label := _make_label("", 18, Color(0.78, 0.86, 0.84, 1.0))
		label.name = label_name
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		loadout_box.add_child(label)
		match label_name:
			"CharacterLabel":
				_character_label = label
			"WeaponLabel":
				_weapon_label = label
			"ModuleLabel":
				_module_label = label
			"DescriptionLabel":
				_description_label = label

	var right_flex := Control.new()
	right_flex.size_flags_vertical = Control.SIZE_EXPAND_FILL
	right_stack.add_child(right_flex)

	var footer := _make_label("v0.1", 15, Color(0.46, 0.58, 0.6, 1.0))
	footer.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	right_stack.add_child(footer)


func _apply_responsive_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.x < 1040.0 or viewport_size.y < 680.0
	var cramped := viewport_size.x < 860.0 or viewport_size.y < 560.0

	_set_margin(_root_margin, 24, 22, 24, 22) if compact else _set_margin(_root_margin, 56, 42, 56, 42)
	_layout.add_theme_constant_override("separation", 18 if compact else 34)
	_left_panel.custom_minimum_size = Vector2(0 if compact else 500, 0)
	_right_panel.visible = not cramped
	_right_panel.custom_minimum_size = Vector2(300 if compact else 340, 0)

	_set_label_size(_subtitle_label, 16 if compact else 20)
	_set_label_size(_title_label, 46 if compact else 72)
	_set_label_size(_tagline_label, 18 if compact else 24)
	_set_label_size(_mission_title_label, 15 if compact else 18)
	_set_label_size(_mission_body_label, 15 if compact else 18)
	_set_label_size(_controls_title_label, 15 if compact else 18)
	_set_label_size(_controls_body_label, 15 if compact else 18)
	_set_label_size(_loadout_title_label, 22 if compact else 26)
	for label in [_character_label, _weapon_label, _module_label, _description_label]:
		_set_label_size(label, 15 if compact else 18)

	_start_button.custom_minimum_size = Vector2(180 if compact else 220, 48 if compact else 58)
	_quit_button.custom_minimum_size = Vector2(128 if compact else 160, 48 if compact else 58)
	_start_button.add_theme_font_size_override("font_size", 18 if compact else 22)
	_quit_button.add_theme_font_size_override("font_size", 18 if compact else 22)
	_preview_frame.custom_minimum_size = Vector2(220 if compact else 260, 190 if compact else 250)
	_preview_box.custom_minimum_size = _preview_frame.custom_minimum_size
	_tagline_label.visible = not cramped
	_controls_block.visible = viewport_size.y >= 620.0


func _set_margin(margin: MarginContainer, left: int, top: int, right: int, bottom: int) -> void:
	if margin == null:
		return
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)


func _set_label_size(label: Label, font_size: int) -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", font_size)


func _setup_tagline(label: Label) -> void:
	label.name = "TaglineLabel"
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART


func _refresh_text() -> void:
	_title_label.text = GameText.main_menu_title()
	_subtitle_label.text = GameText.main_menu_subtitle()
	_tagline_label.text = GameText.main_menu_tagline()
	_mission_title_label.text = GameText.main_menu_mission_title()
	_mission_body_label.text = GameText.main_menu_mission_body()
	_controls_title_label.text = GameText.main_menu_controls_title()
	_controls_body_label.text = GameText.main_menu_controls_body()
	_loadout_title_label.text = GameText.main_menu_loadout_title()
	_character_label.text = GameText.main_menu_character(character_data)
	_weapon_label.text = GameText.main_menu_weapon(weapon_data)
	var fire_module: ModuleData
	var payload_module: ModuleData
	if character_data != null:
		fire_module = character_data.get("starting_fire_module") as ModuleData
		payload_module = character_data.get("starting_payload_module") as ModuleData
	_module_label.text = GameText.main_menu_module_pair(fire_module, payload_module)
	_description_label.text = GameText.main_menu_description(character_data)
	_start_button.text = GameText.main_menu_start()
	_quit_button.text = GameText.main_menu_quit()


func _on_start_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(game_scene_path)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _make_grid_background() -> Control:
	var grid := GridContainer.new()
	grid.columns = 18
	grid.set_anchors_preset(Control.PRESET_FULL_RECT)
	grid.modulate = Color(1.0, 1.0, 1.0, 0.34)
	for index in range(180):
		var cell := ColorRect.new()
		cell.custom_minimum_size = Vector2(84, 44)
		if index % 7 == 0:
			cell.color = Color(0.02, 0.32, 0.38, 0.18)
		elif index % 11 == 0:
			cell.color = Color(0.74, 0.16, 0.28, 0.12)
		else:
			cell.color = Color(0.08, 0.11, 0.14, 0.18)
		grid.add_child(cell)
	return grid


func _make_info_block(block_name: String, title_text: String, body_text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = block_name
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.02, 0.035, 0.052, 0.82), Color(0.18, 0.48, 0.56, 0.5), 1, 6))

	var margin := _make_margin(16, 14, 16, 14)
	margin.name = "Margin"
	panel.add_child(margin)

	var stack := VBoxContainer.new()
	stack.name = "Stack"
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)

	var title := _make_label(title_text, 18, Color(0.47, 0.94, 1.0, 1.0))
	title.name = "Title"
	stack.add_child(title)

	var body := _make_label(body_text, 18, Color(0.84, 0.89, 0.86, 1.0))
	body.name = "Body"
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(body)
	return panel


func _make_panel() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _make_style(Color(0.025, 0.035, 0.052, 0.94), Color(0.12, 0.78, 0.9, 0.55), 2, 8))
	return panel


func _make_margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	return margin


func _make_label(text_value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	return label


func _make_button() -> Button:
	var button := Button.new()
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_stylebox_override("normal", _make_style(Color(0.04, 0.13, 0.16, 0.95), Color(0.13, 0.72, 0.82, 0.9), 2, 6))
	button.add_theme_stylebox_override("hover", _make_style(Color(0.07, 0.26, 0.29, 1.0), Color(0.48, 0.94, 1.0, 1.0), 2, 6))
	button.add_theme_stylebox_override("pressed", _make_style(Color(0.74, 0.16, 0.28, 0.95), Color(0.98, 0.58, 0.66, 1.0), 2, 6))
	button.add_theme_stylebox_override("focus", _make_style(Color(0.07, 0.22, 0.25, 0.7), Color(0.92, 0.96, 0.62, 1.0), 2, 6))
	button.add_theme_color_override("font_color", Color(0.94, 0.98, 0.94, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 0.86, 1.0))
	return button


func _make_style(bg: Color, border: Color, border_width: int, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_right = radius
	style.corner_radius_bottom_left = radius
	return style
