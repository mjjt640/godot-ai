class_name ProgressionChecks
extends RefCounted


func check_default_character_resource(ctx) -> void:
	var character := load("res://resources/characters/character_core_runner.tres")
	if character == null:
		ctx.failures.append("Failed to load default character resource")
		return

	check_character_fields(ctx, character, "Default character")

	var template := load("res://resources/characters/character_template.tres")
	if template == null:
		ctx.failures.append("Failed to load character template resource")
	else:
		check_character_fields(ctx, template, "Character template")

	var player := ctx.instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	if player == null:
		return
	ctx.root.add_child(player)
	ctx.expect(player.character_data != null, "Player scene should assign default character_data")
	if player.character_data != null:
		ctx.expect(is_equal_approx(player.move_speed, float(player.character_data.get("move_speed"))), "Player should apply character move_speed")
		ctx.expect(is_equal_approx(player.max_health, float(player.character_data.get("max_health"))), "Player should apply character max_health")
		ctx.expect(is_equal_approx(player.get_luck(), float(player.character_data.get("luck"))), "Player should apply character luck")
	ctx.remove_instance(player)


func check_default_character_pool(ctx) -> void:
	var pool := load("res://resources/characters/default_character_pool.tres") as Resource
	if pool == null:
		ctx.failures.append("Failed to load default character pool")
		return

	var characters: Array = pool.get("characters")
	ctx.expect(not characters.is_empty(), "Default character pool needs at least one character")
	ctx.expect(characters.size() >= 3, "Default character pool should include first-pass character variety")
	var default_character: Resource = pool.call("get_default_character") as Resource
	ctx.expect(default_character != null, "Default character pool should resolve default character")
	for character in characters:
		if character != null:
			check_character_fields(ctx, character, "Pooled character %s" % character.get("id"))
	if default_character != null:
		check_character_fields(ctx, default_character, "Default pooled character")


func check_character_fields(ctx, character: Resource, label: String) -> void:
	ctx.expect(character.get("id") != &"", "%s needs id" % label)
	ctx.expect(character.get("display_name") != "", "%s needs Chinese display_name" % label)
	ctx.expect(character.get("description") != "", "%s needs Chinese description" % label)
	ctx.expect(float(character.get("move_speed")) > 0.0, "%s needs positive move_speed" % label)
	ctx.expect(float(character.get("max_health")) > 0.0, "%s needs positive max_health" % label)
	ctx.expect(float(character.get("xp_magnet_radius")) > 0.0, "%s needs positive xp_magnet_radius" % label)
	ctx.expect(character.get(ctx.removed_xp_movement_key) == null, "%s should not expose removed XP magnet movement stat" % label)
	ctx.expect(float(character.get("luck")) >= 0.0, "%s needs non-negative luck" % label)
	ctx.expect(float(character.get("attack_speed")) > 0.0, "%s needs positive attack_speed" % label)
	ctx.expect(float(character.get("attack_range")) > 0.0, "%s needs positive attack_range" % label)
	ctx.expect(float(character.get("crit_chance")) >= 0.0, "%s needs non-negative crit_chance" % label)
	ctx.expect(float(character.get("crit_damage_mult")) >= 1.0, "%s needs crit_damage_mult >= 1.0" % label)
	ctx.expect(character.get("starting_fire_module") != null, "%s should reserve starting_fire_module" % label)
	ctx.expect(character.get("starting_payload_module") != null, "%s should reserve starting_payload_module" % label)


