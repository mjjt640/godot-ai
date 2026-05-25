class_name TouchDamageBehaviorExecutor
extends "res://scripts/enemies/enemy_behavior_executor.gd"

var _cooldown_remaining: float = 0.0


func matches(enemy_data: Resource) -> bool:
	return enemy_data != null


func tick(enemy, delta: float) -> void:
	super.tick(enemy, delta)
	if _cooldown_remaining > 0.0:
		_cooldown_remaining -= delta


func update_contact(enemy, _delta_to_target: Vector2) -> void:
	super.update_contact(enemy, _delta_to_target)
	if _enemy == null or _enemy.enemy_data == null:
		return
	if _cooldown_remaining > 0.0:
		return

	var player := _enemy.get_behavior_target() as PlayerController
	if player == null:
		return

	player.take_damage(_enemy.enemy_data.get_touch_damage())
	var push_direction: Vector2 = player.global_position - _enemy.global_position
	if push_direction == Vector2.ZERO:
		push_direction = -_enemy.velocity
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	player.apply_knockback(push_direction, _enemy.enemy_data.get_player_knockback())
	_enemy.apply_hit_reaction((_enemy.global_position - player.global_position).normalized(), _enemy.enemy_data.get_touch_knockback())
	_cooldown_remaining = _enemy.enemy_data.get_touch_interval()


func reset() -> void:
	_cooldown_remaining = 0.0
	super.reset()
