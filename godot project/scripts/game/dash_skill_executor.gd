class_name DashSkillExecutor
extends "res://scripts/game/enemy_skill_executor.gd"

const DashEnemySkillDataScript = preload("res://resources/enemies/skills/dash_enemy_skill_data.gd")
const BossDashWarningEffect = preload("res://scripts/effects/boss_dash_warning_effect.gd")

var _direction: Vector2 = Vector2.ZERO
var _hit_targets: Array[Node] = []


func matches(skill_template: Resource) -> bool:
	return skill_template != null and skill_template.get_script() == DashEnemySkillDataScript


func can_start(enemy, skill_template: Resource, direction: Vector2) -> bool:
	if not super.can_start(enemy, skill_template, direction):
		return false

	var normalized_direction := direction.normalized()
	var warning_length := float(skill_template.get("warning_length"))
	return float(enemy.get_world_clearance_for_skill(normalized_direction, warning_length)) > float(enemy.get_body_probe_radius())


func start(enemy, skill_template: Resource, direction: Vector2) -> void:
	super.start(enemy, skill_template, direction)
	_direction = direction.normalized()
	_hit_targets.clear()
	_spawn_warning()
	_enemy.begin_boss_windup(float(_skill.get("windup_duration")))


func update(delta: float) -> bool:
	if _enemy == null or _skill == null:
		return false

	if _enemy.is_in_skill_dash():
		return _update_dash(delta)

	_enemy.move_skill_idle(delta)
	if not _enemy.advance_skill_state(delta):
		return true

	if _enemy.is_in_skill_windup():
		_begin_dash()
		return true
	if _enemy.is_in_skill_recover():
		return false
	return true


func finish() -> void:
	_direction = Vector2.ZERO
	_hit_targets.clear()
	super.finish()


func _begin_dash() -> void:
	if _direction == Vector2.ZERO:
		return
	_hit_targets.clear()
	_enemy.begin_boss_dash(_direction, float(_skill.get("dash_speed")), float(_skill.get("dash_duration")))


func _update_dash(delta: float) -> bool:
	_enemy.move_skill_motion(delta, _direction)
	_try_hit_target()
	if _enemy.get_slide_collision_count() > 0:
		_begin_recover()
		return true
	if _enemy.advance_skill_state(delta):
		_begin_recover()
	return true


func _begin_recover() -> void:
	_enemy.begin_boss_recover(maxf(float(_skill.get("recover_duration")), 0.0))


func _spawn_warning() -> void:
	var parent: Node = _enemy.get_tree().current_scene
	if parent == null:
		parent = _enemy.get_parent()
	if parent == null:
		return

	var effect := BossDashWarningEffect.new()
	effect.global_position = _enemy.global_position
	effect.rotation = _direction.angle()
	parent.add_child(effect)
	effect.play(_skill)


func _try_hit_target() -> void:
	var player := _enemy.get_skill_target() as PlayerController
	if player == null or _hit_targets.has(player):
		return

	var offset: Vector2 = player.global_position - _enemy.global_position
	var body_radius := float(_enemy.get_body_probe_radius())
	var forward_distance: float = offset.dot(_direction)
	if forward_distance < -body_radius:
		return

	var hit_width := maxf(float(_skill.get("warning_width")), body_radius * 2.0)
	var side_distance := absf(offset.dot(_direction.orthogonal().normalized()))
	if side_distance > hit_width * 0.5:
		return
	if offset.length() > hit_width:
		return

	_hit_targets.append(player)
	player.take_damage(float(_skill.get("damage")))
	player.apply_knockback(player.global_position - _enemy.global_position, float(_skill.get("knockback")))