func check_upgrade_pool(ctx) -> void:
	var pool := load("res://resources/upgrades/pools/default_upgrade_pool.tres") as UpgradePoolData
	if pool == null:
		ctx.failures.append("Failed to load default upgrade pool")
		return

	var option_count: int = pool.option_count
	var options: Array = pool.options
	ctx.expect(option_count == 3, "Default upgrade pool should present three options")
	ctx.expect(pool.max_module_count > 0, "Default upgrade pool should configure a positive module cap")
	ctx.expect(pool.common_rarity_weight > pool.rare_rarity_weight, "Common upgrades should refresh more often than rare upgrades")
	ctx.expect(pool.rare_rarity_weight > pool.epic_rarity_weight, "Rare upgrades should refresh more often than epic upgrades")
	ctx.expect(pool.epic_rarity_weight > pool.legendary_rarity_weight, "Epic upgrades should refresh more often than legendary upgrades")
	ctx.expect(options.size() >= option_count, "Default upgrade pool needs enough options")
	for option in options:
		ctx.expect(option != null, "Upgrade pool should not contain null options")
		if option != null:
			ctx.expect(option.display_name != "", "Upgrade option %s needs Chinese display_name" % option.id)
			ctx.expect(option.weight > 0.0, "Upgrade option %s needs positive weight" % option.id)
			ctx.expect(pool.get_rarity_weight(option.rarity) > 0.0, "Upgrade option %s needs positive rarity weight" % option.id)
			ctx.expect(option.upgrade_type == UpgradeOptionData.UpgradeType.MODULE, "Default upgrade pool should only install modules: %s" % option.id)
			ctx.expect(option.module != null, "Module upgrade %s needs module data" % option.id)
			ctx.expect(option.stat_modifiers.is_empty(), "Module install option %s should not carry stat_modifiers" % option.id)
			ctx.expect(option.general_modifiers.is_empty(), "Module install option %s should not carry general_modifiers" % option.id)
			if option.module != null:
				ctx.expect(int(option.module.rarity) == int(option.rarity), "Module upgrade %s should match module rarity" % option.id)


func check_module_skill_pool(ctx) -> void:
	var pool := load("res://resources/upgrades/pools/default_module_skill_pool.tres") as UpgradePoolData
	if pool == null:
		ctx.failures.append("Failed to load default module skill pool")
		return

	var effect_stat_option_count := 0
	var has_blast_radius_boost := false
	var has_splash_damage_boost := false
	var has_luck_boost := false
	var has_attack_speed_boost := false
	var has_attack_range_boost := false
	var has_crit_chance_boost := false
	var has_crit_damage_boost := false
	var has_piercing_firepower := false
	var has_wide_spread := false
	var has_blast_aftershock := false
	var has_legendary_option := false
	ctx.expect(pool.option_count == 3, "Default module skill pool should present three options")
	ctx.expect(pool.common_rarity_weight > pool.rare_rarity_weight, "Module skill common weight should exceed rare weight")
	ctx.expect(pool.rare_rarity_weight > pool.epic_rarity_weight, "Module skill rare weight should exceed epic weight")
	ctx.expect(pool.epic_rarity_weight > pool.legendary_rarity_weight, "Module skill epic weight should exceed legendary weight")
	for option in pool.options:
		ctx.expect(option != null, "Module skill pool should not contain null options")
		if option == null:
			continue
		ctx.expect(option.display_name != "", "Module skill %s needs Chinese display_name" % option.id)
		ctx.expect(option.weight > 0.0, "Module skill %s needs positive weight" % option.id)
		ctx.expect(option.upgrade_type == UpgradeOptionData.UpgradeType.STAT, "Module skill %s should use STAT type" % option.id)
		ctx.expect(not option.stat_modifiers.is_empty(), "Module skill %s should declare stat_modifiers" % option.id)
		ctx.expect(option.general_modifiers.is_empty(), "Module skill %s should not use general_modifiers" % option.id)
		ctx.expect(not option.required_module_ids.is_empty(), "Module skill %s should declare required_module_ids" % option.id)
		ctx.expect(pool.get_rarity_weight(option.rarity) > 0.0, "Module skill %s needs positive rarity weight" % option.id)
		if option.rarity == UpgradeOptionData.Rarity.LEGENDARY:
			has_legendary_option = true
		if not option.stat_modifiers.is_empty():
			effect_stat_option_count += 1
			ctx.expect(not (option.stat_modifiers.has(&"explosion_radius_add") and option.stat_modifiers.has(&"explosion_damage_mult_add")), "Module skill %s should not mix explosion radius and splash damage" % option.id)
			if option.stat_modifiers.has(&"explosion_radius_add"):
				has_blast_radius_boost = true
			if option.stat_modifiers.has(&"explosion_damage_mult_add"):
				has_splash_damage_boost = true
			if option.stat_modifiers.has(&"luck_add"):
				has_luck_boost = true
			if option.stat_modifiers.has(&"attack_speed_add"):
				has_attack_speed_boost = true
			if option.stat_modifiers.has(&"attack_range_add"):
				has_attack_range_boost = true
			if option.stat_modifiers.has(&"crit_chance_add"):
				has_crit_chance_boost = true
			if option.stat_modifiers.has(&"crit_damage_mult_add"):
				has_crit_damage_boost = true
		if option.id == &"upgrade_piercing_firepower":
			has_piercing_firepower = true
			ctx.expect(option.required_module_ids.has(&"piercing_round"), "Piercing firepower should depend on piercing module")
		if option.id == &"upgrade_wide_spread":
			has_wide_spread = true
			ctx.expect(option.required_module_ids.has(&"spread_fire"), "Wide spread should depend on spread fire module")
		if option.id == &"upgrade_blast_aftershock":
			has_blast_aftershock = true
			ctx.expect(option.required_module_ids.has(&"explosive_payload"), "Blast aftershock should depend on explosive payload module")
	ctx.expect(effect_stat_option_count >= 8, "Default module skill pool should include resource-driven module skills")
	ctx.expect(has_blast_radius_boost, "Default upgrade pool should include a separate blast radius upgrade")
	ctx.expect(has_splash_damage_boost, "Default upgrade pool should include a separate splash damage upgrade")
	ctx.expect(has_luck_boost, "Default module skill pool should include luck module skill")
	ctx.expect(has_attack_speed_boost, "Default module skill pool should include attack speed module skill")
	ctx.expect(has_attack_range_boost, "Default module skill pool should include attack range module skill")
	ctx.expect(has_crit_chance_boost, "Default module skill pool should include crit chance module skill")
	ctx.expect(has_crit_damage_boost, "Default module skill pool should include crit damage module skill")
	ctx.expect(has_piercing_firepower, "Default module skill pool should include piercing firepower upgrade")
	ctx.expect(has_wide_spread, "Default module skill pool should include wide spread upgrade")
	ctx.expect(has_blast_aftershock, "Default module skill pool should include blast aftershock upgrade")
	ctx.expect(has_legendary_option, "Default upgrade pool should include at least one legendary option")


