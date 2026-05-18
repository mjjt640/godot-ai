class_name ModuleApplier
extends RefCounted

const FIRE_SINGLE: StringName = &"single_shot"
const FIRE_BURST: StringName = &"burst_fire"
const FIRE_SPREAD: StringName = &"spread_fire"
const PAYLOAD_NORMAL: StringName = &"normal_payload"
const PAYLOAD_PIERCING: StringName = &"piercing_round"
const PAYLOAD_EXPLOSIVE: StringName = &"explosive_round"


static func create_shot_profile(base_weapon: BaseWeaponData, modules_by_slot: Dictionary) -> ShotProfile:
	var profile := ShotProfile.new()
	if base_weapon != null:
		profile.damage = base_weapon.damage
		profile.cooldown = base_weapon.cooldown
		profile.speed = base_weapon.projectile_speed
		profile.lifetime = base_weapon.projectile_lifetime
		profile.projectile_size = base_weapon.projectile_size

	for module in modules_by_slot.values():
		if module != null:
			_apply_stat_modifiers(profile, module.stat_modifiers)

	_apply_fire_mode(profile, modules_by_slot.get(ModuleData.SLOT_FIRE_MODE))
	_apply_payload(profile, modules_by_slot.get(ModuleData.SLOT_PAYLOAD))
	return profile


static func _apply_stat_modifiers(profile: ShotProfile, modifiers: Dictionary) -> void:
	profile.damage += float(modifiers.get(&"damage_add", 0.0))
	profile.damage *= float(modifiers.get(&"damage_mult", 1.0))
	profile.cooldown += float(modifiers.get(&"cooldown_add", 0.0))
	profile.cooldown *= float(modifiers.get(&"cooldown_mult", 1.0))
	profile.speed += float(modifiers.get(&"speed_add", 0.0))
	profile.speed *= float(modifiers.get(&"speed_mult", 1.0))


static func _apply_fire_mode(profile: ShotProfile, module: ModuleData) -> void:
	var module_id := module.id if module != null else FIRE_SINGLE
	match module_id:
		FIRE_BURST:
			profile.projectile_count = 1
			profile.angles = [0.0]
			profile.burst_count = 3
			profile.burst_interval = 0.09
			profile.cooldown *= 1.25
			profile.damage *= 0.78
		FIRE_SPREAD:
			profile.projectile_count = 3
			profile.angles = [-13.0, 0.0, 13.0]
			profile.burst_count = 1
			profile.damage *= 0.72
		_:
			profile.projectile_count = 1
			profile.angles = [0.0]
			profile.burst_count = 1


static func _apply_payload(profile: ShotProfile, module: ModuleData) -> void:
	var module_id := module.id if module != null else PAYLOAD_NORMAL
	match module_id:
		PAYLOAD_PIERCING:
			profile.pierce_count = 2
			profile.damage *= 0.9
		PAYLOAD_EXPLOSIVE:
			profile.explosion_radius = 72.0
			profile.damage *= 0.82
		_:
			profile.pierce_count = 0
			profile.explosion_radius = 0.0
