class_name WeaponController
extends Node2D

@export var build_state_path: NodePath = ^"../../BuildState"
@export var projectile_scene: PackedScene = preload("res://scenes/weapons/projectile.tscn")

var _cooldown_remaining: float = 0.0
var _burst_active: bool = false
@onready var _build_state: BuildState = get_node_or_null(build_state_path)


func _physics_process(delta: float) -> void:
	if _build_state == null or _burst_active:
		return

	_cooldown_remaining -= delta
	if _cooldown_remaining > 0.0:
		return

	var target := _find_nearest_enemy()
	if target == null:
		return

	var profile := _build_state.get_current_shot_profile()
	_cooldown_remaining = profile.cooldown
	_fire_profile(profile, target.global_position)


func _fire_profile(profile: ShotProfile, target_position: Vector2) -> void:
	if profile.burst_count <= 1:
		_spawn_projectile_group(profile, target_position)
		return

	_fire_burst(profile, target_position)


func _fire_burst(profile: ShotProfile, target_position: Vector2) -> void:
	_burst_active = true
	for index in range(profile.burst_count):
		_spawn_projectile_group(profile, target_position)
		if index < profile.burst_count - 1:
			await get_tree().create_timer(profile.burst_interval).timeout
	_burst_active = false


func _spawn_projectile_group(profile: ShotProfile, target_position: Vector2) -> void:
	var base_direction := (target_position - global_position).normalized()
	if base_direction == Vector2.ZERO:
		base_direction = Vector2.RIGHT

	for angle_offset in profile.angles:
		var projectile := projectile_scene.instantiate() as ProjectileController
		get_tree().current_scene.add_child(projectile)
		projectile.global_position = global_position
		projectile.configure(profile, base_direction.rotated(deg_to_rad(angle_offset)))


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D
	var nearest_distance := INF
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy is Node2D:
			continue

		var distance := global_position.distance_squared_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest
