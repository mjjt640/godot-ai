class_name PressureEnemyBehaviorExecutor
extends "res://scripts/enemies/enemy_behavior_executor.gd"

const EnemyTemplateData = preload("res://resources/enemies/enemy_template_data.gd")
const PressureImpactEffect = preload("res://scripts/effects/pressure_impact_effect.gd")
const PressureWarningEffect = preload("res://scripts/effects/pressure_warning_effect.gd")

var _cooldown_remaining: float = 0.0
var _warning_remaining: float = 0.0
var _warning_position: Vector2 = Vector2.ZERO


func matches(enemy_data: Resource) -> bool:
	return enemy_data != null and int(enemy_data.get_behavior_type()) == EnemyTemplateData.BehaviorType.PRESSURE


func update(enemy, delta_to_target: Vector2, delta: float) -> void:
	super.update(enemy, delta_to_target, delta)
	if _enemy == null or _enemy.enemy_data == null:
		return

	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta
	if _warning_remaining > 0.0:
		_warning_remaining -= delta
		if _warning_remaining <= 0.0:
			_resolve_warning()
		return

	_try_start_warning(delta_to_target)


func reset() -> void:
	_cooldown_remaining = 0.0
	_warning_remaining = 0.0
	_warning_position = Vector2.ZERO
	super.reset()


func _try_start_warning(delta_to_target: Vector2) -> void:
	if _cooldown_remaining > 0.0:
		return
	if delta_to_target.length() > _enemy.enemy_data.get_pressure_range():
		return
	if not _enemy.has_clear_target_line_for_behavior(delta_to_target):
		return

	var player := _enemy.get_behavior_target() as PlayerController
	if player == null:
		return

	_warning_position = player.global_position
	_warning_remaining = _enemy.enemy_data.get_pressure_warning_duration()
	_cooldown_remaining = _enemy.enemy_data.get_pressure_interval()
	_spawn_warning()


func _resolve_warning() -> void:
	var player := _enemy.get_behavior_target() as PlayerController
	if player == null:
		return
	var delta_to_player: Vector2 = player.global_position - _enemy.global_position
	if not _enemy.has_clear_target_line_for_behavior(delta_to_player):
		return
	if player.global_position.distance_to(_warning_position) > _enemy.enemy_data.get_pressure_radius():
		return

	_spawn_impact()
	player.take_damage(_enemy.enemy_data.get_pressure_damage())
	var push_direction := player.global_position - _warning_position
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	player.apply_knockback(push_direction, _enemy.enemy_data.get_pressure_knockback())


func _spawn_warning() -> void:
	var parent := _get_effect_parent()
	if parent == null:
		return

	var effect := PressureWarningEffect.new()
	effect.global_position = _warning_position
	parent.add_child(effect)
	effect.play(_enemy.enemy_data.get_pressure_radius(), _enemy.enemy_data.get_pressure_warning_duration(), _enemy.combat_feedback)


func _spawn_impact() -> void:
	var parent := _get_effect_parent()
	if parent == null:
		return

	var effect := PressureImpactEffect.new()
	effect.global_position = _warning_position
	parent.add_child(effect)
	effect.play(_enemy.enemy_data.get_pressure_radius(), _enemy.combat_feedback)


func _get_effect_parent() -> Node:
	var parent: Node = _enemy.get_tree().current_scene
	if parent == null:
		parent = _enemy.get_parent()
	return parent
