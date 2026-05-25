extends SceneTree

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const DashEnemySkillDataScript = preload("res://resources/enemies/skills/dash_enemy_skill_data.gd")
const GameText = preload("res://scripts/ui/game_text.gd")
const SanityContextScript = preload("res://scripts/dev/sanity_context.gd")
const WorldMapChecksScript = preload("res://scripts/dev/world_map_checks.gd")
const ProgressionChecksScript = preload("res://scripts/dev/progression_checks.gd")
const EnemyCombatChecksScript = preload("res://scripts/dev/enemy_combat_checks.gd")
const ENEMY_BEHAVIOR_PRESSURE := 2
const ENEMY_BEHAVIOR_SHIELD := 3

class DamageProbe:
	extends Node2D

	var damage_taken: float = 0.0

	func take_damage(amount: float) -> void:
		damage_taken += amount

	func apply_hit_reaction(_push_direction: Vector2, _force: float) -> void:
		pass

var _failures: Array[String] = []
var _removed_xp_movement_key := "xp_magnet" + "_speed"
var _world_map_checks = WorldMapChecksScript.new()
var _progression_checks = ProgressionChecksScript.new()
var _enemy_combat_checks = EnemyCombatChecksScript.new()


func _ctx():
	return SanityContextScript.new(self, root, _failures, _removed_xp_movement_key)


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_collision_scene("res://scenes/player/player.tscn", CollisionLayers.PLAYER, CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/enemies/enemy_basic.tscn", CollisionLayers.ENEMY, CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/enemies/enemy_fast.tscn", CollisionLayers.ENEMY, CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/enemies/enemy_tank.tscn", CollisionLayers.ENEMY, CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/enemies/enemy_elite_brute.tscn", CollisionLayers.ENEMY, CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/enemies/enemy_boss_overseer.tscn", CollisionLayers.ENEMY, CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/weapons/projectile.tscn", CollisionLayers.PROJECTILE, CollisionLayers.ENEMY | CollisionLayers.WORLD)
	_check_collision_scene("res://scenes/pickups/xp_pickup.tscn", CollisionLayers.PICKUP, CollisionLayers.PLAYER)
	_check_xp_pickup_magnet_is_player_driven()
	_check_arena_bounds_scene()
	_check_arena_visual_scene()
	_check_arena_hazards()
	_check_world_resource_grouping()
	_check_default_map_data()
	_check_default_map_tile_library()
	_check_game_root_scene()
	_check_combat_feedback_resource()
	_check_combat_feedback_readability_hooks()
	_check_projectile_single_target_hit()
	_check_projectile_explosion_damage_multiplier()
	_check_projectile_world_collision_rules()
	_check_enemy_soft_separation()
	_check_enemy_obstacle_navigation()
	_check_enemy_obstacle_escape_navigation_hooks()
	_check_enemy_skill_executor_split()
	_check_enemy_behavior_executor_split()
	_check_boss_wide_body_navigation_and_state()
	_check_health_bar_ui()
	_check_hud_run_objective_ui()
	_check_boss_health_bar_ui()
	_check_enemy_health_bar_rules()
	_check_enemy_behavior_variants()
	_check_base_weapon_parameters_apply_to_profile()
	_check_stat_upgrade_applies_to_profile()
	_check_character_stats_apply_to_profile()
	_check_critical_hit_damage()
	_check_general_upgrade_applies_to_player()
	_check_luck_increases_high_rarity_weight()
	_check_default_character_resource()
	_check_default_character_pool()
	_check_upgrade_pool()
	_check_module_skill_pool()
	_check_general_skill_pool()
	_check_upgrade_resource_grouping()
	_check_upgrade_filtering_rules()
	_check_upgrade_pool_decoupling()
	_check_run_tuning()
	_check_map_documentation()
	_check_legacy_paths_removed()
	_check_run_objective()
	_check_wave_table()
	_check_enemy_templates_and_pool_variety()
	_check_spawn_manager_is_resource_driven()
	_check_script_text_boundaries()
	_check_upgrade_card_uses_game_text()
	_finish()


func _check_collision_scene(scene_path: String, expected_layer: int, expected_mask: int) -> void:
	var instance := _instantiate_scene(scene_path)
	if instance == null:
		return

	root.add_child(instance)
	var collision_object := instance as CollisionObject2D
	if collision_object == null:
		_failures.append("%s root is not CollisionObject2D" % scene_path)
	else:
		_expect(collision_object.collision_layer == expected_layer, "%s collision_layer expected %d got %d" % [scene_path, expected_layer, collision_object.collision_layer])
		_expect(collision_object.collision_mask == expected_mask, "%s collision_mask expected %d got %d" % [scene_path, expected_mask, collision_object.collision_mask])
	_remove_instance(instance)


func _check_arena_bounds_scene() -> void:
	_world_map_checks.call("check_arena_bounds_scene", _ctx(), CollisionLayers)


func _check_arena_visual_scene() -> void:
	_world_map_checks.call("check_arena_visual_scene", _ctx(), CollisionLayers)


func _check_arena_hazards() -> void:
	_world_map_checks.call("check_arena_hazards", _ctx(), CollisionLayers)


func _check_world_resource_grouping() -> void:
	_world_map_checks.call("check_world_resource_grouping", _ctx())


func _check_default_map_data() -> void:
	_world_map_checks.call("check_default_map_data", _ctx())


func _check_default_map_tile_library() -> void:
	_world_map_checks.call("check_default_map_tile_library", _ctx())


func _check_game_root_scene() -> void:
	_world_map_checks.call("check_game_root_scene", _ctx())


func _check_special_enemy_scene(scene_path: String, expects_boss: bool) -> void:
	_enemy_combat_checks.call("check_special_enemy_scene", _ctx(), scene_path, expects_boss)


func _check_combat_feedback_resource() -> void:
	_enemy_combat_checks.call("check_combat_feedback_resource", _ctx())


func _check_combat_feedback_readability_hooks() -> void:
	_enemy_combat_checks.call("check_combat_feedback_readability_hooks", _ctx())


func _check_xp_pickup_magnet_is_player_driven() -> void:
	var pickup_source := FileAccess.get_file_as_string("res://scripts/progression/xp_pickup_controller.gd")
	_expect(pickup_source.find("get_xp_magnet_radius") >= 0, "XP pickup should read magnet radius from PlayerController")
	_expect(pickup_source.find("get_" + _removed_xp_movement_key) == -1, "XP pickup should not read removed XP magnet movement stat from PlayerController")
	_expect(pickup_source.find("DEFAULT_MAGNET_PULL_RATE") >= 0, "XP pickup should use one internal default pull value")
	_expect(pickup_source.find("_age >= lifetime") == -1, "XP pickup should not auto-collect by lifetime")

	var player_source := FileAccess.get_file_as_string("res://scripts/player/player_controller.gd")
	_expect(player_source.find("@export var xp_magnet_radius") >= 0, "PlayerController should expose per-character XP magnet radius")
	_expect(player_source.find(_removed_xp_movement_key) == -1, "PlayerController should not expose removed XP magnet movement stat")
	_expect(player_source.find("xp_magnet_radius_add") >= 0, "PlayerController should support general upgrade XP magnet radius modifiers")

	var run_tuning_source := FileAccess.get_file_as_string("res://resources/runs/run_tuning_data.gd")
	var default_run_tuning_source := FileAccess.get_file_as_string("res://resources/runs/default_run_tuning.tres")
	_expect(run_tuning_source.find("pickup_magnet_radius") == -1, "Run tuning should not configure XP magnet radius")
	_expect(run_tuning_source.find("pickup_lifetime") == -1, "Run tuning should not configure XP lifetime")
	_expect(default_run_tuning_source.find("pickup_magnet_radius") == -1, "Default run tuning should not store XP magnet radius")
	_expect(default_run_tuning_source.find("pickup_lifetime") == -1, "Default run tuning should not store XP lifetime")

	var player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	var pickup := _instantiate_scene("res://scenes/pickups/xp_pickup.tscn") as XPPickupController
	if player == null or pickup == null:
		return

	var collected := [false]
	pickup.collected.connect(func(_amount: int) -> void: collected[0] = true)
	player.global_position = Vector2.ZERO
	pickup.global_position = Vector2(player.get_xp_magnet_radius() - 10.0, 0.0)
	var initial_distance := pickup.global_position.distance_to(player.global_position)
	root.add_child(player)
	root.add_child(pickup)
	pickup._physics_process(0.1)
	var final_distance := pickup.global_position.distance_to(player.global_position)
	_expect(final_distance < initial_distance, "XP pickup should magnet toward the player inside player magnet radius")
	_expect(not bool(collected[0]), "XP pickup should persist until player collision")
	_expect(not pickup.is_queued_for_deletion(), "XP pickup should not queue_free without player collision")
	_remove_instance(pickup)
	_remove_instance(player)


func _check_projectile_single_target_hit() -> void:
	_enemy_combat_checks.call("check_projectile_single_target_hit", _ctx(), DamageProbe)


