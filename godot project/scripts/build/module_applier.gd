class_name ModuleApplier
extends RefCounted


static func create_shot_profile(base_weapon: BaseWeaponData, modules_by_slot: Dictionary, stat_modifiers: Dictionary = {}, character_modifiers: Dictionary = {}) -> ShotProfile:
	var profile := ShotProfile.new()
	if base_weapon != null:
		profile.damage = base_weapon.damage
		profile.cooldown = base_weapon.cooldown
		profile.speed = base_weapon.projectile_speed
		profile.lifetime = base_weapon.projectile_lifetime
		profile.projectile_size = base_weapon.projectile_size
		profile.attack_range = base_weapon.attack_range
		profile.can_pierce_world = base_weapon.can_pierce_world
		profile.explosion_damage_mult = base_weapon.explosion_damage_mult
		profile.knockback_strength = base_weapon.knockback_strength

	_apply_character_modifiers(profile, character_modifiers)
	for module in modules_by_slot.values():
		if module != null:
			_apply_module_modifiers(profile, module)
	_apply_stat_modifiers(profile, stat_modifiers)
	return profile


static func _apply_module_modifiers(profile: ShotProfile, module: ModuleData) -> void:
	profile.damage += module.damage_add
	profile.damage *= module.damage_mult
	profile.cooldown += module.cooldown_add
	profile.cooldown *= module.cooldown_mult
	profile.speed += module.speed_add
	profile.speed *= module.speed_mult
	profile.knockback_strength += module.knockback_add
	profile.knockback_strength *= module.knockback_mult

	if module.projectile_count >= 0:
		profile.projectile_count = module.projectile_count
	if not module.angles.is_empty():
		profile.angles = module.angles.duplicate()
	if module.burst_count >= 0:
		profile.burst_count = module.burst_count
	if module.burst_interval >= 0.0:
		profile.burst_interval = module.burst_interval
	if module.pierce_count >= 0:
		profile.pierce_count = module.pierce_count
	if module.explosion_radius >= 0.0:
		profile.explosion_radius = module.explosion_radius
	if module.explosion_damage_mult >= 0.0:
		profile.explosion_damage_mult = module.explosion_damage_mult
	if not module.stat_modifiers.is_empty():
		_apply_stat_modifiers(profile, module.stat_modifiers)


static func _apply_character_modifiers(profile: ShotProfile, modifiers: Dictionary) -> void:
	if modifiers.is_empty():
		return

	var attack_speed: float = max(_float_modifier(modifiers, &"attack_speed", 1.0), 0.01)
	profile.cooldown /= attack_speed
	profile.attack_range = min(profile.attack_range, max(_float_modifier(modifiers, &"attack_range", profile.attack_range), 0.0))
	profile.crit_chance = clampf(_float_modifier(modifiers, &"crit_chance", profile.crit_chance), 0.0, 1.0)
	profile.crit_damage_mult = max(_float_modifier(modifiers, &"crit_damage_mult", profile.crit_damage_mult), 1.0)


static func _apply_stat_modifiers(profile: ShotProfile, modifiers: Dictionary) -> void:
	if modifiers.is_empty():
		return

	profile.damage += _float_modifier(modifiers, &"damage_add", 0.0)
	profile.damage *= _float_modifier(modifiers, &"damage_mult", 1.0)
	profile.cooldown += _float_modifier(modifiers, &"cooldown_add", 0.0)
	profile.cooldown *= _float_modifier(modifiers, &"cooldown_mult", 1.0)
	profile.speed += _float_modifier(modifiers, &"speed_add", 0.0)
	profile.speed *= _float_modifier(modifiers, &"speed_mult", 1.0)
	profile.projectile_size += _float_modifier(modifiers, &"projectile_size_add", 0.0)
	profile.projectile_size *= _float_modifier(modifiers, &"projectile_size_mult", 1.0)
	profile.projectile_count += _int_modifier(modifiers, &"projectile_count_add", 0)
	profile.burst_count += _int_modifier(modifiers, &"burst_count_add", 0)
	profile.burst_interval += _float_modifier(modifiers, &"burst_interval_add", 0.0)
	profile.burst_interval *= _float_modifier(modifiers, &"burst_interval_mult", 1.0)
	profile.pierce_count += _int_modifier(modifiers, &"pierce_count_add", 0)
	profile.explosion_radius += _float_modifier(modifiers, &"explosion_radius_add", 0.0)
	profile.explosion_damage_mult += _float_modifier(modifiers, &"explosion_damage_mult_add", 0.0)
	profile.explosion_damage_mult *= _float_modifier(modifiers, &"explosion_damage_mult_mult", 1.0)
	profile.knockback_strength += _float_modifier(modifiers, &"knockback_add", 0.0)
	profile.knockback_strength *= _float_modifier(modifiers, &"knockback_mult", 1.0)
	var attack_speed: float = max((1.0 + _float_modifier(modifiers, &"attack_speed_add", 0.0)) * _float_modifier(modifiers, &"attack_speed_mult", 1.0), 0.01)
	profile.cooldown /= attack_speed
	profile.attack_range += _float_modifier(modifiers, &"attack_range_add", 0.0)
	profile.attack_range *= _float_modifier(modifiers, &"attack_range_mult", 1.0)
	profile.attack_range = max(profile.attack_range, 0.0)
	profile.crit_chance += _float_modifier(modifiers, &"crit_chance_add", 0.0)
	profile.crit_chance = clampf(profile.crit_chance, 0.0, 1.0)
	profile.crit_damage_mult += _float_modifier(modifiers, &"crit_damage_mult_add", 0.0)
	profile.crit_damage_mult *= _float_modifier(modifiers, &"crit_damage_mult_mult", 1.0)
	profile.crit_damage_mult = max(profile.crit_damage_mult, 1.0)


static func _float_modifier(modifiers: Dictionary, key: StringName, default_value: float) -> float:
	if modifiers.has(key):
		return float(modifiers[key])
	var string_key := String(key)
	if modifiers.has(string_key):
		return float(modifiers[string_key])
	return default_value


static func _int_modifier(modifiers: Dictionary, key: StringName, default_value: int) -> int:
	return int(round(_float_modifier(modifiers, key, float(default_value))))
