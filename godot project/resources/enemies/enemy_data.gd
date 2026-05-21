class_name EnemyData
extends Resource

@export var id: StringName
@export var display_name: String = ""
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