func _check_projectile_explosion_damage_multiplier() -> void:
	_enemy_combat_checks.call("check_projectile_explosion_damage_multiplier", _ctx(), DamageProbe)


func _check_projectile_world_collision_rules() -> void:
	_enemy_combat_checks.call("check_projectile_world_collision_rules", _ctx(), CollisionLayers)


func _check_enemy_soft_separation() -> void:
	_enemy_combat_checks.call("check_enemy_soft_separation", _ctx())


func _check_enemy_obstacle_navigation() -> void:
	_enemy_combat_checks.call("check_enemy_obstacle_navigation", _ctx(), CollisionLayers)


func _check_enemy_obstacle_escape_navigation_hooks() -> void:
	_enemy_combat_checks.call("check_enemy_obstacle_escape_navigation_hooks", _ctx())


func _check_enemy_skill_executor_split() -> void:
	_enemy_combat_checks.call("check_enemy_skill_executor_split", _ctx())


func _check_enemy_behavior_executor_split() -> void:
	_enemy_combat_checks.call("check_enemy_behavior_executor_split", _ctx())


func _check_boss_wide_body_navigation_and_state() -> void:
	_enemy_combat_checks.call("check_boss_wide_body_navigation_and_state", _ctx(), DashEnemySkillDataScript, CollisionLayers)


func _check_health_bar_ui() -> void:
	var hud := _instantiate_scene("res://scenes/ui/hud.tscn")
	if hud != null:
		root.add_child(hud)
		var character_label := hud.get_node_or_null("%CharacterLabel") as Label
		_expect(character_label != null, "HUD should include a player character Label")
		var health_bar := hud.get_node_or_null("%HealthBar") as ProgressBar
		_expect(health_bar != null, "HUD should include a player health ProgressBar")
		if health_bar != null:
			_expect(not health_bar.show_percentage, "HUD health bar should hide percentage text")
		_remove_instance(hud)

	for scene_path in [
		"res://scenes/enemies/enemy_basic.tscn",
		"res://scenes/enemies/enemy_fast.tscn",
		"res://scenes/enemies/enemy_tank.tscn",
	]:
		var enemy := _instantiate_scene(scene_path)
		if enemy == null:
			continue
		root.add_child(enemy)
		var enemy_health_bar := enemy.get_node_or_null("HealthBar") as ProgressBar
		_expect(enemy_health_bar != null, "%s should include an enemy health ProgressBar" % scene_path)
		if enemy_health_bar != null:
			_expect(not enemy_health_bar.show_percentage, "%s enemy health bar should hide percentage text" % scene_path)
		_remove_instance(enemy)


func _check_hud_run_objective_ui() -> void:
	var hud := _instantiate_scene("res://scenes/ui/hud.tscn") as HUDController
	if hud == null:
		return

	root.add_child(hud)
	_expect(hud.get_node_or_null("%RunTimeLabel") != null, "HUD should include a run time Label")
	_expect(hud.get_node_or_null("%ObjectiveLabel") != null, "HUD should include a run objective Label")
	_expect(hud.get_node_or_null("%NextEventLabel") != null, "HUD should include a next objective event Label")

	var objective := load("res://resources/runs/default_run_objective.tres")
	hud.update_run_status(12.0, objective)
	var run_time_label := hud.get_node_or_null("%RunTimeLabel") as Label
	var objective_label := hud.get_node_or_null("%ObjectiveLabel") as Label
	var next_event_label := hud.get_node_or_null("%NextEventLabel") as Label
	if run_time_label != null:
		_expect(run_time_label.text.find("00:12") >= 0, "HUD run time should render elapsed time")
	if objective_label != null:
		_expect(objective_label.text.find("目标") >= 0, "HUD objective text should explain the run objective")
	if next_event_label != null:
		_expect(next_event_label.text.find("精英") >= 0, "HUD next event should describe the first elite event")
		_expect(next_event_label.text.find(GameText.format_time(58.0)) >= 0, "HUD next event should show remaining time")

	hud.update_run_status(181.0, objective)
	if next_event_label != null:
		_expect(next_event_label.text.find("Boss") >= 0 or next_event_label.text.find("压制核心") >= 0, "HUD next event should keep boss pressure visible after boss spawn")
	_remove_instance(hud)


