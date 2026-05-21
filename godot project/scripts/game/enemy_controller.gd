class_name EnemyController
extends CharacterBody2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const DamageNumber = preload("res://scripts/effects/damage_number.gd")

signal died(experience_reward: int, death_position: Vector2)

@export var enemy_data: EnemyData
@export var combat_feedback: Resource = preload("res://resources/combat/default_combat_feedback.tres")

var health: float = 1.0
var _target: Node2D
var _touch_cooldown_remaining: float = 0.0
var _knockback_velocity: Vector2 = Vector2.ZERO
@onready var _visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var _health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar


func _ready() -> void:
	collision_layer = CollisionLayers.ENEMY
	collision_mask = CollisionLayers.WORLD
	add_to_group("enemies")
	if enemy_data != null:
		health = enemy_data.max_health
	_refresh_health_bar()
	_find_target()


func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_find_target()
		return

	if _touch_cooldown_remaining > 0.0:
		_touch_cooldown_remaining -= _delta

	var delta_to_target := _target.global_position - global_position
	var stop_distance := enemy_data.stop_distance if enemy_data != null else 34.0
	if delta_to_target.length() <= stop_distance:
		_try_touch_damage()
		velocity = _get_separation_velocity() + _knockback_velocity
		move_and_slide()
		_decay_knockback(_delta)
		return

	var direction := delta_to_target.normalized()
	velocity = direction * _get_move_speed() + _get_separation_velocity() + _knockback_velocity
	move_and_slide()
	_decay_knockback(_delta)


func take_damage(amount: float) -> void:
	health -= amount
	_refresh_health_bar()
	_play_hit_feedback()
	_spawn_damage_number(amount)
	if health <= 0.0:
		_die()


func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	_target = players[0] if not players.is_empty() else null


func _get_move_speed() -> float:
	return enemy_data.move_speed if enemy_data != null else 100.0


func _get_separation_velocity() -> Vector2:
	var radius: float = enemy_data.separation_radius if enemy_data != null else 42.0
	var strength: float = enemy_data.separation_strength if enemy_data != null else 150.0
	if radius <= 0.0 or strength <= 0.0:
		return Vector2.ZERO

	var push := Vector2.ZERO
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == self or not enemy is Node2D:
			continue

		var enemy_node := enemy as Node2D
		var offset: Vector2 = global_position - enemy_node.global_position
		var distance: float = offset.length()
		if distance >= radius:
			continue
		if distance <= 0.001:
			offset = Vector2.RIGHT.rotated(float(get_instance_id() % 360) * TAU / 360.0)
			distance = 0.001
		push += offset.normalized() * (1.0 - distance / radius)

	return push.limit_length(1.0) * strength


func _try_touch_damage() -> void:
	if _touch_cooldown_remaining > 0.0:
		return

	var player := _target as PlayerController
	if player == null:
		return

	var touch_damage := enemy_data.touch_damage if enemy_data != null else 5.0
	player.take_damage(touch_damage)
	var touch_knockback := enemy_data.touch_knockback if enemy_data != null else 90.0
	var player_knockback := enemy_data.player_knockback if enemy_data != null else 140.0
	var push_direction := player.global_position - global_position
	if push_direction == Vector2.ZERO:
		push_direction = -velocity
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	player.apply_knockback(push_direction, player_knockback)
	_apply_hit_reaction((global_position - player.global_position).normalized(), touch_knockback)
	_touch_cooldown_remaining = enemy_data.touch_interval if enemy_data != null else 0.6


func apply_hit_reaction(push_direction: Vector2, force: float) -> void:
	_apply_hit_reaction(push_direction, force)


func _apply_hit_reaction(push_direction: Vector2, force: float) -> void:
	if push_direction == Vector2.ZERO:
		return

	_knockback_velocity += push_direction.normalized() * force


func _decay_knockback(delta: float) -> void:
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, 1200.0 * delta)


func _play_hit_feedback() -> void:
	if _visual == null:
		return

	_visual.scale = Vector2.ONE * float(combat_feedback.get("enemy_hit_scale"))
	_visual.modulate = combat_feedback.get("enemy_hit_color")
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector2.ONE, float(combat_feedback.get("enemy_hit_duration")))
	tween.parallel().tween_property(_visual, "modulate", Color.WHITE, float(combat_feedback.get("enemy_hit_duration")))


func _spawn_damage_number(amount: float) -> void:
	var damage_number := DamageNumber.new()
	var spread := float(combat_feedback.get("damage_number_spread"))
	damage_number.global_position = global_position + Vector2(randf_range(-spread, spread), -28.0)
	get_tree().current_scene.add_child(damage_number)
	damage_number.play(amount, combat_feedback)


func _refresh_health_bar() -> void:
	if _health_bar == null:
		return

	var max_value: float = enemy_data.max_health if enemy_data != null else max(health, 1.0)
	_health_bar.max_value = max_value
	_health_bar.value = clampf(health, 0.0, max_value)
	_health_bar.visible = health < max_value and health > 0.0


func _die() -> void:
	var reward := enemy_data.experience_reward if enemy_data != null else 1
	died.emit(reward, global_position)

	set_physics_process(false)
	collision_layer = 0
	collision_mask = 0
	if _visual == null:
		queue_free()
		return

	_visual.scale = Vector2.ONE * float(combat_feedback.get("enemy_death_scale"))
	_visual.modulate = combat_feedback.get("enemy_death_color")
	var tween := create_tween()
	tween.tween_property(_visual, "scale", Vector2.ZERO, float(combat_feedback.get("enemy_death_duration")))
	tween.parallel().tween_property(_visual, "modulate:a", 0.0, float(combat_feedback.get("enemy_death_duration")))
	tween.finished.connect(queue_free)
