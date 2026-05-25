class_name UIRunProfileChecks
extends RefCounted


func check_health_bar_ui(ctx) -> void:
	var hud = ctx.instantiate_scene("res://scenes/ui/hud.tscn")
	if hud != null:
		ctx.root.add_child(hud)
		var character_label := hud.get_node_or_null("%CharacterLabel") as Label
		ctx.expect(character_label != null, "HUD should include a player character Label")
		var health_bar := hud.get_node_or_null("%HealthBar") as ProgressBar
		ctx.expect(health_bar != null, "HUD should include a player health ProgressBar")
		if health_bar != null:
			ctx.expect(not health_bar.show_percentage, "HUD health bar should hide percentage text")
		ctx.remove_instance(hud)

	for scene_path in [
		"res://scenes/enemies/enemy_basic.tscn",
		"res://scenes/enemies/enemy_fast.tscn",
		"res://scenes/enemies/enemy_tank.tscn",
	]:
		var enemy = ctx.instantiate_scene(scene_path)
		if enemy == null:
			continue
		ctx.root.add_child(enemy)
		var enemy_health_bar := enemy.get_node_or_null("HealthBar") as ProgressBar
		ctx.expect(enemy_health_bar != null, "%s should include an enemy health ProgressBar" % scene_path)
		if enemy_health_bar != null:
			ctx.expect(not enemy_health_bar.show_percentage, "%s enemy health bar should hide percentage text" % scene_path)
		ctx.remove_instance(enemy)


func check_hud_run_objective_ui(ctx, game_text) -> void:
	var hud = ctx.instantiate_scene("res://scenes/ui/hud.tscn")
	if hud == null:
		return

	ctx.root.add_child(hud)
	ctx.expect(hud.get_node_or_null("%RunTimeLabel") != null, "HUD should include a run time Label")
	ctx.expect(hud.get_node_or_null("%ObjectiveLabel") != null, "HUD should include a run objective Label")
	ctx.expect(hud.get_node_or_null("%NextEventLabel") != null, "HUD should include a next objective event Label")

	var objective = load("res://resources/runs/default_run_objective.tres")
	hud.update_run_status(12.0, objective)
	var run_time_label := hud.get_node_or_null("%RunTimeLabel") as Label
	var objective_label := hud.get_node_or_null("%ObjectiveLabel") as Label
	var next_event_label := hud.get_node_or_null("%NextEventLabel") as Label
	if run_time_label != null:
		ctx.expect(run_time_label.text.find("00:12") >= 0, "HUD run time should render elapsed time")
	if objective_label != null:
		ctx.expect(objective_label.text.find("目标") >= 0, "HUD objective text should explain the run objective")
	if next_event_label != null:
		ctx.expect(next_event_label.text.find("精英") >= 0, "HUD next event should describe the first elite event")
		ctx.expect(next_event_label.text.find(game_text.format_time(58.0)) >= 0, "HUD next event should show remaining time")

	hud.update_run_status(181.0, objective)
	if next_event_label != null:
		ctx.expect(next_event_label.text.find("Boss") >= 0 or next_event_label.text.find("压制核心") >= 0, "HUD next event should keep boss pressure visible after boss spawn")
	ctx.remove_instance(hud)


func check_boss_health_bar_ui(ctx) -> void:
	var hud = ctx.instantiate_scene("res://scenes/ui/hud.tscn")
	if hud == null:
		return

	ctx.root.add_child(hud)
	var status_panel: Node = hud.get_node_or_null("Root/StatusPanel")
	ctx.expect(status_panel != null, "HUD player status should be anchored in the upper-left StatusPanel")
	var old_center_margin: Node = hud.get_node_or_null("Root/MarginContainer")
	ctx.expect(old_center_margin == null, "HUD should not keep player status in a centered MarginContainer")

	var boss_panel := hud.get_node_or_null("%BossHealthPanel") as Control
	var boss_bar := hud.get_node_or_null("%BossHealthBar") as ProgressBar
	var boss_label := hud.get_node_or_null("%BossHealthLabel") as Label
	ctx.expect(boss_panel != null, "HUD should include a top-center BossHealthPanel")
	ctx.expect(boss_bar != null, "HUD should include a BossHealthBar")
	ctx.expect(boss_label != null, "HUD should include a BossHealthLabel")
	if boss_panel != null:
		ctx.expect(not boss_panel.visible, "Boss health panel should start hidden")

	var boss = ctx.instantiate_scene("res://scenes/enemies/enemy_boss_overseer.tscn")
	if boss != null:
		ctx.root.add_child(boss)
		ctx.expect(hud.has_method("track_boss"), "HUD should expose track_boss for boss health UI")
		if hud.has_method("track_boss"):
			hud.track_boss(boss)
		if boss_panel != null:
			ctx.expect(boss_panel.visible, "Boss health panel should show while tracking boss")
		if boss_bar != null:
			ctx.expect(is_equal_approx(boss_bar.max_value, boss.get_max_health()), "Boss health bar max should use boss health")
		boss.take_damage(10.0)
		if boss_bar != null:
			ctx.expect(is_equal_approx(boss_bar.value, boss.health), "Boss health bar should update from boss health signal")
		ctx.remove_instance(boss)
	ctx.remove_instance(hud)


func check_enemy_health_bar_rules(ctx) -> void:
	var normal_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_basic.tscn")
	var elite_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_elite_brute.tscn")
	var boss_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_boss_overseer.tscn")
	if normal_enemy != null:
		ctx.root.add_child(normal_enemy)
		var normal_bar := normal_enemy.get_node_or_null("HealthBar") as ProgressBar
		ctx.expect(normal_bar != null, "Normal enemy should keep a hit-revealed health bar")
		if normal_bar != null:
			ctx.expect(not normal_bar.visible, "Normal enemy health bar should start hidden")
			normal_enemy.take_damage(1.0)
			ctx.expect(normal_bar.visible, "Normal enemy health bar should show after taking damage")
		ctx.remove_instance(normal_enemy)
	if elite_enemy != null:
		ctx.root.add_child(elite_enemy)
		var elite_bar := elite_enemy.get_node_or_null("HealthBar") as ProgressBar
		ctx.expect(elite_bar != null, "Elite enemy should include a persistent overhead health bar")
		if elite_bar != null:
			ctx.expect(elite_bar.visible, "Elite enemy health bar should be persistent")
		ctx.remove_instance(elite_enemy)
	if boss_enemy != null:
		ctx.root.add_child(boss_enemy)
		var boss_bar := boss_enemy.get_node_or_null("HealthBar") as ProgressBar
		ctx.expect(boss_bar == null or not boss_bar.visible, "Boss overhead health bar should not compete with HUD boss bar")
		ctx.remove_instance(boss_enemy)


func check_base_weapon_parameters_apply_to_profile(ctx) -> void:
	var base_weapon := BaseWeaponData.new()
	base_weapon.attack_range = 520.0
	base_weapon.can_pierce_world = true
	var profile := ModuleApplier.create_shot_profile(base_weapon, {}, {}, {})
	ctx.expect(is_equal_approx(profile.attack_range, 520.0), "BaseWeaponData attack_range should define the base lock-on range")
	ctx.expect(profile.can_pierce_world, "BaseWeaponData can_pierce_world should flow into ShotProfile")
	var character_limited_profile := ModuleApplier.create_shot_profile(base_weapon, {}, {}, {&"attack_range": 480.0})
	ctx.expect(is_equal_approx(character_limited_profile.attack_range, 480.0), "Character attack_range should cap weapon lock-on range when lower")
	var character_long_range_profile := ModuleApplier.create_shot_profile(base_weapon, {}, {}, {&"attack_range": 900.0})
	ctx.expect(is_equal_approx(character_long_range_profile.attack_range, 520.0), "Character attack_range should not erase the weapon base lock-on range when higher")

	var core_bolt = load("res://resources/weapons/core_bolt.tres")
	ctx.expect(core_bolt != null, "Core bolt weapon should load")
	if core_bolt != null:
		ctx.expect(core_bolt.attack_range > 0.0, "Core bolt should configure a finite lock-on range")
		ctx.expect(not core_bolt.can_pierce_world, "Core bolt should not pierce world obstacles by default")


