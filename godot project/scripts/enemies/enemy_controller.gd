class_name EnemyController
extends CharacterBody2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const DamageNumber = preload("res://scripts/effects/damage_number.gd")
const DashSkillExecutor = preload("res://scripts/enemies/dash_skill_executor.gd")
const PressureEnemyBehaviorExecutor = preload("res://scripts/enemies/pressure_enemy_behavior_executor.gd")
const TouchDamageBehaviorExecutor = preload("res://scripts/enemies/touch_damage_behavior_executor.gd")

signal died(experience_reward: int, death_position: Vector2)
signal health_changed(current_health: float, max_health: float)

enum CombatState {
	CHASE,
	WINDUP,
	DASH,
	RECOVER
}

@export var enemy_data: EnemyData
@export var combat_feedback: Resource = preload("res://resources/combat/default_combat_feedback.tres")

var health: float = 1.0
var _target: Node2D
var _knockback_velocity: Vector2 = Vector2.ZERO
var _last_navigation_position: Vector2 = Vector2.ZERO
var _navigation_stuck_time: float = 0.0
var _detour_direction: int = 0
var _detour_remaining: float = 0.0
var _obstacle_escape_remaining: float = 0.0
var _last_world_collision_normal: Vector2 = Vector2.ZERO
var _body_probe_radius: float = 0.0
var _combat_state: CombatState = CombatState.CHASE
var _combat_state_remaining: float = 0.0
var _skill_motion_velocity: Vector2 = Vector2.ZERO
var _skill_cooldowns: Dictionary = {}
var _skill_executors: Array = []
var _active_skill_executor
var _behavior_executors: Array = []
@onready var _visual: Node2D = get_node_or_null("Visual") as Node2D
@onready var _health_bar: ProgressBar = get_node_or_null("HealthBar") as ProgressBar
@onready var _collision_shape: CollisionShape2D = get_node_or_null("CollisionShape2D") as CollisionShape2D


func _ready() -> void:
	collision_layer = CollisionLayers.ENEMY
	collision_mask = CollisionLayers.WORLD
	add_to_group("enemies")
	if enemy_data != null:
		health = enemy_data.get_max_health()
	_skill_executors = [DashSkillExecutor.new()]
	_behavior_executors = [TouchDamageBehaviorExecutor.new(), PressureEnemyBehaviorExecutor.new()]
	_body_probe_radius = _resolve_body_probe_radius()
	_last_navigation_position = global_position
	_refresh_health_bar()
	_start_visual_animation()
	_find_target()


func _physics_process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		_find_target()
		return

	_tick_behavior_executors(_delta)
	if _update_combat_state(_delta):
		return

	var delta_to_target := _target.global_position - global_position
	_update_behavior_executors(delta_to_target, _delta)
	_try_enemy_skill(delta_to_target, _delta)
	if _combat_state != CombatState.CHASE:
		return
	var stop_distance := enemy_data.get_stop_distance() if enemy_data != null else 34.0
	if delta_to_target.length() <= stop_distance and _has_clear_target_line(delta_to_target):
		_update_contact_behavior_executors(delta_to_target)
		velocity = _get_separation_velocity() + _knockback_velocity
		move_and_slide()
		_reset_navigation_stuck()
		_decay_knockback(_delta)
		return

	var direction := _get_navigation_direction(delta_to_target, _delta)
	velocity = direction * _get_move_speed() + _get_separation_velocity() + _knockback_velocity
	move_and_slide()
	_recover_from_slide_collisions(direction)
	_update_navigation_stuck(_delta, direction)
	_decay_knockback(_delta)


func take_damage(amount: float) -> void:
	health -= amount
	_refresh_health_bar()
	health_changed.emit(health, get_max_health())
	_play_hit_feedback()
	_spawn_damage_number(amount)
	if health <= 0.0:
		_die()


func _find_target() -> void:
	var players := get_tree().get_nodes_in_group("player")
	_target = players[0] if not players.is_empty() else null