func _check_boss_health_bar_ui() -> void:
	var hud := _instantiate_scene("res://scenes/ui/hud.tscn") as HUDController
	if hud == null:
		return

	root.add_child(hud)
	var status_panel := hud.get_node_or_null("Root/StatusPanel")
	_expect(status_panel != null, "HUD player status should be anchored in the upper-left StatusPanel")
	var old_center_margin := hud.get_node_or_null("Root/MarginContainer")
	_expect(old_center_margin == null, "HUD should not keep player status in a centered MarginContainer")

	var boss_panel := hud.get_node_or_null("%BossHealthPanel") as Control
	var boss_bar := hud.get_node_or_null("%BossHealthBar") as ProgressBar
	var boss_label := hud.get_node_or_null("%BossHealthLabel") as Label
	_expect(boss_panel != null, "HUD should include a top-center BossHealthPanel")
	_expect(boss_bar != null, "HUD should include a BossHealthBar")
	_expect(boss_label != null, "HUD should include a BossHealthLabel")
	if boss_panel != null:
		_expect(not boss_panel.visible, "Boss health panel should start hidden")

	var boss := _instantiate_scene("res://scenes/enemies/enemy_boss_overseer.tscn") as EnemyController
	if boss != null:
		root.add_child(boss)
		_expect(hud.has_method("track_boss"), "HUD should expose track_boss for boss health UI")
		if hud.has_method("track_boss"):
			hud.track_boss(boss)
		if boss_panel != null:
			_expect(boss_panel.visible, "Boss health panel should show while tracking boss")
		if boss_bar != null:
			_expect(is_equal_approx(boss_bar.max_value, boss.get_max_health()), "Boss health bar max should use boss health")
		boss.take_damage(10.0)
		if boss_bar != null:
			_expect(is_equal_approx(boss_bar.value, boss.health), "Boss health bar should update from boss health signal")
		_remove_instance(boss)
	_remove_instance(hud)


func _check_enemy_health_bar_rules() -> void:
	var normal_enemy := _instantiate_scene("res://scenes/enemies/enemy_basic.tscn") as EnemyController
	var elite_enemy := _instantiate_scene("res://scenes/enemies/enemy_elite_brute.tscn") as EnemyController
	var boss_enemy := _instantiate_scene("res://scenes/enemies/enemy_boss_overseer.tscn") as EnemyController
	if normal_enemy != null:
		root.add_child(normal_enemy)
		var normal_bar := normal_enemy.get_node_or_null("HealthBar") as ProgressBar
		_expect(normal_bar != null, "Normal enemy should keep a hit-revealed health bar")
		if normal_bar != null:
			_expect(not normal_bar.visible, "Normal enemy health bar should start hidden")
			normal_enemy.take_damage(1.0)
			_expect(normal_bar.visible, "Normal enemy health bar should show after taking damage")
		_remove_instance(normal_enemy)
	if elite_enemy != null:
		root.add_child(elite_enemy)
		var elite_bar := elite_enemy.get_node_or_null("HealthBar") as ProgressBar
		_expect(elite_bar != null, "Elite enemy should include a persistent overhead health bar")
		if elite_bar != null:
			_expect(elite_bar.visible, "Elite enemy health bar should be persistent")
		_remove_instance(elite_enemy)
	if boss_enemy != null:
		root.add_child(boss_enemy)
		var boss_bar := boss_enemy.get_node_or_null("HealthBar") as ProgressBar
		_expect(boss_bar == null or not boss_bar.visible, "Boss overhead health bar should not compete with HUD boss bar")
		_remove_instance(boss_enemy)


func _check_enemy_behavior_variants() -> void:
	_enemy_combat_checks.call("check_enemy_behavior_variants", _ctx(), ENEMY_BEHAVIOR_PRESSURE, ENEMY_BEHAVIOR_SHIELD)


func _check_base_weapon_parameters_apply_to_profile() -> void:
	var base_weapon := BaseWeaponData.new()
	base_weapon.attack_range = 520.0
	base_weapon.can_pierce_world = true
	var profile := ModuleApplier.create_shot_profile(base_weapon, {}, {}, {})
	_expect(is_equal_approx(profile.attack_range, 520.0), "BaseWeaponData attack_range should define the base lock-on range")
	_expect(profile.can_pierce_world, "BaseWeaponData can_pierce_world should flow into ShotProfile")
	var character_limited_profile := ModuleApplier.create_shot_profile(base_weapon, {}, {}, {&"attack_range": 480.0})
	_expect(is_equal_approx(character_limited_profile.attack_range, 480.0), "Character attack_range should cap weapon lock-on range when lower")
	var character_long_range_profile := ModuleApplier.create_shot_profile(base_weapon, {}, {}, {&"attack_range": 900.0})
	_expect(is_equal_approx(character_long_range_profile.attack_range, 520.0), "Character attack_range should not erase the weapon base lock-on range when higher")

	var core_bolt := load("res://resources/weapons/core_bolt.tres") as BaseWeaponData
	_expect(core_bolt != null, "Core bolt weapon should load")
	if core_bolt != null:
		_expect(core_bolt.attack_range > 0.0, "Core bolt should configure a finite lock-on range")
		_expect(not core_bolt.can_pierce_world, "Core bolt should not pierce world obstacles by default")


