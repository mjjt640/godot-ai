class_name RunManager
extends Node2D

@export var spawn_manager_path: NodePath = ^"SpawnManager"
@export var xp_manager_path: NodePath = ^"XPManager"
@export var upgrade_manager_path: NodePath = ^"UpgradeManager"
@export var level_up_panel_path: NodePath = ^"LevelUpPanel"
@export var hud_path: NodePath = ^"HUD"
@export var build_state_path: NodePath = ^"BuildState"

@onready var _spawn_manager: SpawnManager = get_node_or_null(spawn_manager_path)
@onready var _xp_manager: XPManager = get_node_or_null(xp_manager_path)
@onready var _upgrade_manager: UpgradeManager = get_node_or_null(upgrade_manager_path)
@onready var _level_up_panel: LevelUpPanelController = get_node_or_null(level_up_panel_path)
@onready var _hud: HUDController = get_node_or_null(hud_path)
@onready var _build_state: BuildState = get_node_or_null(build_state_path)


func _ready() -> void:
	if _spawn_manager != null:
		_spawn_manager.enemy_spawned.connect(_on_enemy_spawned)
	if _xp_manager != null:
		_xp_manager.level_up_requested.connect(_on_level_up_requested)
	if _level_up_panel != null:
		_level_up_panel.upgrade_selected.connect(_on_upgrade_selected)
		_level_up_panel.hide_options()
	if _hud != null:
		_hud.bind(_build_state, _xp_manager)


func _on_enemy_spawned(enemy: EnemyController) -> void:
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(experience_reward: int, _death_position: Vector2) -> void:
	if _xp_manager != null:
		_xp_manager.gain_experience(experience_reward)


func _on_level_up_requested() -> void:
	if _level_up_panel == null or _upgrade_manager == null:
		return

	get_tree().paused = true
	_level_up_panel.show_options(_upgrade_manager.request_options())


func _on_upgrade_selected(option: UpgradeOptionData) -> void:
	if _upgrade_manager != null:
		_upgrade_manager.apply_upgrade(option)
	if _xp_manager != null:
		_xp_manager.confirm_level_up()

	if _level_up_panel != null:
		_level_up_panel.hide_options()
	get_tree().paused = false
