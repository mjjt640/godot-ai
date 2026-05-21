class_name ShotProfile
extends RefCounted

var damage: float = 10.0
var cooldown: float = 0.55
var speed: float = 520.0
var lifetime: float = 1.6
var projectile_size: float = 1.0
var projectile_count: int = 1
var angles: Array[float] = [0.0]
var pierce_count: int = 0
var explosion_radius: float = 0.0
var explosion_damage_mult: float = 0.55
var knockback_strength: float = 120.0
var burst_count: int = 1
var burst_interval: float = 0.08
var attack_range: float = 780.0
var crit_chance: float = 0.0
var crit_damage_mult: float = 1.5


func duplicate_profile() -> ShotProfile:
	var copy := ShotProfile.new()
	copy.damage = damage
	copy.cooldown = cooldown
	copy.speed = speed
	copy.lifetime = lifetime
	copy.projectile_size = projectile_size
	copy.projectile_count = projectile_count
	copy.angles = angles.duplicate()
	copy.pierce_count = pierce_count
	copy.explosion_radius = explosion_radius
	copy.explosion_damage_mult = explosion_damage_mult
	copy.knockback_strength = knockback_strength
	copy.burst_count = burst_count
	copy.burst_interval = burst_interval
	copy.attack_range = attack_range
	copy.crit_chance = crit_chance
	copy.crit_damage_mult = crit_damage_mult
	return copy
