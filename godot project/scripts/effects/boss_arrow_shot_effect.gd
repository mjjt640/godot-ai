class_name BossArrowShotEffect
extends Node2D

const SequenceFrameEffectScript = preload("res://scripts/effects/sequence_frame_effect.gd")

var direction: Vector2 = Vector2.RIGHT
var speed: float = 720.0
var travel_distance: float = 520.0
var damage: float = 22.0
var knockback: float = 240.0
var hit_radius: float = 26.0
var impact_effect_path: String = ""
var impact_effect_fps: float = 18.0
var impact_effect_scale: float = 0.5

var _target: PlayerController
var _traveled: float = 0.0
var _hit: bool = false


func play(
	start_position: Vector2,
	shot_direction: Vector2,
	max_travel_distance: float,
	shot_speed: float,
	shot_damage: float,
	shot_knockback: float,
	shot_hit_radius: float,
	player_target: PlayerController,
	flight_effect_path: String,
	flight_effect_fps: float,
	flight_effect_scale: float,
	shot_impact_effect_path: String,
	shot_impact_effect_fps: float,
	shot_impact_effect_scale: float
) -> void:
	global_position = start_position
	direction = shot_direction.normalized() if shot_direction != Vector2.ZERO else Vector2.RIGHT
	rotation = direction.angle()
	travel_distance = maxf(max_travel_distance, 1.0)
	speed = maxf(shot_speed, 1.0)
	damage = maxf(shot_damage, 0.0)
	knockback = maxf(shot_knockback, 0.0)
	hit_radius = maxf(shot_hit_radius, 1.0)
	_target = player_target
	impact_effect_path = shot_impact_effect_path
	impact_effect_fps = maxf(shot_impact_effect_fps, 1.0)
	impact_effect_scale = maxf(shot_impact_effect_scale, 0.01)

	if not flight_effect_path.is_empty():
		var flight_effect := SequenceFrameEffectScript.new()
		flight_effect.configure(flight_effect_path, flight_effect_fps, true, 0.0, flight_effect_scale)
		add_child(flight_effect)


func _physics_process(delta: float) -> void:
	var step_distance := speed * delta
	var start_position := global_position
	var end_position := start_position + direction * step_distance
	global_position = end_position
	_traveled += step_distance

	_try_hit_segment(start_position, end_position)
	if _traveled >= travel_distance and not is_queued_for_deletion():
		_spawn_impact(end_position)
		queue_free()


func _try_hit_segment(start_position: Vector2, end_position: Vector2) -> void:
	if _hit or _target == null or not is_instance_valid(_target):
		return

	var segment := end_position - start_position
	var closest := start_position
	var segment_length_squared := segment.length_squared()
	if segment_length_squared > 0.001:
		var t := clampf((_target.global_position - start_position).dot(segment) / segment_length_squared, 0.0, 1.0)
		closest = start_position + segment * t

	if closest.distance_to(_target.global_position) > hit_radius:
		return

	_hit = true
	_target.take_damage(damage)
	_target.apply_knockback(direction, knockback)
	_spawn_impact(closest)
	queue_free()


func _spawn_impact(effect_position: Vector2) -> void:
	if impact_effect_path.is_empty():
		return

	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return

	var impact_effect := SequenceFrameEffectScript.new()
	impact_effect.global_position = effect_position
	impact_effect.rotation = rotation
	impact_effect.configure(impact_effect_path, impact_effect_fps, false, 0.0, impact_effect_scale)
	parent.add_child(impact_effect)