func check_stat_upgrade_applies_to_profile(ctx) -> void:
	var build_state := BuildState.new()
	var base_weapon := BaseWeaponData.new()
	base_weapon.damage = 10.0
	base_weapon.cooldown = 0.5
	base_weapon.projectile_speed = 500.0
	base_weapon.projectile_lifetime = 1.5
	base_weapon.projectile_size = 1.0
	base_weapon.knockback_strength = 100.0
	build_state.base_weapon_data = base_weapon
	build_state.default_fire_mode = null
	build_state.default_payload = null
	ctx.root.add_child(build_state)

	var upgrade_manager := UpgradeManager.new()
	ctx.root.add_child(upgrade_manager)
	upgrade_manager._build_state = build_state

	var option := UpgradeOptionData.new()
	option.upgrade_type = UpgradeOptionData.UpgradeType.STAT
	option.stat_modifiers = {
		&"pierce_count_add": 1,
		&"explosion_radius_add": 28.0,
		&"explosion_damage_mult_add": 0.1,
		&"knockback_add": 35.0,
		&"attack_speed_add": 1.0,
		&"attack_range_add": 120.0,
		&"crit_chance_add": 0.2,
		&"crit_damage_mult_add": 0.4,
		&"luck_add": 0.25,
	}
	var player := PlayerController.new()
	ctx.root.add_child(player)
	upgrade_manager._player = player
	var initial_luck: float = player.get_luck()
	upgrade_manager.apply_upgrade(option)
	var profile = build_state.get_current_shot_profile()

	ctx.expect(profile.pierce_count == 1, "STAT upgrade should add projectile pierce_count")
	ctx.expect(is_equal_approx(profile.explosion_radius, 28.0), "STAT upgrade should add explosion radius")
	ctx.expect(is_equal_approx(profile.explosion_damage_mult, 0.65), "STAT upgrade should add explosion damage multiplier")
	ctx.expect(is_equal_approx(profile.knockback_strength, 135.0), "STAT upgrade should add projectile knockback")
	ctx.expect(is_equal_approx(profile.cooldown, 0.25), "STAT upgrade should apply attack_speed_add")
	ctx.expect(is_equal_approx(profile.attack_range, 900.0), "STAT upgrade should add attack range")
	ctx.expect(is_equal_approx(profile.crit_chance, 0.2), "STAT upgrade should add crit chance")
	ctx.expect(is_equal_approx(profile.crit_damage_mult, 1.9), "STAT upgrade should add crit damage")
	ctx.expect(is_equal_approx(player.get_luck(), initial_luck + 0.25), "STAT upgrade should add player luck for module skill pool")
	ctx.remove_instance(player)
	ctx.remove_instance(upgrade_manager)
	ctx.remove_instance(build_state)


func check_character_stats_apply_to_profile(ctx) -> void:
	var character := CharacterData.new()
	character.attack_speed = 2.0
	character.attack_range = 640.0
	character.crit_chance = 0.35
	character.crit_damage_mult = 1.8

	var build_state := BuildState.new()
	var base_weapon := BaseWeaponData.new()
	base_weapon.cooldown = 0.6
	base_weapon.attack_range = 900.0
	build_state.base_weapon_data = base_weapon
	build_state.default_fire_mode = null
	build_state.default_payload = null
	ctx.root.add_child(build_state)
	build_state.configure_from_character(character)
	var profile = build_state.get_current_shot_profile()

	ctx.expect(is_equal_approx(profile.cooldown, 0.3), "Character attack_speed should reduce shot cooldown")
	ctx.expect(is_equal_approx(profile.attack_range, 640.0), "Character attack_range should apply to shot profile")
	ctx.expect(is_equal_approx(profile.crit_chance, 0.35), "Character crit_chance should apply to shot profile")
	ctx.expect(is_equal_approx(profile.crit_damage_mult, 1.8), "Character crit_damage_mult should apply to shot profile")
	ctx.remove_instance(build_state)


func check_critical_hit_damage(ctx, damage_probe_script) -> void:
	var projectile = ctx.instantiate_scene("res://scenes/weapons/projectile.tscn")
	if projectile == null:
		return

	var target = damage_probe_script.new()
	ctx.root.add_child(projectile)
	ctx.root.add_child(target)
	target.add_to_group("enemies")
	var profile := ShotProfile.new()
	profile.damage = 10.0
	profile.crit_chance = 1.0
	profile.crit_damage_mult = 2.0
	projectile.configure(profile, Vector2.RIGHT)
	HitResolver.resolve_projectile_hit(target, projectile)

	ctx.expect(is_equal_approx(target.damage_taken, 20.0), "Projectile critical hit should multiply damage")
	ctx.remove_instance(target)
	ctx.remove_instance(projectile)


