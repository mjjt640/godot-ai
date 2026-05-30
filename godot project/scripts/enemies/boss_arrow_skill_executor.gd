class_name BossArrowSkillExecutor
extends "res://scripts/enemies/enemy_skill_executor.gd"

const ArrowEnemySkillDataScript = preload("res://resources/enemies/skills/arrow_enemy_skill_data.gd")
const BossArrowRainEffect = preload("res://scripts/effects/boss_arrow_rain_effect.gd")
const BossArrowShotEffect = preload("res://scripts/effects/boss_arrow_shot_effect.gd")
const BossDashWarningEffect = preload("res://scripts/effects/boss_dash_warning_effect.gd")

const ATTACK_MODE_SHOT := 0
const ATTACK_MODE_RAIN := 1

var _direction: Vector2 = Vector2.ZERO
var _target_position: Vector2 = Vector2.ZERO


func matches(skill_template: Resource) -> bool:
	return skill_template != null and skill_template.get_script() == ArrowEnemySkillDataScript


func can_start(enemy, skill_template: Resource, direction: Vector2) -> bool:
	if not super.can_start(enemy, skill_template, direction):
		return false
	if not bool(skill_template.get("requires_line_of_sight")):
		return true

	var target: Node2D = enemy.get_skill_target() as Node2D
	if target == null:
		return false

	var target_distance: float = enemy.global_position.distance_to(target.global_position)
	var clearance: float = _get_arrow_clearance(enemy, direction.normalized(), target_distance)
	return clearance >= maxf(target_distance - float(enemy.get_body_probe_radius()), 0.0)


func start(enemy, skill_template: Resource, direction: Vector2) -> void:
	super.start(enemy, skill_template, direction)
	_direction = direction.normalized()
	var target: Node2D = _enemy.get_skill_target() as Node2D
	_target_position = target.global_position if target != null else _enemy.global_position + _direction * float(_skill.get("warning_length"))
	if _enemy.has_method("face_skill_direction"):
		_enemy.call("face_skill_direction", _direction)
	_spawn_warning()
	_enemy.begin_boss_windup(float(_skill.get("windup_duration")))


func update(delta: float) -> bool:
	if _enemy == null or _skill == null:
		return false

	if _enemy.is_in_skill_dash():
		_enemy.move_skill_idle(delta)
		if _enemy.advance_skill_state(delta):
			_begin_recover()
		return true

	_enemy.move_skill_idle(delta)
	if not _enemy.advance_skill_state(delta):
		return true

	if _enemy.is_in_skill_windup():
		_begin_release()
		return true
	if _enemy.is_in_skill_recover():
		return false
	return true


func finish() -> void:
	_direction = Vector2.ZERO
	super.finish()


func _begin_release() -> void:
	_enemy.begin_boss_dash(_direction, 0.0, float(_skill.get("release_duration")))
	if int(_skill.get("attack_mode")) == ATTACK_MODE_SHOT:
		_spawn_arrow_shot()


func _begin_recover() -> void:
	_enemy.begin_boss_recover(maxf(float(_skill.get("recover_duration")), 0.0))


func _spawn_warning() -> void:
	if int(_skill.get("attack_mode")) == ATTACK_MODE_RAIN:
		_spawn_arrow_rain()
		return

	var parent: Node = _effect_parent()
	if parent == null:
		return

	var effect := BossDashWarningEffect.new()
	effect.global_position = _enemy.global_position
	effect.rotation = _direction.angle()
	parent.add_child(effect)
	effect.play(_skill)


func _spawn_arrow_shot() -> void:
	var target: PlayerController = _enemy.get_skill_target() as PlayerController
	if target == null:
		return

	var parent: Node = _effect_parent()
	if parent == null:
		return

	var spawn_offset: float = float(_enemy.get_body_probe_radius()) + maxf(float(_skill.get("projectile_spawn_offset")), 0.0)
	var origin: Vector2 = _enemy.global_position + _direction * spawn_offset
	var warning_length: float = maxf(float(_skill.get("warning_length")), 1.0)
	var clearance: float = _get_arrow_clearance(_enemy, _direction, warning_length)
	var max_travel: float = maxf(clearance - spawn_offset, 1.0)
	var target_travel: float = origin.distance_to(target.global_position) + maxf(float(_skill.get("projectile_hit_radius")), 1.0)
	var travel_distance: float = minf(max_travel, target_travel)

	var effect := BossArrowShotEffect.new()
	parent.add_child(effect)
	effect.play(
		origin,
		_direction,
		travel_distance,
		float(_skill.get("projectile_speed")),
		float(_skill.get("damage")),
		float(_skill.get("knockback")),
		float(_skill.get("projectile_hit_radius")),
		target,
		String(_skill.get("shot_effect_path")),
		float(_skill.get("shot_effect_fps")),
		float(_skill.get("shot_effect_scale")),
		String(_skill.get("impact_effect_path")),
		float(_skill.get("impact_effect_fps")),
		float(_skill.get("impact_effect_scale"))
	)


func _spawn_arrow_rain() -> void:
	var target: PlayerController = _enemy.get_skill_target() as PlayerController
	if target == null:
		return

	var parent: Node = _effect_parent()
	if parent == null:
		return

	var effect := BossArrowRainEffect.new()
	parent.add_child(effect)
	effect.play(
		_target_position,
		target,
		float(_skill.get("rain_radius")),
		float(_skill.get("windup_duration")),
		float(_skill.get("release_duration")),
		float(_skill.get("damage")),
		float(_skill.get("knockback")),
		String(_skill.get("rain_target_effect_path")),
		float(_skill.get("rain_target_effect_fps")),
		float(_skill.get("rain_target_effect_scale")),
		String(_skill.get("rain_effect_path")),
		float(_skill.get("rain_effect_fps")),
		float(_skill.get("rain_effect_scale")),
		_enemy.get("combat_feedback") as Resource
	)


func _effect_parent() -> Node:
	var parent: Node = _enemy.get_tree().current_scene
	if parent == null:
		parent = _enemy.get_parent()
	return parent


func _get_arrow_clearance(enemy, direction: Vector2, distance: float) -> float:
	if enemy != null and enemy.has_method("get_center_world_clearance_for_skill"):
		return float(enemy.call("get_center_world_clearance_for_skill", direction, distance))
	return float(enemy.get_world_clearance_for_skill(direction, distance))
