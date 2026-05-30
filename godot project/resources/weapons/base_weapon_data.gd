class_name BaseWeaponData
extends Resource

@export var id: StringName = &"core_bolt"
@export var display_name: String = "枪芒"
@export_multiline var description: String = "以长枪为基础武器母题的自动武器，用模块改变连刺、扫击、贯穿和震爆。"

@export var damage: float = 10.0
@export var cooldown: float = 0.55
@export var projectile_speed: float = 520.0
@export var projectile_lifetime: float = 1.6
@export var projectile_size: float = 1.0
@export var attack_range: float = 780.0
@export var can_pierce_world: bool = false
@export var explosion_damage_mult: float = 0.55
@export var knockback_strength: float = 120.0
