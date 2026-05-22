class_name EnemyTemplateData
extends Resource

enum BehaviorType {
	MELEE,
	SWARM,
	PRESSURE,
	SHIELD,
	BOSS
}

@export var behavior_type: BehaviorType = BehaviorType.MELEE
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
@export var pressure_range: float = 0.0
@export var pressure_interval: float = 1.0
@export var pressure_damage: float = 0.0
@export var pressure_knockback: float = 0.0
@export var pressure_radius: float = 40.0
@export var pressure_warning_duration: float = 0.0
@export var knockback_taken_mult: float = 1.0