func check_general_upgrade_applies_to_player(ctx) -> void:
	var player := PlayerController.new()
	var xp_manager := XPManager.new()
	player.max_health = 100.0
	ctx.root.add_child(player)
	ctx.root.add_child(xp_manager)
	player.health = 40.0

	var upgrade_manager := UpgradeManager.new()
	ctx.root.add_child(upgrade_manager)
	upgrade_manager._player = player
	upgrade_manager._xp_manager = xp_manager

	var option := UpgradeOptionData.new()
	option.upgrade_type = UpgradeOptionData.UpgradeType.GENERAL
	option.general_modifiers = {
		&"xp_magnet_radius_add": 70.0,
		&"heal_add": 25.0,
		&"move_speed_mult": 1.08,
		&"xp_gain_mult": 1.5,
	}
	var initial_magnet_radius: float = player.get_xp_magnet_radius()
	var initial_move_speed: float = player.get_move_speed()
	upgrade_manager.apply_upgrade(option)
	xp_manager.gain_experience(10)

	ctx.expect(is_equal_approx(player.get_xp_magnet_radius(), initial_magnet_radius + 70.0), "GENERAL upgrade should add player XP magnet radius")
	ctx.expect(is_equal_approx(player.health, 65.0), "GENERAL upgrade should heal player health")
	ctx.expect(player.get_move_speed() > initial_move_speed, "GENERAL upgrade should increase player move speed")
	ctx.expect(is_equal_approx(xp_manager.get_experience_gain_mult(), 1.5), "GENERAL upgrade should increase XP gain multiplier")
	ctx.expect(xp_manager.current_xp == 15, "XPManager should apply XP gain multiplier when gaining experience")
	ctx.remove_instance(upgrade_manager)
	ctx.remove_instance(xp_manager)
	ctx.remove_instance(player)


func check_luck_increases_high_rarity_weight(ctx) -> void:
	var pool := UpgradePoolData.new()
	var common_option := UpgradeOptionData.new()
	common_option.id = &"common_probe"
	common_option.rarity = UpgradeOptionData.Rarity.COMMON
	common_option.weight = 1.0
	var legendary_option := UpgradeOptionData.new()
	legendary_option.id = &"legendary_probe"
	legendary_option.rarity = UpgradeOptionData.Rarity.LEGENDARY
	legendary_option.weight = 1.0

	var player := PlayerController.new()
	player.luck = 1.0
	var upgrade_manager := UpgradeManager.new()
	upgrade_manager.upgrade_pool = pool
	upgrade_manager._option_pool_by_id[common_option.id] = pool
	upgrade_manager._option_pool_by_id[legendary_option.id] = pool
	ctx.root.add_child(player)
	ctx.root.add_child(upgrade_manager)
	upgrade_manager._player = player

	var common_weight: float = upgrade_manager._effective_weight(common_option)
	var legendary_weight: float = upgrade_manager._effective_weight(legendary_option)
	var legendary_without_luck: float = legendary_option.weight * pool.get_rarity_weight(legendary_option.rarity)
	ctx.expect(is_equal_approx(common_weight, pool.common_rarity_weight), "Luck should not increase common upgrade weight")
	ctx.expect(legendary_weight > legendary_without_luck, "Luck should increase legendary upgrade weight")
	ctx.remove_instance(upgrade_manager)
	ctx.remove_instance(player)