func _check_stat_upgrade_applies_to_profile() -> void:
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
	root.add_child(build_state)

	var upgrade_manager := UpgradeManager.new()
	root.add_child(upgrade_manager)
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
	root.add_child(player)
	upgrade_manager._player = player
	var initial_luck := player.get_luck()
	upgrade_manager.apply_upgrade(option)
	var profile := build_state.get_current_shot_profile()

	_expect(profile.pierce_count == 1, "STAT upgrade should add projectile pierce_count")
	_expect(is_equal_approx(profile.explosion_radius, 28.0), "STAT upgrade should add explosion radius")
	_expect(is_equal_approx(profile.explosion_damage_mult, 0.65), "STAT upgrade should add explosion damage multiplier")
	_expect(is_equal_approx(profile.knockback_strength, 135.0), "STAT upgrade should add projectile knockback")
	_expect(is_equal_approx(profile.cooldown, 0.25), "STAT upgrade should apply attack_speed_add")
	_expect(is_equal_approx(profile.attack_range, 900.0), "STAT upgrade should add attack range")
	_expect(is_equal_approx(profile.crit_chance, 0.2), "STAT upgrade should add crit chance")
	_expect(is_equal_approx(profile.crit_damage_mult, 1.9), "STAT upgrade should add crit damage")
	_expect(is_equal_approx(player.get_luck(), initial_luck + 0.25), "STAT upgrade should add player luck for module skill pool")
	_remove_instance(player)
	_remove_instance(upgrade_manager)
	_remove_instance(build_state)


func _check_character_stats_apply_to_profile() -> void:
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
	root.add_child(build_state)
	build_state.configure_from_character(character)
	var profile := build_state.get_current_shot_profile()

	_expect(is_equal_approx(profile.cooldown, 0.3), "Character attack_speed should reduce shot cooldown")
	_expect(is_equal_approx(profile.attack_range, 640.0), "Character attack_range should apply to shot profile")
	_expect(is_equal_approx(profile.crit_chance, 0.35), "Character crit_chance should apply to shot profile")
	_expect(is_equal_approx(profile.crit_damage_mult, 1.8), "Character crit_damage_mult should apply to shot profile")
	_remove_instance(build_state)


func _check_critical_hit_damage() -> void:
	var projectile := _instantiate_scene("res://scenes/weapons/projectile.tscn") as ProjectileController
	if projectile == null:
		return

	var target := DamageProbe.new()
	root.add_child(projectile)
	root.add_child(target)
	target.add_to_group("enemies")
	var profile := ShotProfile.new()
	profile.damage = 10.0
	profile.crit_chance = 1.0
	profile.crit_damage_mult = 2.0
	projectile.configure(profile, Vector2.RIGHT)
	HitResolver.resolve_projectile_hit(target, projectile)

	_expect(is_equal_approx(target.damage_taken, 20.0), "Projectile critical hit should multiply damage")
	_remove_instance(target)
	_remove_instance(projectile)


func _check_general_upgrade_applies_to_player() -> void:
	var player := PlayerController.new()
	var xp_manager := XPManager.new()
	player.max_health = 100.0
	root.add_child(player)
	root.add_child(xp_manager)
	player.health = 40.0

	var upgrade_manager := UpgradeManager.new()
	root.add_child(upgrade_manager)
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
	var initial_magnet_radius := player.get_xp_magnet_radius()
	var initial_move_speed := player.get_move_speed()
	upgrade_manager.apply_upgrade(option)
	xp_manager.gain_experience(10)

	_expect(is_equal_approx(player.get_xp_magnet_radius(), initial_magnet_radius + 70.0), "GENERAL upgrade should add player XP magnet radius")
	_expect(is_equal_approx(player.health, 65.0), "GENERAL upgrade should heal player health")
	_expect(player.get_move_speed() > initial_move_speed, "GENERAL upgrade should increase player move speed")
	_expect(is_equal_approx(xp_manager.get_experience_gain_mult(), 1.5), "GENERAL upgrade should increase XP gain multiplier")
	_expect(xp_manager.current_xp == 15, "XPManager should apply XP gain multiplier when gaining experience")
	_remove_instance(upgrade_manager)
	_remove_instance(xp_manager)
	_remove_instance(player)