func _start_visual_animation() -> void:
	if not _visual is AnimatedSprite2D:
		return

	var animated := _visual as AnimatedSprite2D
	if animated.sprite_frames != null and animated.sprite_frames.has_animation(&"idle"):
		animated.play(&"idle")


func _get_move_speed() -> float:
	return enemy_data.get_move_speed() if enemy_data != null else 100.0


func get_max_health() -> float:
	return enemy_data.get_max_health() if enemy_data != null else max(health, 1.0)


func get_display_name() -> String:
	if enemy_data != null and not enemy_data.display_name.is_empty():
		return enemy_data.display_name
	return "敌人"


func get_combat_state() -> int:
	return int(_combat_state)


func begin_boss_windup(duration: float) -> void:
	if not _can_use_boss_skill_state():
		return
	_set_combat_state(CombatState.WINDUP, duration)


func begin_boss_dash(direction: Vector2, speed: float, duration: float) -> void:
	if not _can_use_boss_skill_state() or direction == Vector2.ZERO:
		return
	_skill_motion_velocity = direction.normalized() * maxf(speed, 0.0)
	_set_combat_state(CombatState.DASH, duration)


func begin_boss_recover(duration: float) -> void:
	if not _can_use_boss_skill_state():
		return
	_set_combat_state(CombatState.RECOVER, duration)


func return_to_chase() -> void:
	if _active_skill_executor != null:
		_active_skill_executor.finish()
		_active_skill_executor = null
	_skill_motion_velocity = Vector2.ZERO
	_set_combat_state(CombatState.CHASE, 0.0)


func get_skill_target() -> Node2D:
	return _target


func get_body_probe_radius() -> float:
	return _body_probe_radius


func get_world_clearance_for_skill(direction: Vector2, distance: float) -> float:
	return _get_world_clearance(direction, distance)


func get_behavior_target() -> Node2D:
	return _target


func has_clear_target_line_for_behavior(delta_to_target: Vector2) -> bool:
	return _has_clear_target_line(delta_to_target)


func is_in_skill_windup() -> bool:
	return _combat_state == CombatState.WINDUP


func is_in_skill_dash() -> bool:
	return _combat_state == CombatState.DASH


func is_in_skill_recover() -> bool:
	return _combat_state == CombatState.RECOVER


func advance_skill_state(delta: float) -> bool:
	_combat_state_remaining -= delta
	return _combat_state_remaining <= 0.0


func move_skill_idle(delta: float) -> void:
	velocity = _knockback_velocity
	move_and_slide()
	_reset_navigation_stuck()
	_decay_knockback(delta)


func move_skill_motion(delta: float, direction: Vector2) -> void:
	velocity = _skill_motion_velocity + _get_separation_velocity() + _knockback_velocity
	move_and_slide()
	_recover_from_slide_collisions(direction)
	_update_navigation_stuck(delta, direction)
	_decay_knockback(delta)


func _get_separation_velocity() -> Vector2:
	var radius: float = enemy_data.get_separation_radius() if enemy_data != null else 42.0
	var strength: float = enemy_data.get_separation_strength() if enemy_data != null else 150.0
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


