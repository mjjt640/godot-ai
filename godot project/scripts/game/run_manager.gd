class_name RunManager
extends Node2D

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
var _camera: Camera2D
var _run_time: float = 0.0
var _triggered_objective_events: Dictionary = {}
var _run_finished: bool = false


func _physics_process(delta: float) -> void:
	if _run_finished:
		return

	_run_time += delta
	if _hud != null:
		_hud.update_run_status(_run_time, run_objective)
	_update_objective_events()


func _ready() -> void:
	if _spawn_manager != null:
		_spawn_manager.run_tuning = run_tuning
		_spawn_manager.enemy_spawned.connect(_on_enemy_spawned)
	if _arena_bounds != null:
		_arena_bounds.call("configure", run_tuning)
	if _arena_visual != null:
		_arena_visual.call("configure", run_tuning)
	if _xp_manager != null:
		_xp_manager.level_up_requested.connect(_on_level_up_requested)
	if _level_up_panel != null:
		_level_up_panel.upgrade_selected.connect(_on_upgrade_selected)
		_level_up_panel.hide_options()
	if _player != null:
		_player.died.connect(_on_player_died)
		_camera = _player.get_node_or_null("Camera2D") as Camera2D
	if _build_state != null and _player != null:
		_build_state.configure_from_character(_player.character_data)
	if _hud != null:
		_hud.bind(_build_state, _xp_manager, _player)
		_hud.update_run_status(_run_time, run_objective)


func _on_enemy_spawned(enemy: EnemyController) -> void:
	enemy.combat_feedback = combat_feedback
	enemy.died.connect(_on_enemy_died)


func _on_enemy_died(experience_reward: int, _death_position: Vector2) -> void:
	_spawn_xp_pickup(experience_reward, _death_position)
	_play_camera_shake()


func _on_objective_enemy_died(enemy: EnemyController) -> void:
	if enemy == null or enemy.enemy_data == null:
		return
	if enemy.enemy_data.is_boss:
		_finish_run(true)


func _on_level_up_requested() -> void:
	if _level_up_panel == null or _upgrade_manager == null:
		return

	get_tree().paused = true
	_level_up_panel.show_options(_upgrade_manager.request_options(), _upgrade_manager.get_module_limit())


func _on_upgrade_selected(option: UpgradeOptionData) -> void:
	if _upgrade_manager != null:
		_upgrade_manager.apply_upgrade(option)
	if _xp_manager != null:
		_xp_manager.confirm_level_up()

	if _level_up_panel != null:
		_level_up_panel.hide_options()
	get_tree().paused = false


func _on_player_died() -> void:
	if _level_up_panel != null:
		_level_up_panel.hide_options()
	_finish_run(false)


func _update_objective_events() -> void:
	if run_objective == null or _spawn_manager == null:
		return

	var events: Array = run_objective.get("events")
	for event in events:
		if event == null or _triggered_objective_events.has(event.get("id")):
			continue
		if _run_time < float(event.get("trigger_time")):
			continue
		_triggered_objective_events[event.get("id")] = true
		_spawn_objective_event(event)


func _spawn_objective_event(event: Resource) -> void:
	var enemy_scene := event.get("enemy_scene") as PackedScene
	if enemy_scene == null:
		return

	var spawn_count: int = max(int(event.get("spawn_count")), 1)
	for _index in range(spawn_count):
		var enemy := _spawn_manager.spawn_enemy_scene(enemy_scene)
		if enemy != null:
			if enemy.enemy_data != null and enemy.enemy_data.get_is_boss() and _hud != null:
				_hud.track_boss(enemy)
			enemy.died.connect(func(_experience_reward: int, _death_position: Vector2) -> void: _on_objective_enemy_died(enemy))


func _finish_run(victory: bool) -> void:
	if _run_finished:
		return

	_run_finished = true
	if _level_up_panel != null:
		_level_up_panel.hide_options()
	if _hud != null:
		if victory:
			_hud.show_victory()
		else:
			_hud.show_game_over()
	get_tree().paused = true


func _spawn_xp_pickup(amount: int, drop_position: Vector2) -> void:
	if xp_pickup_scene == null or _xp_manager == null:
		return

	var pickup := xp_pickup_scene.instantiate() as XPPickupController
	if pickup == null:
		return

	pickup.global_position = drop_position
	pickup.amount = amount
	pickup.configure_from_tuning(run_tuning)

	var container := _pickup_container if _pickup_container != null else get_tree().current_scene
	container.add_child(pickup)
	pickup.scatter(combat_feedback)
	pickup.collected.connect(_on_xp_pickup_collected)


func _on_xp_pickup_collected(amount: int) -> void:
	if _xp_manager != null:
		_xp_manager.gain_experience(amount)


func _play_camera_shake() -> void:
	if _camera == null or combat_feedback == null:
		return

	var original_offset := _camera.offset
	var shake_strength := float(combat_feedback.get("camera_shake_strength"))
	var shake_duration := float(combat_feedback.get("camera_shake_duration"))
	var tween := create_tween()
	tween.tween_property(_camera, "offset", Vector2(randf_range(-shake_strength, shake_strength), randf_range(-shake_strength, shake_strength)), shake_duration * 0.5)
	tween.tween_property(_camera, "offset", original_offset, shake_duration * 0.5)