func _check_luck_increases_high_rarity_weight() -> void:
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
	root.add_child(player)
	root.add_child(upgrade_manager)
	upgrade_manager._player = player

	var common_weight := upgrade_manager._effective_weight(common_option)
	var legendary_weight := upgrade_manager._effective_weight(legendary_option)
	var legendary_without_luck := legendary_option.weight * pool.get_rarity_weight(legendary_option.rarity)
	_expect(is_equal_approx(common_weight, pool.common_rarity_weight), "Luck should not increase common upgrade weight")
	_expect(legendary_weight > legendary_without_luck, "Luck should increase legendary upgrade weight")
	_remove_instance(upgrade_manager)
	_remove_instance(player)


func _check_default_character_resource() -> void:
	_progression_checks.call("check_default_character_resource", _ctx())


func _check_default_character_pool() -> void:
	_progression_checks.call("check_default_character_pool", _ctx())


func _check_character_fields(character: Resource, label: String) -> void:
	_expect(character.get("id") != &"", "%s needs id" % label)
	_expect(character.get("display_name") != "", "%s needs Chinese display_name" % label)
	_expect(character.get("description") != "", "%s needs Chinese description" % label)
	_expect(float(character.get("move_speed")) > 0.0, "%s needs positive move_speed" % label)
	_expect(float(character.get("max_health")) > 0.0, "%s needs positive max_health" % label)
	_expect(float(character.get("xp_magnet_radius")) > 0.0, "%s needs positive xp_magnet_radius" % label)
	_expect(character.get(_removed_xp_movement_key) == null, "%s should not expose removed XP magnet movement stat" % label)
	_expect(float(character.get("luck")) >= 0.0, "%s needs non-negative luck" % label)
	_expect(float(character.get("attack_speed")) > 0.0, "%s needs positive attack_speed" % label)
	_expect(float(character.get("attack_range")) > 0.0, "%s needs positive attack_range" % label)
	_expect(float(character.get("crit_chance")) >= 0.0, "%s needs non-negative crit_chance" % label)
	_expect(float(character.get("crit_damage_mult")) >= 1.0, "%s needs crit_damage_mult >= 1.0" % label)
	_expect(character.get("starting_fire_module") != null, "%s should reserve starting_fire_module" % label)
	_expect(character.get("starting_payload_module") != null, "%s should reserve starting_payload_module" % label)


func _check_upgrade_pool() -> void:
	_progression_checks.call("check_upgrade_pool", _ctx())


func _check_module_skill_pool() -> void:
	_progression_checks.call("check_module_skill_pool", _ctx())


func _check_general_skill_pool() -> void:
	_progression_checks.call("check_general_skill_pool", _ctx(), Callable(self, "_has_module_skill_stat"))


func _check_upgrade_resource_grouping() -> void:
	_progression_checks.call("check_upgrade_resource_grouping", _ctx())


func _check_upgrade_filtering_rules() -> void:
	_progression_checks.call("check_upgrade_filtering_rules", _ctx(), Callable(self, "_find_upgrade_option"))


func _check_upgrade_pool_decoupling() -> void:
	_progression_checks.call("check_upgrade_pool_decoupling", _ctx())



func _check_wave_table() -> void:
	var wave_table := load("res://resources/waves/default_wave_table.tres")
	if wave_table == null:
		_failures.append("Failed to load default wave table")
		return

	var entries: Array = wave_table.get("entries")
	_expect(entries.size() >= 3, "Default wave table should have early, mid and late entries")
	var has_basic := false
	var has_fast := false
	var has_tank := false
	var has_swarm := false
	var has_ranged := false
	var has_shield := false
	var previous_start := -1.0
	for entry in entries:
		_expect(entry != null, "Wave table should not contain null entries")
		if entry == null:
			continue
		_expect(entry.start_time > previous_start, "Wave entries should be ordered by start_time")
		_expect(entry.spawn_interval > 0.0, "Wave entry %.0f needs positive spawn_interval" % entry.start_time)
		_expect(entry.spawn_batch_size > 0, "Wave entry %.0f needs positive spawn_batch_size" % entry.start_time)
		_expect(entry.max_alive_enemies >= entry.spawn_batch_size, "Wave entry %.0f max_alive_enemies should cover batch size" % entry.start_time)
		_expect(not entry.enemy_scenes.is_empty(), "Wave entry %.0f needs enemy scenes" % entry.start_time)
		_expect(entry.spawn_batch_size <= 6, "Wave entry %.0f spawn_batch_size should stay readable" % entry.start_time)
		_expect(entry.max_alive_enemies <= 48, "Wave entry %.0f max_alive_enemies should stay within early-run pressure budget" % entry.start_time)
		for enemy_scene in entry.enemy_scenes:
			_expect(enemy_scene != null, "Wave entry %.0f should not contain null enemy scenes" % entry.start_time)
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
	_expect(has_basic, "Default wave table should include basic enemies")
	_expect(has_fast, "Default wave table should include fast enemies")
	_expect(has_tank, "Default wave table should include tank enemies")
	_expect(has_swarm, "Default wave table should include swarm enemies")
	_expect(has_ranged, "Default wave table should include ranged pressure enemies")
	_expect(has_shield, "Default wave table should include shield enemies")


