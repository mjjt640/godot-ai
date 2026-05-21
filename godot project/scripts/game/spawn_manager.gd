class_name SpawnManager
extends Node

signal enemy_spawned(enemy: EnemyController)

@export var player_path: NodePath = ^"../Player"
@export var run_tuning: RunTuningData = preload("res://resources/runs/default_run_tuning.tres")
@export var wave_table: Resource = preload("res://resources/waves/default_wave_table.tres")

var _elapsed: float = 0.0
var _run_time: float = 0.0
@onready var _player: Node2D = get_node_or_null(player_path)


func _physics_process(delta: float) -> void:
	if _player == null or run_tuning == null:
		return

	_run_time += delta
	_elapsed += delta
	var wave_entry: Resource = _get_wave_entry()
	if _elapsed < _get_spawn_interval(wave_entry):
		return

	_elapsed = 0.0
	var alive_enemies: int = get_tree().get_nodes_in_group("enemies").size()
	var max_alive_enemies := _get_max_alive_enemies(wave_entry)
	if alive_enemies >= max_alive_enemies:
		return

	var spawn_count: int = min(_get_spawn_batch_size(wave_entry), max_alive_enemies - alive_enemies)
	for _index in range(spawn_count):
		spawn_enemy(wave_entry)


func spawn_enemy(wave_entry: Resource = null) -> void:
	var scenes := _get_enemy_scenes(wave_entry)
	if scenes.is_empty():
		return

	var scene: PackedScene = scenes.pick_random()
	spawn_enemy_scene(scene)


func spawn_enemy_scene(scene: PackedScene) -> EnemyController:
	if scene == null:
		return null

	var enemy: EnemyController = scene.instantiate() as EnemyController
	if enemy == null:
		return null

	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _get_spawn_position()
	enemy_spawned.emit(enemy)
	return enemy


func _get_spawn_position() -> Vector2:
	var min_position := -run_tuning.arena_half_extents + Vector2.ONE * run_tuning.enemy_spawn_margin
	var max_position := run_tuning.arena_half_extents - Vector2.ONE * run_tuning.enemy_spawn_margin
	var minimum_distance: float = min(run_tuning.minimum_spawn_distance, run_tuning.spawn_radius)
	for _attempt in range(12):
		var desired_position := _player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * run_tuning.spawn_radius
		var spawn_position := desired_position.clamp(min_position, max_position)
		if spawn_position.distance_to(_player.global_position) >= minimum_distance:
			return spawn_position

	var fallback_direction := (_player.global_position.direction_to(Vector2.ZERO))
	if fallback_direction.is_zero_approx():
		fallback_direction = Vector2.RIGHT
	return (_player.global_position + fallback_direction * minimum_distance).clamp(min_position, max_position)


func _get_wave_entry() -> Resource:
	if wave_table == null:
		return null
	return wave_table.call("get_entry", _run_time)


func _get_spawn_interval(wave_entry: Resource) -> float:
	return float(wave_entry.get("spawn_interval")) if wave_entry != null else run_tuning.spawn_interval


func _get_spawn_batch_size(wave_entry: Resource) -> int:
	return int(wave_entry.get("spawn_batch_size")) if wave_entry != null else run_tuning.spawn_batch_size


func _get_max_alive_enemies(wave_entry: Resource) -> int:
	return int(wave_entry.get("max_alive_enemies")) if wave_entry != null else run_tuning.max_alive_enemies


func _get_enemy_scenes(wave_entry: Resource) -> Array[PackedScene]:
	if wave_entry != null:
		var scenes: Array[PackedScene] = wave_entry.get("enemy_scenes")
		return scenes
	return []