func _get_navigation_direction(delta_to_target: Vector2, delta: float) -> Vector2:
	if delta_to_target == Vector2.ZERO:
		return Vector2.ZERO

	if _detour_remaining > 0.0:
		_detour_remaining -= delta
	if _obstacle_escape_remaining > 0.0:
		_obstacle_escape_remaining -= delta

	var direct_direction := delta_to_target.normalized()
	var probe_distance := _get_path_probe_distance(delta_to_target.length())
	if probe_distance <= 0.0:
		return direct_direction

	var direct_blocked := _is_world_blocked(direct_direction, probe_distance)
	var is_stuck := enemy_data != null and _navigation_stuck_time >= enemy_data.get_path_stuck_time()
	if not direct_blocked and not is_stuck:
		_detour_direction = 0
		return direct_direction

	if _detour_direction == 0 or _detour_remaining <= 0.0 or _obstacle_escape_remaining > 0.0:
		_detour_direction = _choose_detour_direction(direct_direction, probe_distance)
		_detour_remaining = enemy_data.get_path_detour_commit_time() if enemy_data != null else 0.42

	var side_angle := enemy_data.get_path_side_probe_angle() if enemy_data != null else 0.9
	var side_direction := direct_direction.rotated(side_angle * _get_detour_angle_multiplier() * float(_detour_direction))
	var avoidance_strength := enemy_data.get_path_avoidance_strength() if enemy_data != null else 1.15
	return (direct_direction + side_direction * avoidance_strength).normalized()


func _get_path_probe_distance(target_distance: float) -> float:
	var probe_distance := enemy_data.get_path_probe_distance() if enemy_data != null else 144.0
	var stop_distance := enemy_data.get_stop_distance() if enemy_data != null else 34.0
	return minf(probe_distance, maxf(target_distance - stop_distance, 0.0))


func _choose_detour_direction(direct_direction: Vector2, probe_distance: float) -> int:
	var side_angle := enemy_data.get_path_side_probe_angle() if enemy_data != null else 0.9
	return _choose_clearer_direction(direct_direction, side_angle, probe_distance)


func _choose_clearer_direction(direct_direction: Vector2, side_angle: float, probe_distance: float) -> int:
	var best_direction := 1 if int(get_instance_id()) % 2 == 0 else -1
	var best_score := -INF
	var angle_multiplier := _get_detour_angle_multiplier()
	for side in [-1, 1]:
		for multiplier in [1.0, angle_multiplier, angle_multiplier + 0.65]:
			var candidate := direct_direction.rotated(side_angle * multiplier * float(side))
			var score := _get_world_clearance(candidate, probe_distance)
			if _last_world_collision_normal != Vector2.ZERO:
				score += maxf(candidate.dot(_last_world_collision_normal), 0.0) * _get_move_speed() * 0.25
			if score > best_score:
				best_score = score
				best_direction = side
	return best_direction


func _get_detour_angle_multiplier() -> float:
	var is_stuck := enemy_data != null and _navigation_stuck_time >= enemy_data.get_path_stuck_time()
	if _obstacle_escape_remaining > 0.0 or is_stuck:
		return 1.75
	return 1.0


func _has_clear_target_line(delta_to_target: Vector2) -> bool:
	if delta_to_target == Vector2.ZERO:
		return true
	return not _is_world_blocked(delta_to_target.normalized(), delta_to_target.length())


func _is_world_blocked(direction: Vector2, distance: float) -> bool:
	return _get_world_clearance(direction, distance) < distance


func _get_world_clearance(direction: Vector2, distance: float) -> float:
	if direction == Vector2.ZERO or distance <= 0.0:
		return 0.0

	var normalized_direction := direction.normalized()
	var nearest_clearance := distance
	for offset in _get_body_probe_offsets(normalized_direction):
		nearest_clearance = minf(nearest_clearance, _get_offset_world_clearance(normalized_direction, distance, offset))
	return nearest_clearance


func _get_center_world_clearance(direction: Vector2, distance: float) -> float:
	if direction == Vector2.ZERO or distance <= 0.0:
		return 0.0
	return _get_offset_world_clearance(direction.normalized(), distance, Vector2.ZERO)


func _get_offset_world_clearance(direction: Vector2, distance: float, offset: Vector2) -> float:
	var start := global_position + offset
	var query := PhysicsRayQueryParameters2D.create(start, start + direction * distance)
	query.collision_mask = CollisionLayers.WORLD
	query.exclude = [get_rid()]
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return distance
	return start.distance_to(hit["position"])