func check_general_skill_pool(ctx, has_module_skill_stat_fn: Callable) -> void:
	var pool := load("res://resources/upgrades/pools/default_general_skill_pool.tres") as UpgradePoolData
	if pool == null:
		ctx.failures.append("Failed to load default general skill pool")
		return

	var has_magnet_range := false
	var has_health_recovery := false
	var has_move_speed := false
	var has_xp_gain := false
	var has_legendary_xp_gain := false
	var has_epic_magnet_multiplier := false
	var magnet_rarities: Array[int] = []
	var health_rarities: Array[int] = []
	var move_speed_rarities: Array[int] = []
	var xp_gain_rarities: Array[int] = []
	ctx.expect(pool.common_rarity_weight > pool.rare_rarity_weight, "General skill pool common weight should exceed rare weight")
	ctx.expect(pool.rare_rarity_weight > pool.epic_rarity_weight, "General skill pool rare weight should exceed epic weight")
	ctx.expect(pool.epic_rarity_weight > pool.legendary_rarity_weight, "General skill pool epic weight should exceed legendary weight")
	for option in pool.options:
		ctx.expect(option != null, "General skill pool should not contain null options")
		if option == null:
			continue
		ctx.expect(option.upgrade_type == UpgradeOptionData.UpgradeType.GENERAL, "General skill %s should use GENERAL upgrade type" % option.id)
		ctx.expect(not option.general_modifiers.is_empty(), "General skill %s should declare general_modifiers" % option.id)
		ctx.expect(option.stat_modifiers.is_empty(), "General skill %s should not use weapon stat_modifiers" % option.id)
		ctx.expect(not bool(has_module_skill_stat_fn.call(option.general_modifiers)), "General skill %s should not use module skill stats" % option.id)
		if option.general_modifiers.has(&"xp_magnet_radius_add"):
			has_magnet_range = true
			magnet_rarities.append(option.rarity)
		if option.general_modifiers.has(&"xp_magnet_radius_mult"):
			has_epic_magnet_multiplier = has_epic_magnet_multiplier or option.rarity == UpgradeOptionData.Rarity.EPIC
		if option.general_modifiers.has(&"heal_add"):
			has_health_recovery = true
			health_rarities.append(option.rarity)
		if option.general_modifiers.has(&"move_speed_add") or option.general_modifiers.has(&"move_speed_mult"):
			has_move_speed = true
			move_speed_rarities.append(option.rarity)
		if option.general_modifiers.has(&"xp_gain_mult"):
			has_xp_gain = true
			xp_gain_rarities.append(option.rarity)
			if option.rarity == UpgradeOptionData.Rarity.LEGENDARY:
				has_legendary_xp_gain = true
		elif option.rarity == UpgradeOptionData.Rarity.LEGENDARY:
			ctx.failures.append("Only XP gain general skills should have legendary rarity: %s" % option.id)
	ctx.expect(has_magnet_range, "General skill pool should include XP magnet range skill")
	ctx.expect(has_health_recovery, "General skill pool should include health recovery skill")
	ctx.expect(has_move_speed, "General skill pool should include move speed skill")
	ctx.expect(has_xp_gain, "General skill pool should include XP gain speed skill")
	ctx.expect(has_legendary_xp_gain, "General skill pool should include legendary XP gain speed skill")
	ctx.expect(has_epic_magnet_multiplier, "General skill pool should include epic XP magnet multiplier skill")
	ctx.expect(_has_common_rare_epic(magnet_rarities), "XP magnet range should have common, rare and epic variants")
	ctx.expect(_has_common_rare_epic(health_rarities), "Health recovery should have common, rare and epic variants")
	ctx.expect(_has_common_rare_epic(move_speed_rarities), "Move speed should have common, rare and epic variants")
	ctx.expect(_has_common_rare_epic(xp_gain_rarities), "XP gain speed should have common, rare and epic variants")


