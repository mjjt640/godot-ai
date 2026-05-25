class_name EnemyBehaviorExecutor
extends RefCounted

var _enemy


func matches(_enemy_data: Resource) -> bool:
	return false


func tick(enemy, _delta: float) -> void:
	_enemy = enemy


func update(enemy, _delta_to_target: Vector2, _delta: float) -> void:
	_enemy = enemy


func update_contact(enemy, _delta_to_target: Vector2) -> void:
	_enemy = enemy


func reset() -> void:
	_enemy = null