func _check_enemy_templates_and_pool_variety() -> void:
	_enemy_combat_checks.call("check_enemy_templates_and_pool_variety", _ctx())


func _check_run_tuning() -> void:
	var run_tuning := load("res://resources/runs/default_run_tuning.tres")
	if run_tuning == null:
		_failures.append("Failed to load default run tuning")
		return

	_expect(run_tuning.spawn_interval > 0.0, "Run tuning needs positive spawn_interval")
	_expect(run_tuning.spawn_radius > 0.0, "Run tuning needs positive spawn_radius")
	_expect(run_tuning.minimum_spawn_distance > 0.0, "Run tuning needs positive minimum_spawn_distance")
	_expect(run_tuning.minimum_spawn_distance < run_tuning.spawn_radius, "Run tuning minimum_spawn_distance should leave spawn ring space")
	_expect(run_tuning.spawn_batch_size > 0, "Run tuning needs positive spawn_batch_size")
	_expect(run_tuning.max_alive_enemies >= run_tuning.spawn_batch_size, "Run tuning max_alive_enemies should cover batch size")


func _check_map_documentation() -> void:
	_world_map_checks.call("check_map_documentation", _ctx())


func _check_legacy_paths_removed() -> void:
	_world_map_checks.call("check_legacy_paths_removed", _ctx())


func _check_run_objective() -> void:
	var objective := load("res://resources/runs/default_run_objective.tres")
	if objective == null:
		_failures.append("Failed to load default run objective")
		return

	var has_elite := false
	var has_boss := false
	var previous_time := -1.0
	var events: Array = objective.get("events")
	for event in events:
		_expect(event != null, "Run objective should not contain null events")
		if event == null:
			continue
		var trigger_time := float(event.get("trigger_time"))
		_expect(trigger_time > previous_time, "Run objective events should be ordered by trigger_time")
		_expect(event.get("enemy_scene") != null, "Run objective event %s needs enemy_scene" % event.get("id"))
		_expect(int(event.get("spawn_count")) > 0, "Run objective event %s needs positive spawn_count" % event.get("id"))
		if int(event.get("event_type")) == 0:
			has_elite = true
		if int(event.get("event_type")) == 1:
			has_boss = true
		previous_time = trigger_time
	_expect(has_elite, "Run objective should include an elite event")
	_expect(has_boss, "Run objective should include a boss event")

	_check_special_enemy_scene("res://scenes/enemies/enemy_elite_brute.tscn", false)
	_check_special_enemy_scene("res://scenes/enemies/enemy_boss_overseer.tscn", true)

	var run_manager_source := FileAccess.get_file_as_string("res://scripts/run/run_manager.gd")
	_expect(run_manager_source.find("run_objective") >= 0, "RunManager should read run objective resource")
	_expect(run_manager_source.find("show_victory") >= 0, "RunManager should show victory after boss objective")


func _check_spawn_manager_is_resource_driven() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/run/spawn_manager.gd")
	_expect(source.find("@export var enemy_scenes") == -1, "SpawnManager should read enemy scenes from wave resources")
	_expect(source.find("res://scenes/enemies/enemy_basic.tscn") == -1, "SpawnManager should not hardcode basic enemy scene")
	_expect(source.find("res://scenes/enemies/enemy_fast.tscn") == -1, "SpawnManager should not hardcode fast enemy scene")
	_expect(source.find("res://scenes/enemies/enemy_tank.tscn") == -1, "SpawnManager should not hardcode tank enemy scene")
	_expect(source.find("spawn_enemy_scene") >= 0, "SpawnManager should expose resource-driven special enemy spawning")