func check_wave_table(ctx) -> void:
	var wave_table = load("res://resources/waves/default_wave_table.tres")
	if wave_table == null:
		ctx.failures.append("Failed to load default wave table")
		return

	var entries: Array = wave_table.get("entries")
	ctx.expect(entries.size() >= 3, "Default wave table should have early, mid and late entries")
	var has_basic := false
	var has_fast := false
	var has_tank := false
	var has_swarm := false
	var has_ranged := false
	var has_shield := false
	var previous_start := -1.0
	for entry in entries:
		ctx.expect(entry != null, "Wave table should not contain null entries")
		if entry == null:
			continue
		ctx.expect(entry.start_time > previous_start, "Wave entries should be ordered by start_time")
		ctx.expect(entry.spawn_interval > 0.0, "Wave entry %.0f needs positive spawn_interval" % entry.start_time)
		ctx.expect(entry.spawn_batch_size > 0, "Wave entry %.0f needs positive spawn_batch_size" % entry.start_time)
		ctx.expect(entry.max_alive_enemies >= entry.spawn_batch_size, "Wave entry %.0f max_alive_enemies should cover batch size" % entry.start_time)
		ctx.expect(not entry.enemy_scenes.is_empty(), "Wave entry %.0f needs enemy scenes" % entry.start_time)
		ctx.expect(entry.spawn_batch_size <= 6, "Wave entry %.0f spawn_batch_size should stay readable" % entry.start_time)
		ctx.expect(entry.max_alive_enemies <= 48, "Wave entry %.0f max_alive_enemies should stay within early-run pressure budget" % entry.start_time)
		for enemy_scene in entry.enemy_scenes:
			ctx.expect(enemy_scene != null, "Wave entry %.0f should not contain null enemy scenes" % entry.start_time)
			if enemy_scene == load("res://scenes/enemies/enemy_basic.tscn"):
				has_basic = true
			elif enemy_scene == load("res://scenes/enemies/enemy_fast.tscn"):
				has_fast = true
			elif enemy_scene == load("res://scenes/enemies/enemy_tank.tscn"):
				has_tank = true
			elif enemy_scene == load("res://scenes/enemies/enemy_swarm.tscn"):
				has_swarm = true
			elif enemy_scene == load("res://scenes/enemies/enemy_ranged.tscn"):
				has_ranged = true
			elif enemy_scene == load("res://scenes/enemies/enemy_shield.tscn"):
				has_shield = true
		previous_start = entry.start_time
	ctx.expect(has_basic, "Default wave table should include basic enemies")
	ctx.expect(has_fast, "Default wave table should include fast enemies")
	ctx.expect(has_tank, "Default wave table should include tank enemies")
	ctx.expect(has_swarm, "Default wave table should include swarm enemies")
	ctx.expect(has_ranged, "Default wave table should include ranged pressure enemies")
	ctx.expect(has_shield, "Default wave table should include shield enemies")


func check_run_tuning(ctx) -> void:
	var run_tuning = load("res://resources/runs/default_run_tuning.tres")
	if run_tuning == null:
		ctx.failures.append("Failed to load default run tuning")
		return

	ctx.expect(run_tuning.spawn_interval > 0.0, "Run tuning needs positive spawn_interval")
	ctx.expect(run_tuning.spawn_radius > 0.0, "Run tuning needs positive spawn_radius")
	ctx.expect(run_tuning.minimum_spawn_distance > 0.0, "Run tuning needs positive minimum_spawn_distance")
	ctx.expect(run_tuning.minimum_spawn_distance < run_tuning.spawn_radius, "Run tuning minimum_spawn_distance should leave spawn ring space")
	ctx.expect(run_tuning.spawn_batch_size > 0, "Run tuning needs positive spawn_batch_size")
	ctx.expect(run_tuning.max_alive_enemies >= run_tuning.spawn_batch_size, "Run tuning max_alive_enemies should cover batch size")


func check_run_objective(ctx, special_enemy_check_fn: Callable) -> void:
	var objective = load("res://resources/runs/default_run_objective.tres")
	if objective == null:
		ctx.failures.append("Failed to load default run objective")
		return

	var has_elite := false
	var has_boss := false
	var previous_time := -1.0
	var events: Array = objective.get("events")
	for event in events:
		ctx.expect(event != null, "Run objective should not contain null events")
		if event == null:
			continue
		var trigger_time := float(event.get("trigger_time"))
		ctx.expect(trigger_time > previous_time, "Run objective events should be ordered by trigger_time")
		ctx.expect(event.get("enemy_scene") != null, "Run objective event %s needs enemy_scene" % event.get("id"))
		ctx.expect(int(event.get("spawn_count")) > 0, "Run objective event %s needs positive spawn_count" % event.get("id"))
		if int(event.get("event_type")) == 0:
			has_elite = true
		if int(event.get("event_type")) == 1:
			has_boss = true
		previous_time = trigger_time
	ctx.expect(has_elite, "Run objective should include an elite event")
	ctx.expect(has_boss, "Run objective should include a boss event")

	special_enemy_check_fn.call("res://scenes/enemies/enemy_elite_brute.tscn", false)
	special_enemy_check_fn.call("res://scenes/enemies/enemy_boss_overseer.tscn", true)

	var run_manager_source := FileAccess.get_file_as_string("res://scripts/run/run_manager.gd")
	ctx.expect(run_manager_source.find("run_objective") >= 0, "RunManager should read run objective resource")
	ctx.expect(run_manager_source.find("show_victory") >= 0, "RunManager should show victory after boss objective")


