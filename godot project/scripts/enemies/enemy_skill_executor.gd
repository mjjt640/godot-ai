class_name EnemySkillExecutor
extends RefCounted

var _enemy
var _skill: Resource


func matches(_skill_template: Resource) -> bool:
	return false


func can_start(enemy, skill_template: Resource, direction: Vector2) -> bool:
	return enemy != null and skill_template != null and direction != Vector2.ZERO and matches(skill_template)


func start(enemy, skill_template: Resource, _direction: Vector2) -> void:
	_enemy = enemy
	_skill = skill_template


func update(_delta: float) -> bool:
	return false


func finish() -> void:
	_enemy = null
	_skill = null
