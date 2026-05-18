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
var burst_count: int = 1
var burst_interval: float = 0.08


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
	copy.burst_count = burst_count
	copy.burst_interval = burst_interval
	return copy