func _check_script_text_boundaries() -> void:
	for path in [
		"res://scripts/ui/hud_controller.gd",
		"res://scripts/ui/level_up_panel_controller.gd",
		"res://scripts/ui/upgrade_card.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		_expect(source.find("GameText") >= 0, "%s should use GameText for player-visible text" % path)


func _check_upgrade_card_uses_game_text() -> void:
	var source := FileAccess.get_file_as_string("res://scripts/ui/upgrade_card.gd")
	_expect(source.find("GameText.upgrade_card") >= 0, "upgrade_card.gd should render option text through GameText.upgrade_card")
	_expect(source.find("GameText.upgrade_card_source") >= 0, "upgrade_card.gd should render upgrade source through GameText")
	_expect(source.find("max_module_count") >= 0, "upgrade_card.gd should receive module cap instead of hardcoding it")

	var panel_source := FileAccess.get_file_as_string("res://scripts/ui/level_up_panel_controller.gd")
	_expect(panel_source.find("max_module_count") >= 0, "LevelUpPanel should pass configured module cap into cards")

	var upgrade_manager_source := FileAccess.get_file_as_string("res://scripts/progression/upgrade_manager.gd")
	_expect(upgrade_manager_source.find("get_module_limit") >= 0, "UpgradeManager should expose resource-driven module cap for UI")
	_expect(upgrade_manager_source.find("can_acquire_module(3") == -1, "UpgradeManager should not hardcode module cap")
	_expect(upgrade_manager_source.find("return upgrade_pool") >= 0, "UpgradeManager should read module cap from the module install pool")

	var pool_data_source := FileAccess.get_file_as_string("res://resources/upgrades/upgrade_pool_data.gd")
	_expect(pool_data_source.find("max_module_count: int = 3") == -1, "UpgradePoolData should not hardcode the default module cap")

	var module_option := UpgradeOptionData.new()
	module_option.upgrade_type = UpgradeOptionData.UpgradeType.MODULE
	var module_source := GameText.upgrade_card_source(module_option, 5)
	_expect(module_source.find("新模块") >= 0, "Module upgrade card source should identify new module options")
	_expect(module_source.find("5") >= 0, "Module upgrade card source should include configured module cap")

	var stat_option := UpgradeOptionData.new()
	stat_option.upgrade_type = UpgradeOptionData.UpgradeType.STAT
	_expect(GameText.upgrade_card_source(stat_option).find("模块强化") >= 0, "Stat upgrade card source should identify module skill options")

	var general_option := UpgradeOptionData.new()
	general_option.upgrade_type = UpgradeOptionData.UpgradeType.GENERAL
	_expect(GameText.upgrade_card_source(general_option).find("通用技能") >= 0, "General upgrade card source should identify general skill options")

	var hud_source := FileAccess.get_file_as_string("res://scripts/ui/hud_controller.gd")
	_expect(hud_source.find("GameText.hud_character") >= 0, "hud_controller.gd should render character text through GameText.hud_character")


func _find_upgrade_option(pool: UpgradePoolData, option_id: StringName) -> UpgradeOptionData:
	for option in pool.options:
		if option != null and option.id == option_id:
			return option
	_failures.append("Failed to find upgrade option %s" % option_id)
	return null


func _has_module_skill_stat(modifiers: Dictionary) -> bool:
	for key in [
		&"luck_add",
		&"luck_mult",
		&"attack_speed_add",
		&"attack_speed_mult",
		&"attack_range_add",
		&"attack_range_mult",
		&"crit_chance_add",
		&"crit_damage_mult_add",
		&"crit_damage_mult_mult",
	]:
		if modifiers.has(key):
			return true
	return false


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		_failures.append("Failed to load %s" % scene_path)
		return null

	var instance := packed_scene.instantiate()
	if instance == null:
		_failures.append("Failed to instantiate %s" % scene_path)
	return instance


func _create_test_world_obstacle(position: Vector2, size: Vector2) -> StaticBody2D:
	var obstacle := StaticBody2D.new()
	obstacle.name = "NavigationTestObstacle"
	obstacle.collision_layer = CollisionLayers.WORLD
	obstacle.collision_mask = 0
	obstacle.global_position = position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	obstacle.add_child(shape)
	return obstacle


func _collect_descendants(node: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	if node == null:
		return descendants
	for child in node.get_children():
		descendants.append(child)
		descendants.append_array(_collect_descendants(child))
	return descendants


func _remove_instance(instance: Node) -> void:
	root.remove_child(instance)
	instance.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("project_sanity_check passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)