func check_upgrade_resource_grouping(ctx) -> void:
	var module_install_pool_path := "res://resources/upgrades/pools/default_upgrade_pool.tres"
	var module_skill_pool_path := "res://resources/upgrades/pools/default_module_skill_pool.tres"
	var general_skill_pool_path := "res://resources/upgrades/pools/default_general_skill_pool.tres"
	ctx.expect(FileAccess.file_exists(module_install_pool_path), "Module install pool should live under resources/upgrades/pools")
	ctx.expect(FileAccess.file_exists(module_skill_pool_path), "Module skill pool should live under resources/upgrades/pools")
	ctx.expect(FileAccess.file_exists(general_skill_pool_path), "General skill pool should live under resources/upgrades/pools")

	var module_install_pool := load(module_install_pool_path) as UpgradePoolData
	var module_skill_pool := load(module_skill_pool_path) as UpgradePoolData
	var general_skill_pool := load(general_skill_pool_path) as UpgradePoolData

	if module_install_pool != null:
		for option in module_install_pool.options:
			if option == null:
				continue
			var option_path := String(option.resource_path)
			ctx.expect(option_path.contains("/resources/upgrades/modules/"), "Module install option should live under resources/upgrades/modules: %s" % option.id)
			if option.module != null:
				var module_path := String(option.module.resource_path)
				ctx.expect(
					module_path.contains("/resources/modules/fire_modes/") or module_path.contains("/resources/modules/payloads/"),
					"Installed module should live under fire_modes or payloads: %s" % option.id
				)

	if module_skill_pool != null:
		for option in module_skill_pool.options:
			if option == null:
				continue
			var option_path := String(option.resource_path)
			ctx.expect(option_path.contains("/resources/upgrades/modules/"), "Module skill option should live under resources/upgrades/modules: %s" % option.id)

	if general_skill_pool != null:
		for option in general_skill_pool.options:
			if option == null:
				continue
			var option_path := String(option.resource_path)
			ctx.expect(
				option_path.contains("/resources/upgrades/general/") or option_path.contains("/resources/upgrades/economy/"),
				"General skill option should live under resources/upgrades/general or economy: %s" % option.id
			)

	var build_state_source := FileAccess.get_file_as_string("res://scripts/build/build_state.gd")
	ctx.expect(build_state_source.find("res://resources/modules/fire_modes/") >= 0, "BuildState should load default fire modules from resources/modules/fire_modes")
	ctx.expect(build_state_source.find("res://resources/modules/payloads/") >= 0, "BuildState should load default payload modules from resources/modules/payloads")

	var upgrade_manager_source := FileAccess.get_file_as_string("res://scripts/progression/upgrade_manager.gd")
	ctx.expect(upgrade_manager_source.find("res://resources/upgrades/pools/default_upgrade_pool.tres") >= 0, "UpgradeManager should load module install pool from resources/upgrades/pools")
	ctx.expect(upgrade_manager_source.find("res://resources/upgrades/pools/default_module_skill_pool.tres") >= 0, "UpgradeManager should load module skill pool from resources/upgrades/pools")
	ctx.expect(upgrade_manager_source.find("res://resources/upgrades/pools/default_general_skill_pool.tres") >= 0, "UpgradeManager should load general skill pool from resources/upgrades/pools")