func _get_body_probe_offsets(direction: Vector2) -> Array[Vector2]:
	var offsets: Array[Vector2] = [Vector2.ZERO]
	var scaled_radius := _get_scaled_body_probe_radius()
	if scaled_radius <= 1.0:
		return offsets

	var side := direction.orthogonal().normalized() * scaled_radius
	offsets.append(side)
	offsets.append(-side)
	return offsets


func _get_scaled_body_probe_radius() -> float:
	var scale := enemy_data.get_path_body_probe_scale() if enemy_data != null else 0.75
	return _body_probe_radius * maxf(scale, 0.0)


func _resolve_body_probe_radius() -> float:
	if _collision_shape == null or _collision_shape.shape == null:
		return 0.0
	if _collision_shape.shape is CircleShape2D:
		return (_collision_shape.shape as CircleShape2D).radius
	if _collision_shape.shape is RectangleShape2D:
		var size := (_collision_shape.shape as RectangleShape2D).size
		return maxf(size.x, size.y) * 0.5
	return 0.0


func _update_navigation_stuck(delta: float, direction: Vector2) -> void:
	if direction == Vector2.ZERO or _knockback_velocity.length() > 1.0:
		_reset_navigation_stuck()
		return

	var moved_speed := global_position.distance_to(_last_navigation_position) / maxf(delta, 0.001)
	var stuck_threshold := enemy_data.get_path_stuck_speed_threshold() if enemy_data != null else 12.0
	if moved_speed <= stuck_threshold:
		_navigation_stuck_time += delta
	else:
		_navigation_stuck_time = 0.0
	_last_navigation_position = global_position


func _reset_navigation_stuck() -> void:
	_navigation_stuck_time = 0.0
	_last_navigation_position = global_position


func _recover_from_slide_collisions(direction: Vector2) -> void:
	if direction == Vector2.ZERO:
		return

	for index in range(get_slide_collision_count()):
		var collision := get_slide_collision(index)
		if collision == null:
			continue
		var collider := collision.get_collider()
		if not collider is CollisionObject2D:
			continue
		var collision_object := collider as CollisionObject2D
		if collision_object.collision_layer & CollisionLayers.WORLD == 0:
			continue

		_last_world_collision_normal = collision.get_normal()
		_obstacle_escape_remaining = maxf(_obstacle_escape_remaining, 0.28)
		var normal_side := signf(_last_world_collision_normal.cross(direction))
		if not is_zero_approx(normal_side):
			_detour_direction = int(normal_side)
			_detour_remaining = enemy_data.get_path_detour_commit_time() if enemy_data != null else 0.42
		return


func _update_behavior_executors(delta_to_target: Vector2, delta: float) -> void:
	if enemy_data == null:
		return
	for executor in _behavior_executors:
		if executor != null and executor.matches(enemy_data):
			executor.update(self, delta_to_target, delta)


func _tick_behavior_executors(delta: float) -> void:
	if enemy_data == null:
		return
	for executor in _behavior_executors:
		if executor != null and executor.matches(enemy_data):
			executor.tick(self, delta)


func _update_contact_behavior_executors(delta_to_target: Vector2) -> void:
	if enemy_data == null:
		return
	for executor in _behavior_executors:
		if executor != null and executor.matches(enemy_data):
			executor.update_contact(self, delta_to_target)


func _try_enemy_skill(delta_to_target: Vector2, delta: float) -> void:
	_update_skill_cooldowns(delta)
	if enemy_data == null or not enemy_data.get_is_boss():
		return
	if _combat_state != CombatState.CHASE:
		return
	if delta_to_target == Vector2.ZERO:
		return

	var skill := _choose_enemy_skill(delta_to_target)
	if skill == null:
		return
	_start_enemy_skill(skill, delta_to_target.normalized())


func _update_skill_cooldowns(delta: float) -> void:
	for id in _skill_cooldowns.keys():
		_skill_cooldowns[id] = maxf(float(_skill_cooldowns[id]) - delta, 0.0)


