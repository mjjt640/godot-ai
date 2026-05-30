class_name ArrowEnemySkillData
extends "res://resources/enemies/enemy_skill_data.gd"

enum AttackMode {
	SHOT,
	RAIN
}

@export_enum("Shot", "Rain") var attack_mode: int = AttackMode.SHOT
@export var windup_duration: float = 0.6
@export var release_duration: float = 0.28
@export var recover_duration: float = 0.35
@export var damage: float = 22.0
@export var knockback: float = 240.0
@export var requires_line_of_sight: bool = true
@export var warning_length: float = 520.0
@export var warning_width: float = 48.0
@export var warning_ring_width: float = 3.0
@export var warning_color: Color = Color(0.55, 0.84, 1.0, 0.92)
@export var warning_fill_color: Color = Color(0.22, 0.45, 1.0, 0.18)
@export var projectile_speed: float = 760.0
@export var projectile_hit_radius: float = 28.0
@export var projectile_spawn_offset: float = 18.0
@export var shot_effect_path: String = "res://art/effects/boss_m20001/charged_arrow"
@export var shot_effect_fps: float = 18.0
@export var shot_effect_scale: float = 0.42
@export var impact_effect_path: String = "res://art/effects/boss_m20001/arrow_fire"
@export var impact_effect_fps: float = 18.0
@export var impact_effect_scale: float = 0.52
@export var rain_radius: float = 92.0
@export var rain_target_effect_path: String = "res://art/effects/boss_m20001/firerain_target"
@export var rain_target_effect_fps: float = 12.0
@export var rain_target_effect_scale: float = 1.0
@export var rain_effect_path: String = "res://art/effects/boss_m20001/firerain"
@export var rain_effect_fps: float = 18.0
@export var rain_effect_scale: float = 0.82
