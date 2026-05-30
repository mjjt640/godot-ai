class_name BossArrowRainEffect
extends Node2D

const PressureImpactEffect = preload("res://scripts/effects/pressure_impact_effect.gd")
const PressureWarningEffect = preload("res://scripts/effects/pressure_warning_effect.gd")
const SequenceFrameEffectScript = preload("res://scripts/effects/sequence_frame_effect.gd")

var radius: float = 88.0
var warning_duration: float = 0.75
var impact_duration: float = 0.7
var damage: float = 24.0
var knockback: float = 220.0
var target_effect_path: String = ""
var target_effect_fps: float = 12.0
var target_effect_scale: float = 1.0
var rain_effect_path: String = ""
var rain_effect_fps: float = 18.0
var rain_effect_scale: float = 0.8
var combat_feedback: Resource

var _target: PlayerController
var _elapsed: float = 0.0
var _impact_started: bool = false


func play(
	target_position: Vector2,
	player_target: PlayerController,
	effect_radius: float,
	windup_duration: float,
	rain_impact_duration: float,
	rain_damage: float,
	rain_knockback: float,
	warning_effect_path: String,
	warning_effect_fps: float,
	warning_effect_scale: float,
	impact_effect_path: String,
	impact_effect_fps: float,
	impact_effect_scale: float,
	feedback: Resource
) -> void:
	global_position = target_position
	_target = player_target
	radius = maxf(effect_radius, 1.0)
	warning_duration = maxf(windup_duration, 0.05)
	impact_duration = maxf(rain_impact_duration, 0.05)
	damage = maxf(rain_damage, 0.0)
	knockback = maxf(rain_knockback, 0.0)
	target_effect_path = warning_effect_path
	target_effect_fps = maxf(warning_effect_fps, 1.0)
	target_effect_scale = maxf(warning_effect_scale, 0.01)
	rain_effect_path = impact_effect_path
	rain_effect_fps = maxf(impact_effect_fps, 1.0)
	rain_effect_scale = maxf(impact_effect_scale, 0.01)
	combat_feedback = feedback
	_spawn_warning()
	_spawn_target_sequence()


func _physics_process(delta: float) -> void:
	_elapsed += delta
	if not _impact_started and _elapsed >= warning_duration:
		_start_impact()
	if _impact_started and _elapsed >= warning_duration + impact_duration:
		queue_free()


func _spawn_warning() -> void:
	var warning := PressureWarningEffect.new()
	add_child(warning)
	warning.play(radius, warning_duration, combat_feedback)


func _spawn_target_sequence() -> void:
	if target_effect_path.is_empty():
		return

	var target_effect := SequenceFrameEffectScript.new()
	target_effect.configure(target_effect_path, target_effect_fps, true, warning_duration, target_effect_scale)
	add_child(target_effect)


func _start_impact() -> void:
	_impact_started = true
	_apply_damage()

	var impact := PressureImpactEffect.new()
	add_child(impact)
	impact.play(radius, combat_feedback)

	if rain_effect_path.is_empty():
		return
	var rain_effect := SequenceFrameEffectScript.new()
	rain_effect.configure(rain_effect_path, rain_effect_fps, false, 0.0, rain_effect_scale)
	add_child(rain_effect)


func _apply_damage() -> void:
	if _target == null or not is_instance_valid(_target):
		return
	if global_position.distance_to(_target.global_position) > radius:
		return

	_target.take_damage(damage)
	var push_direction := _target.global_position - global_position
	if push_direction == Vector2.ZERO:
		push_direction = Vector2.RIGHT
	_target.apply_knockback(push_direction, knockback)
