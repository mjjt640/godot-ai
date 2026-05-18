class_name EnemyController
extends CharacterBody2D

signal died(experience_reward: int, death_position: Vector2)

@export var enemy_data: EnemyData

var health: float = 1.0
var _target: Node2D


func _ready() -> void:
	add_to_group("enemies")
	if enemy_data != null:
		health = enemy_data.max_health
	_find_target()


func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_find_target()
		return

	var direction := (_target.global_position - global_position).normalized()
	velocity = direction * _get_move_speed()
	move_and_slide()


func take_damage(amount: float) -> void:
	health -= amount
	if health <= 0.0:
		var reward := enemy_data.experience_reward if enemy_data != null else 1
		died.emit(reward, global_position)
		queue_free()


func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	_target = players[0] if not players.is_empty() else null


func _get_move_speed() -> float:
	return enemy_data.move_speed if enemy_data != null else 100.0
