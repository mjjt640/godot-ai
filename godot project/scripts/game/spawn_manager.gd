class_name SpawnManager
extends Node

signal enemy_spawned(enemy: EnemyController)

@export var player_path: NodePath = ^"../Player"
@export var spawn_interval: float = 1.25
@export var spawn_radius: float = 620.0
@export var enemy_scenes: Array[PackedScene] = [
	preload("res://scenes/enemies/enemy_basic.tscn"),
	preload("res://scenes/enemies/enemy_fast.tscn"),
	preload("res://scenes/enemies/enemy_tank.tscn"),
]

var _elapsed: float = 0.0
@onready var _player: Node2D = get_node_or_null(player_path)


func _physics_process(delta: float) -> void:
	if _player == null or enemy_scenes.is_empty():
		return

	_elapsed += delta
	if _elapsed >= spawn_interval:
		_elapsed = 0.0
		spawn_enemy()


func spawn_enemy() -> void:
	var scene: PackedScene = enemy_scenes.pick_random()
	var enemy: EnemyController = scene.instantiate() as EnemyController
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = _player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * spawn_radius
	enemy_spawned.emit(enemy)
