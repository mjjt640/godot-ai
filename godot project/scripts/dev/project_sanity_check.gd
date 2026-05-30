extends SceneTree

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const ArrowEnemySkillDataScript = preload("res://resources/enemies/skills/arrow_enemy_skill_data.gd")
const GameText = preload("res://scripts/ui/game_text.gd")
const SanityContextScript = preload("res://scripts/dev/sanity_context.gd")
const WorldMapChecksScript = preload("res://scripts/dev/world_map_checks.gd")
const ProgressionChecksScript = preload("res://scripts/dev/progression_checks.gd")
const EnemyCombatChecksScript = preload("res://scripts/dev/enemy_combat_checks.gd")
const UIRunProfileChecksScript = preload("res://scripts/dev/ui_run_profile_checks.gd")
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
var _ui_run_profile_checks = UIRunProfileChecksScript.new()


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
	_check_arena_tile_layers()
	_check_game_root_scene()
	_check_combat_feedback_resource()
	_check_combat_feedback_readability_hooks()
	_check_player_visual_animator_state()
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
	_check_main_menu_ui()
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


func _check_arena_tile_layers() -> void:
	_world_map_checks.call("check_arena_tile_layers", _ctx())


func _check_game_root_scene() -> void:
	_world_map_checks.call("check_game_root_scene", _ctx())


func _check_special_enemy_scene(scene_path: String, expects_boss: bool) -> void:
	_enemy_combat_checks.call("check_special_enemy_scene", _ctx(), scene_path, expects_boss)


func _check_combat_feedback_resource() -> void:
	_enemy_combat_checks.call("check_combat_feedback_resource", _ctx())


func _check_combat_feedback_readability_hooks() -> void:
	_enemy_combat_checks.call("check_combat_feedback_readability_hooks", _ctx())


func _check_player_visual_animator_state() -> void:
	_enemy_combat_checks.call("check_player_visual_animator_state", _ctx())


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
	_enemy_combat_checks.call("check_boss_wide_body_navigation_and_state", _ctx(), ArrowEnemySkillDataScript, CollisionLayers)


func _check_health_bar_ui() -> void:
	_ui_run_profile_checks.call("check_health_bar_ui", _ctx())


func _check_hud_run_objective_ui() -> void:
	_ui_run_profile_checks.call("check_hud_run_objective_ui", _ctx(), GameText)


func _check_boss_health_bar_ui() -> void:
	_ui_run_profile_checks.call("check_boss_health_bar_ui", _ctx())


func _check_main_menu_ui() -> void:
	_ui_run_profile_checks.call("check_main_menu_ui", _ctx(), GameText)


func _check_enemy_health_bar_rules() -> void:
	_ui_run_profile_checks.call("check_enemy_health_bar_rules", _ctx())


func _check_enemy_behavior_variants() -> void:
	_enemy_combat_checks.call("check_enemy_behavior_variants", _ctx(), ENEMY_BEHAVIOR_PRESSURE, ENEMY_BEHAVIOR_SHIELD)


func _check_base_weapon_parameters_apply_to_profile() -> void:
	_ui_run_profile_checks.call("check_base_weapon_parameters_apply_to_profile", _ctx())


func _check_stat_upgrade_applies_to_profile() -> void:
	_ui_run_profile_checks.call("check_stat_upgrade_applies_to_profile", _ctx())


func _check_character_stats_apply_to_profile() -> void:
	_ui_run_profile_checks.call("check_character_stats_apply_to_profile", _ctx())


func _check_critical_hit_damage() -> void:
	_ui_run_profile_checks.call("check_critical_hit_damage", _ctx(), DamageProbe)


func _check_general_upgrade_applies_to_player() -> void:
	_ui_run_profile_checks.call("check_general_upgrade_applies_to_player", _ctx())


func _check_luck_increases_high_rarity_weight() -> void:
	_ui_run_profile_checks.call("check_luck_increases_high_rarity_weight", _ctx())


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
	_ui_run_profile_checks.call("check_wave_table", _ctx())


func _check_enemy_templates_and_pool_variety() -> void:
	_enemy_combat_checks.call("check_enemy_templates_and_pool_variety", _ctx())


func _check_run_tuning() -> void:
	_ui_run_profile_checks.call("check_run_tuning", _ctx())


func _check_map_documentation() -> void:
	_world_map_checks.call("check_map_documentation", _ctx())


func _check_legacy_paths_removed() -> void:
	_world_map_checks.call("check_legacy_paths_removed", _ctx())


func _check_run_objective() -> void:
	_ui_run_profile_checks.call("check_run_objective", _ctx(), Callable(self, "_check_special_enemy_scene"))


func _check_spawn_manager_is_resource_driven() -> void:
	_ui_run_profile_checks.call("check_spawn_manager_is_resource_driven", _ctx())


func _check_script_text_boundaries() -> void:
	_ui_run_profile_checks.call("check_script_text_boundaries", _ctx())


func _check_upgrade_card_uses_game_text() -> void:
	_ui_run_profile_checks.call("check_upgrade_card_uses_game_text", _ctx(), GameText)


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
