class_name RunManager
extends Node2D

const RunObjectiveControllerScript = preload("res://scripts/run/run_objective_controller.gd")
const RunLevelFlowControllerScript = preload("res://scripts/run/run_level_flow_controller.gd")
const RunCombatRewardControllerScript = preload("res://scripts/run/run_combat_reward_controller.gd")

@export var spawn_manager_path: NodePath = ^"SpawnManager"
@export var xp_manager_path: NodePath = ^"XPManager"
@export var upgrade_manager_path: NodePath = ^"UpgradeManager"
@export var level_up_panel_path: NodePath = ^"LevelUpPanel"
@export var hud_path: NodePath = ^"HUD"
@export var arena_visual_path: NodePath = ^"ArenaVisual"
@export var arena_bounds_path: NodePath = ^"ArenaBounds"
@export var build_state_path: NodePath = ^"BuildState"
@export var player_path: NodePath = ^"Player"
@export var pickup_container_path: NodePath = ^"Pickups"
@export var map_data: Resource = preload("res://resources/maps/default_map.tres")
@export var run_tuning: RunTuningData = preload("res://resources/runs/default_run_tuning.tres")
@export var run_objective: Resource = preload("res://resources/runs/default_run_objective.tres")
@export var combat_feedback: Resource = preload("res://resources/combat/default_combat_feedback.tres")
@export var xp_pickup_scene: PackedScene = preload("res://scenes/pickups/xp_pickup.tscn")

@onready var _spawn_manager: SpawnManager = get_node_or_null(spawn_manager_path)
@onready var _xp_manager: XPManager = get_node_or_null(xp_manager_path)
@onready var _upgrade_manager: UpgradeManager = get_node_or_null(upgrade_manager_path)
@onready var _level_up_panel: LevelUpPanelController = get_node_or_null(level_up_panel_path)
@onready var _hud: HUDController = get_node_or_null(hud_path)
@onready var _arena_visual: Node = get_node_or_null(arena_visual_path)
@onready var _arena_bounds: Node = get_node_or_null(arena_bounds_path)
@onready var _build_state: BuildState = get_node_or_null(build_state_path)
@onready var _player: PlayerController = get_node_or_null(player_path)
@onready var _pickup_container: Node2D = get_node_or_null(pickup_container_path)
var _run_time: float = 0.0
var _run_finished: bool = false
var _objective_controller
var _level_flow_controller
var _combat_reward_controller


func _physics_process(delta: float) -> void:
	if _run_finished:
		return

	_run_time += delta
	if _hud != null:
		_hud.update_run_status(_run_time, run_objective)
	_process_objective_events()


func _ready() -> void:
	_objective_controller = RunObjectiveControllerScript.new()
	_level_flow_controller = RunLevelFlowControllerScript.new()
	_combat_reward_controller = RunCombatRewardControllerScript.new()
	_objective_controller.reset()
	_apply_map_data()
	if _spawn_manager != null:
		_spawn_manager.run_tuning = run_tuning
		_spawn_manager.enemy_spawned.connect(_on_enemy_spawned)
	if _arena_bounds != null:
		_arena_bounds.call("configure", run_tuning)
	if _arena_visual != null:
		_arena_visual.call("configure", run_tuning, map_data.get("visual_data"), map_data.get("tile_library"), map_data.get("tile_layout"))
	if _xp_manager != null:
		_xp_manager.level_up_requested.connect(_on_level_up_requested)
	if _level_up_panel != null:
		_level_up_panel.upgrade_selected.connect(_on_upgrade_selected)
		_level_flow_controller.initialize(_level_up_panel)
	if _player != null:
		_player.died.connect(_on_player_died)
	if _build_state != null and _player != null:
		_build_state.configure_from_character(_player.character_data)
	_combat_reward_controller.configure(_xp_manager, xp_pickup_scene, _pickup_container, run_tuning, combat_feedback, get_tree())
	if _hud != null:
		_hud.bind(_build_state, _xp_manager, _player)
		_hud.update_run_status(_run_time, run_objective)


func _apply_map_data() -> void:
	if map_data == null:
		return

	var map_run_tuning := map_data.get("run_tuning") as RunTuningData
	if map_run_tuning != null:
		run_tuning = map_run_tuning


func _on_enemy_spawned(enemy: EnemyController) -> void:
	enemy.combat_feedback = combat_feedback
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(experience_reward: int, _death_position: Vector2) -> void:
	_combat_reward_controller.handle_enemy_died(experience_reward, _death_position)


func _on_objective_enemy_died(enemy: EnemyController) -> void:
	if _objective_controller.is_victory_enemy(enemy):
		_finish_run(true)


func _on_level_up_requested() -> void:
	_level_flow_controller.handle_level_up_requested(get_tree(), _level_up_panel, _upgrade_manager)


func _on_upgrade_selected(option: UpgradeOptionData) -> void:
	_level_flow_controller.handle_upgrade_selected(get_tree(), _level_up_panel, _upgrade_manager, _xp_manager, option)


func _on_player_died() -> void:
	_level_flow_controller.prepare_run_finish(_level_up_panel)
	_finish_run(false)


func _process_objective_events() -> void:
	if _spawn_manager == null:
		return

	for event in _objective_controller.collect_ready_events(run_objective, _run_time):
		_spawn_objective_event(event)


func _spawn_objective_event(event: Resource) -> void:
	var enemy_scene := event.get("enemy_scene") as PackedScene
	if enemy_scene == null:
		return

	var spawn_count: int = max(int(event.get("spawn_count")), 1)
	for _index in range(spawn_count):
		var enemy := _spawn_manager.spawn_enemy_scene(enemy_scene)
		if enemy != null:
			if _objective_controller.register_spawned_objective_enemy(enemy) and _hud != null:
				_hud.track_boss(enemy)
			enemy.died.connect(func(_experience_reward: int, _death_position: Vector2) -> void: _on_objective_enemy_died(enemy))


func _finish_run(victory: bool) -> void:
	if _run_finished:
		return

	_run_finished = true
	_level_flow_controller.prepare_run_finish(_level_up_panel)
	if _hud != null:
		if victory:
			_hud.show_victory()
		else:
			_hud.show_game_over()
	get_tree().paused = true
