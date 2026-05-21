class_name HUDController
extends CanvasLayer

const GameText = preload("res://scripts/ui/game_text.gd")

@onready var _xp_label: Label = %XpLabel
@onready var _level_label: Label = %LevelLabel
@onready var _character_label: Label = %CharacterLabel
@onready var _health_label: Label = %HealthLabel
@onready var _health_bar: ProgressBar = %HealthBar
@onready var _fire_mode_label: Label = %FireModeLabel
@onready var _payload_label: Label = %PayloadLabel
@onready var _game_over_panel: Control = %GameOverPanel
@onready var _game_over_label: Label = %GameOverLabel

var _build_state: BuildState
var _xp_manager: XPManager
var _player: PlayerController


func bind(build_state: BuildState, xp_manager: XPManager, player: PlayerController) -> void:
	_build_state = build_state
	_xp_manager = xp_manager
	_player = player

	if _build_state != null:
		_build_state.modules_changed.connect(_on_modules_changed)
		_on_modules_changed(_build_state.modules_by_slot)
	if _xp_manager != null:
		_xp_manager.xp_changed.connect(_on_xp_changed)
		_on_xp_changed(_xp_manager.current_xp, _xp_manager.get_required_xp(), _xp_manager.level)
	if _player != null:
		_player.health_changed.connect(_on_health_changed)
		_player.died.connect(_on_player_died)
		_on_health_changed(_player.health, _player.max_health)
		_character_label.text = GameText.hud_character(_player.character_data)


func _on_modules_changed(modules_by_slot: Dictionary) -> void:
	var fire_mode: ModuleData = modules_by_slot.get(ModuleData.SLOT_FIRE_MODE)
	var payload: ModuleData = modules_by_slot.get(ModuleData.SLOT_PAYLOAD)
	_fire_mode_label.text = GameText.hud_fire_mode(fire_mode)
	_payload_label.text = GameText.hud_payload(payload)


func _on_xp_changed(current_xp: int, required_xp: int, level: int) -> void:
	_level_label.text = GameText.hud_level(level)
	_xp_label.text = GameText.hud_xp(current_xp, required_xp)


func _on_health_changed(current_health: float, max_health: float) -> void:
	_health_label.text = GameText.hud_health(current_health, max_health)
	_health_bar.max_value = max_health
	_health_bar.value = clampf(current_health, 0.0, max_health)


func _on_player_died() -> void:
	show_game_over()


func show_game_over() -> void:
	_game_over_panel.visible = true
	_game_over_label.text = GameText.game_over()


func show_victory() -> void:
	_game_over_panel.visible = true
	_game_over_label.text = GameText.victory()
