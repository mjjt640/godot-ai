class_name EnemyData
extends Resource

const EnemyTemplateData = preload("res://resources/enemies/enemy_template_data.gd")

@export var id: StringName
@export var display_name: String = ""
@export var template: Resource
@export var is_elite: bool = false
@export var is_boss: bool = false
@export var max_health: float = 20.0
@export var move_speed: float = 110.0
@export var touch_damage: float = 8.0
@export var touch_knockback: float = 90.0
@export var player_knockback: float = 140.0
@export var stop_distance: float = 34.0
@export var separation_radius: float = 42.0
@export var separation_strength: float = 150.0
@export var touch_interval: float = 0.6
@export var experience_reward: int = 1
@export var skill_pool: Resource
@export var path_probe_distance: float = 144.0
@export var path_side_probe_angle: float = 0.9
@export var path_avoidance_strength: float = 1.15
@export var path_body_probe_scale: float = 0.75
@export var path_stuck_speed_threshold: float = 12.0
@export var path_stuck_time: float = 0.24
@export var path_detour_commit_time: float = 0.42
@export var behavior_type: int = -1
@export var pressure_range: float = 0.0
@export var pressure_interval: float = 0.0
@export var pressure_damage: float = 0.0
@export var pressure_knockback: float = 0.0
@export var pressure_radius: float = 0.0
@export var pressure_warning_duration: float = 0.0
@export var knockback_taken_mult: float = 0.0


func get_is_elite() -> bool:
	return is_elite or (template != null and template.is_elite)


func get_is_boss() -> bool:
	return is_boss or (template != null and template.is_boss)


func get_max_health() -> float:
	return _resolve_float(&"max_health")


func get_move_speed() -> float:
	return _resolve_float(&"move_speed")


func get_touch_damage() -> float:
	return _resolve_float(&"touch_damage")


func get_touch_knockback() -> float:
	return _resolve_float(&"touch_knockback")


func get_player_knockback() -> float:
	return _resolve_float(&"player_knockback")


func get_stop_distance() -> float:
	return _resolve_float(&"stop_distance")


func get_separation_radius() -> float:
	return _resolve_float(&"separation_radius")


func get_separation_strength() -> float:
	return _resolve_float(&"separation_strength")


func get_touch_interval() -> float:
	return _resolve_float(&"touch_interval")


func get_experience_reward() -> int:
	if experience_reward > 0:
		return experience_reward
	if template != null:
		return template.experience_reward
	return 1


func get_skill_pool() -> Resource:
	if skill_pool != null:
		return skill_pool
	if template != null:
		return template.get("skill_pool")
	return null


func get_path_probe_distance() -> float:
	return _resolve_float(&"path_probe_distance")


func get_path_side_probe_angle() -> float:
	return _resolve_float(&"path_side_probe_angle")


func get_path_avoidance_strength() -> float:
	return _resolve_float(&"path_avoidance_strength")


func get_path_body_probe_scale() -> float:
	return _resolve_float(&"path_body_probe_scale")


func get_path_stuck_speed_threshold() -> float:
	return _resolve_float(&"path_stuck_speed_threshold")


func get_path_stuck_time() -> float:
	return _resolve_float(&"path_stuck_time")


func get_path_detour_commit_time() -> float:
	return _resolve_float(&"path_detour_commit_time")


func get_behavior_type() -> int:
	if behavior_type >= 0:
		return behavior_type
	if template != null:
		return int(template.get("behavior_type"))
	return EnemyTemplateData.BehaviorType.MELEE


func get_pressure_range() -> float:
	return _resolve_behavior_float(&"pressure_range")


func get_pressure_interval() -> float:
	return _resolve_behavior_float(&"pressure_interval")


func get_pressure_damage() -> float:
	return _resolve_behavior_float(&"pressure_damage")


func get_pressure_knockback() -> float:
	return _resolve_behavior_float(&"pressure_knockback")


func get_pressure_radius() -> float:
	return _resolve_behavior_float(&"pressure_radius")


func get_pressure_warning_duration() -> float:
	var value := _resolve_behavior_float(&"pressure_warning_duration")
	if value <= 0.0:
		return 0.45
	return value


func get_knockback_taken_mult() -> float:
	var value := _resolve_behavior_float(&"knockback_taken_mult")
	if value <= 0.0:
		return 1.0
	return value


func _resolve_float(property_name: StringName) -> float:
	var local_value := float(get(property_name))
	var default_value := _default_float(property_name)
	if not is_equal_approx(local_value, default_value):
		return local_value
	if template != null:
		return float(template.get(property_name))
	return local_value


func _resolve_behavior_float(property_name: StringName) -> float:
	var local_value := float(get(property_name))
	if local_value > 0.0:
		return local_value
	if template != null:
		var template_value := float(template.get(property_name))
		if template_value > 0.0:
			return template_value
	if property_name == &"pressure_interval":
		return 1.0
	if property_name == &"knockback_taken_mult":
		return 1.0
	return 0.0


func _default_float(property_name: StringName) -> float:
	match property_name:
		&"max_health":
			return 20.0
		&"move_speed":
			return 110.0
		&"touch_damage":
			return 8.0
		&"touch_knockback":
			return 90.0
		&"player_knockback":
			return 140.0
		&"stop_distance":
			return 34.0
		&"separation_radius":
			return 42.0
		&"separation_strength":
			return 150.0
		&"touch_interval":
			return 0.6
		&"path_probe_distance":
			return 144.0
		&"path_side_probe_angle":
			return 0.9
		&"path_avoidance_strength":
			return 1.15
		&"path_body_probe_scale":
			return 0.75
		&"path_stuck_speed_threshold":
			return 12.0
		&"path_stuck_time":
			return 0.24
		&"path_detour_commit_time":
			return 0.42
	return 0.0