func check_upgrade_filtering_rules(ctx, find_upgrade_option_fn: Callable) -> void:
	var pool := load("res://resources/upgrades/pools/default_upgrade_pool.tres") as UpgradePoolData
	var module_skill_pool := load("res://resources/upgrades/pools/default_module_skill_pool.tres") as UpgradePoolData
	if pool == null or module_skill_pool == null:
		return

	var build_state := BuildState.new()
	build_state.default_fire_mode = null
	build_state.default_payload = null
	ctx.root.add_child(build_state)

	var upgrade_manager := UpgradeManager.new()
	ctx.root.add_child(upgrade_manager)
	upgrade_manager.upgrade_pool = pool
	upgrade_manager.module_skill_pool = module_skill_pool
	upgrade_manager._build_state = build_state

	var pierce_boost: UpgradeOptionData = find_upgrade_option_fn.call(module_skill_pool, &"upgrade_pierce_boost")
	if pierce_boost != null:
		ctx.expect(not upgrade_manager._can_offer(pierce_boost), "Pierce boost should not appear before piercing module is current")
		var piercing_module := load("res://resources/modules/payloads/payload_piercing.tres") as ModuleData
		build_state.install_module(piercing_module, false, false)
		ctx.expect(upgrade_manager._can_offer(pierce_boost), "Pierce boost should appear after piercing module is current")

	var luck_boost: UpgradeOptionData = find_upgrade_option_fn.call(module_skill_pool, &"upgrade_luck_boost")
	if luck_boost != null:
		ctx.expect(upgrade_manager._can_offer(luck_boost), "Luck boost should appear when a required starting module is current")

	var module_option: UpgradeOptionData = find_upgrade_option_fn.call(pool, &"upgrade_burst_fire")
	if module_option != null:
		build_state.acquired_module_ids = [&"burst_fire"]
		ctx.expect(not upgrade_manager._can_offer(module_option), "Already acquired modules should wait for the future replacement path")
		var capped_module_ids: Array[StringName] = []
		for index in range(pool.max_module_count):
			capped_module_ids.append(StringName("module_%d" % index))
		build_state.acquired_module_ids = capped_module_ids
		ctx.expect(not upgrade_manager._can_offer(module_option), "Module upgrades should stop appearing after module cap")

	ctx.remove_instance(upgrade_manager)
	ctx.remove_instance(build_state)


func check_upgrade_pool_decoupling(ctx) -> void:
	var empty_module_pool := UpgradePoolData.new()
	empty_module_pool.options = []
	empty_module_pool.option_count = 3

	var module_skill_pool := UpgradePoolData.new()
	module_skill_pool.option_count = 3
	var stat_option := UpgradeOptionData.new()
	stat_option.id = &"decoupled_stat_probe"
	stat_option.display_name = "解耦强化"
	stat_option.upgrade_type = UpgradeOptionData.UpgradeType.STAT
	stat_option.stat_modifiers = {&"attack_range_add": 1.0}
	stat_option.required_module_ids = [&"normal_payload"]
	module_skill_pool.options = [stat_option]

	var general_pool := UpgradePoolData.new()
	general_pool.option_count = 3
	var general_option := UpgradeOptionData.new()
	general_option.id = &"decoupled_general_probe"
	general_option.display_name = "解耦通用"
	general_option.upgrade_type = UpgradeOptionData.UpgradeType.GENERAL
	general_option.general_modifiers = {&"xp_magnet_radius_add": 1.0}
	general_pool.options = [general_option]

	var build_state := BuildState.new()
	build_state.default_fire_mode = null
	build_state.default_payload = null
	ctx.root.add_child(build_state)
	var normal_payload := load("res://resources/modules/payloads/payload_normal.tres") as ModuleData
	build_state.install_module(normal_payload, false, false)

	var upgrade_manager := UpgradeManager.new()
	ctx.root.add_child(upgrade_manager)
	upgrade_manager.upgrade_pool = empty_module_pool
	upgrade_manager.module_skill_pool = module_skill_pool
	upgrade_manager.general_skill_pool = general_pool
	upgrade_manager._build_state = build_state

	var options := upgrade_manager.request_options()
	ctx.expect(options.has(stat_option), "Module skill pool should still offer options when module install pool is empty")
	ctx.expect(options.has(general_option), "General skill pool should still offer options when module install pool is empty")
	ctx.remove_instance(upgrade_manager)
	ctx.remove_instance(build_state)


func _has_common_rare_epic(rarities: Array[int]) -> bool:
	return (
		rarities.has(UpgradeOptionData.Rarity.COMMON)
		and rarities.has(UpgradeOptionData.Rarity.RARE)
		and rarities.has(UpgradeOptionData.Rarity.EPIC)
	)
