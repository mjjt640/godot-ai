class_name BaseWeaponData
extends Resource

@export var id: StringName = &"core_bolt"
@export var display_name: String = "核心弹"
@export_multiline var description: String = "一把基础自动射击武器。"

@export var damage: float = 10.0
@export var cooldown: float = 0.55
@export var projectile_speed: float = 520.0
@export var projectile_lifetime: float = 1.6
@export var projectile_size: float = 1.0
@export var explosion_damage_mult: float = 0.55
@export var knockback_strength: float = 120.0