func _choose_enemy_skill(delta_to_target: Vector2) -> Resource:
	var pool := enemy_data.get_skill_pool() if enemy_data != null else null
	if pool == null:
		return null

	var skills: Array = pool.get("skills")
	var distance := delta_to_target.length()
	var direction := delta_to_target.normalized()
	for skill in skills:
		if skill == null:
			continue
		if float(_skill_cooldowns.get(skill.get("id"), 0.0)) > 0.0:
			continue
		if distance < float(skill.get("min_range")) or distance > float(skill.get("max_range")):
			continue
		var executor = _find_skill_executor(skill)
		if executor == null or not executor.can_start(self, skill, direction):
			continue
		return skill
	return null


func _start_enemy_skill(skill: Resource, direction: Vector2) -> void:
	var executor = _find_skill_executor(skill)
	if executor == null or not executor.can_start(self, skill, direction):
		return
	_skill_cooldowns[skill.get("id")] = maxf(float(skill.get("cooldown")), 0.0)
	_active_skill_executor = executor
	_active_skill_executor.start(self, skill, direction)


func _find_skill_executor(skill: Resource):
	for executor in _skill_executors:
		if executor != null and executor.matches(skill):
			return executor
	return null


func _update_combat_state(delta: float) -> bool:
	if _combat_state == CombatState.CHASE:
		return false

	if _active_skill_executor != null:
		if _active_skill_executor.update(delta):
			return true
		_finish_active_skill_executor()
		return true

	if _combat_state == CombatState.DASH:
		move_skill_motion(delta, _skill_motion_velocity.normalized())
	else:
		move_skill_idle(delta)

	if advance_skill_state(delta):
		return_to_chase()
	return true


func _finish_active_skill_executor() -> void:
	if _active_skill_executor != null:
		_active_skill_executor.finish()
		_active_skill_executor = null
	return_to_chase()


func _set_combat_state(state: CombatState, duration: float) -> void:
	_combat_state = state
	_combat_state_remaining = maxf(duration, 0.0)
	if state != CombatState.DASH:
		_skill_motion_velocity = Vector2.ZERO


func _can_use_boss_skill_state() -> bool:
	return enemy_data != null and enemy_data.get_is_boss()


func apply_hit_reaction(push_direction: Vector2, force: float) -> void:
	_apply_hit_reaction(push_direction, force)


func _apply_hit_reaction(push_direction: Vector2, force: float) -> void:
	if push_direction == Vector2.ZERO:
		return

	var knockback_mult := enemy_data.get_knockback_taken_mult() if enemy_data != null else 1.0
	_knockback_velocity += push_direction.normalized() * force * knockback_mult
	velocity = _knockback_velocity


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
	var damage_number_parent := get_tree().current_scene
	if damage_number_parent == null:
		damage_number_parent = get_parent()
	if damage_number_parent == null:
		return
	damage_number_parent.add_child(damage_number)
	if enemy_data != null and enemy_data.get_is_boss():
		damage_number.modulate = combat_feedback.get("damage_number_boss_color")
	elif enemy_data != null and enemy_data.get_is_elite():
		damage_number.modulate = combat_feedback.get("damage_number_elite_color")
	damage_number.play(amount, combat_feedback)


func _refresh_health_bar() -> void:
	if _health_bar == null:
		return

	var max_value: float = get_max_health()
	_health_bar.max_value = max_value
	_health_bar.value = clampf(health, 0.0, max_value)
	_health_bar.visible = _should_show_overhead_health_bar(max_value)


func _die() -> void:
	var reward := enemy_data.get_experience_reward() if enemy_data != null else 1
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


func _should_show_overhead_health_bar(max_value: float) -> bool:
	if enemy_data != null and enemy_data.get_is_boss():
		return false
	if enemy_data != null and enemy_data.get_is_elite():
		return health > 0.0
	return health < max_value and health > 0.0