func check_spawn_manager_is_resource_driven(ctx) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/run/spawn_manager.gd")
	ctx.expect(source.find("@export var enemy_scenes") == -1, "SpawnManager should read enemy scenes from wave resources")
	ctx.expect(source.find("res://scenes/enemies/enemy_basic.tscn") == -1, "SpawnManager should not hardcode basic enemy scene")
	ctx.expect(source.find("res://scenes/enemies/enemy_fast.tscn") == -1, "SpawnManager should not hardcode fast enemy scene")
	ctx.expect(source.find("res://scenes/enemies/enemy_tank.tscn") == -1, "SpawnManager should not hardcode tank enemy scene")
	ctx.expect(source.find("spawn_enemy_scene") >= 0, "SpawnManager should expose resource-driven special enemy spawning")


func check_script_text_boundaries(ctx) -> void:
	for path in [
		"res://scripts/ui/hud_controller.gd",
		"res://scripts/ui/level_up_panel_controller.gd",
		"res://scripts/ui/upgrade_card.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		ctx.expect(source.find("GameText") >= 0, "%s should use GameText for player-visible text" % path)


func check_upgrade_card_uses_game_text(ctx, game_text) -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/upgrade_card.gd")
	ctx.expect(source.find("GameText.upgrade_card") >= 0, "upgrade_card.gd should render option text through GameText.upgrade_card")
	ctx.expect(source.find("GameText.upgrade_card_source") >= 0, "upgrade_card.gd should render upgrade source through GameText")
	ctx.expect(source.find("max_module_count") >= 0, "upgrade_card.gd should receive module cap instead of hardcoding it")

	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/level_up_panel_controller.gd")
	ctx.expect(panel_source.find("max_module_count") >= 0, "LevelUpPanel should pass configured module cap into cards")

	var upgrade_manager_source := FileAccess.get_file_as_string("res://scripts/progression/upgrade_manager.gd")
	ctx.expect(upgrade_manager_source.find("get_module_limit") >= 0, "UpgradeManager should expose resource-driven module cap for UI")
	ctx.expect(upgrade_manager_source.find("can_acquire_module(3") == -1, "UpgradeManager should not hardcode module cap")
	ctx.expect(upgrade_manager_source.find("return upgrade_pool") >= 0, "UpgradeManager should read module cap from the module install pool")

	var pool_data_source := FileAccess.get_file_as_string("res://resources/upgrades/upgrade_pool_data.gd")
	ctx.expect(pool_data_source.find("max_module_count: int = 3") == -1, "UpgradePoolData should not hardcode the default module cap")

	var module_option := UpgradeOptionData.new()
	module_option.upgrade_type = UpgradeOptionData.UpgradeType.MODULE
	var module_source: String = game_text.upgrade_card_source(module_option, 5)
	ctx.expect(module_source.find("新模块") >= 0, "Module upgrade card source should identify new module options")
	ctx.expect(module_source.find("5") >= 0, "Module upgrade card source should include configured module cap")

	var stat_option := UpgradeOptionData.new()
	stat_option.upgrade_type = UpgradeOptionData.UpgradeType.STAT
	ctx.expect(game_text.upgrade_card_source(stat_option).find("模块强化") >= 0, "Stat upgrade card source should identify module skill options")

	var general_option := UpgradeOptionData.new()
	general_option.upgrade_type = UpgradeOptionData.UpgradeType.GENERAL
	ctx.expect(game_text.upgrade_card_source(general_option).find("通用技能") >= 0, "General upgrade card source should identify general skill options")

	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud_controller.gd")
	ctx.expect(hud_source.find("GameText.hud_character") >= 0, "hud_controller.gd should render character text through GameText.hud_character")
