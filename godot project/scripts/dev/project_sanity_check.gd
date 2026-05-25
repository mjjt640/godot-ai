extends SceneTree

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const DashEnemySkillDataScript = preload("res://resources/enemies/skills/dash_enemy_skill_data.gd")
const GameText = preload("res://scripts/ui/game_text.gd")
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
	_check_upgrade_filtering_rules()
	_check_upgrade_pool_decoupling()
	_check_run_tuning()
	_check_map_documentation()
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
	var instance := _instantiate_scene("res://scenes/environment/arena_bounds.tscn")
	if instance == null:
		return

	root.add_child(instance)
	_expect(instance.get_child_count() == 4, "ArenaBounds should create four world walls")
	for child in instance.get_children():
		var wall := child as StaticBody2D
		if wall == null:
			_failures.append("ArenaBounds child %s is not StaticBody2D" % child.name)
		else:
			_expect(wall.collision_layer == CollisionLayers.WORLD, "ArenaBounds wall %s should use WORLD layer" % wall.name)
			_expect(wall.collision_mask == 0, "ArenaBounds wall %s should not scan masks" % wall.name)
	_remove_instance(instance)


func _check_arena_visual_scene() -> void:
	var instance := _instantiate_scene("res://scenes/environment/arena_visual.tscn")
	if instance == null:
		return

	root.add_child(instance)
	var expected_layers := [
		"GroundBaseLayer",
		"GroundDetailLayer",
		"NeonDetailLayer",
		"PropVisualLayer",
		"HazardVisualLayer",
		"BoundaryVisualLayer",
		"WorldCollisionLayer",
		"HazardAreaLayer",
	]
	var previous_z_index := -1000000
	for layer_name in expected_layers:
		var layer := instance.get_node_or_null(layer_name) as Node2D
		_expect(layer != null, "ArenaVisual should include %s" % layer_name)
		if layer != null:
			_expect(layer.z_index > previous_z_index, "ArenaVisual layer %s should keep stable ascending z_index order" % layer_name)
			previous_z_index = layer.z_index

	var world_collision_layer := instance.get_node_or_null("WorldCollisionLayer")
	_expect(world_collision_layer != null, "ArenaVisual should isolate obstacle collision in WorldCollisionLayer")
	var obstacle_count := 0
	for child in _collect_descendants(world_collision_layer):
		if child is StaticBody2D:
			obstacle_count += 1
			var obstacle := child as StaticBody2D
			_expect(obstacle.collision_layer == CollisionLayers.WORLD, "ArenaVisual obstacle %s should use WORLD layer" % obstacle.name)
			_expect(obstacle.collision_mask == 0, "ArenaVisual obstacle %s should not scan masks" % obstacle.name)
	_expect(obstacle_count > 0, "ArenaVisual should create resource-driven obstacles")
	_remove_instance(instance)


func _check_arena_hazards() -> void:
	var instance := _instantiate_scene("res://scenes/environment/arena_visual.tscn")
	if instance == null:
		return

	root.add_child(instance)
	var hazard_area_layer := instance.get_node_or_null("HazardAreaLayer")
	_expect(hazard_area_layer != null, "ArenaVisual should isolate hazard gameplay areas in HazardAreaLayer")
	var hazards: Array[Area2D] = []
	for child in _collect_descendants(hazard_area_layer):
		if child is Area2D and child.name.begins_with("Hazard"):
			hazards.append(child)
	_expect(not hazards.is_empty(), "ArenaVisual should create resource-driven hazards")
	if not hazards.is_empty():
		var hazard := hazards[0]
		_expect(hazard.collision_layer == 0, "ArenaVisual hazard should not block physical movement")
		_expect(hazard.collision_mask == CollisionLayers.PLAYER, "ArenaVisual hazard should only scan player layer")
		_expect(hazard.get_node_or_null("DamageTimer") != null, "ArenaVisual hazard should create periodic damage timer")
	_remove_instance(instance)


func _check_default_map_data() -> void:
	var map_data := load("res://resources/maps/default_map.tres")
	_expect(map_data != null, "Default map data should exist")
	if map_data == null:
		return

	_expect(map_data.get("id") == &"cyber_test_zone", "Default map should point to the first playable cyber test zone")
	_expect(map_data.get("run_tuning") != null, "Default map data should reference run tuning")
	_expect(map_data.get("visual_data") != null, "Default map data should reference arena visual data")
	var run_tuning := map_data.get("run_tuning") as RunTuningData
	if run_tuning != null:
		_expect(run_tuning.arena_half_extents.x >= 2400.0, "First playable map should be wide enough for survivor-style roaming")
		_expect(run_tuning.arena_half_extents.y >= 1500.0, "First playable map should be tall enough for survivor-style roaming")
		_expect(run_tuning.minimum_spawn_distance < run_tuning.spawn_radius, "First playable map should leave spawn ring space")
	var visual_data: Resource = map_data.get("visual_data") as Resource
	if visual_data != null:
		var obstacles: Array = visual_data.get("obstacles") as Array
		var hazards: Array = visual_data.get("hazards") as Array
		_expect(obstacles.size() >= 8, "First playable map should reuse simple obstacle chunks across a large arena")
		_expect(obstacles.size() <= 16, "First playable map should stay simple and avoid maze-like obstacle density")
		_expect(hazards.size() <= 2, "First playable map should keep hazards sparse while testing roaming")
	_expect(map_data.get("tile_library") != null, "Default map data should reference a tile library")

	var run_manager_source := FileAccess.get_file_as_string("res://scripts/run/run_manager.gd")
	_expect(run_manager_source.find("@export var map_data") >= 0, "RunManager should expose a single map_data selection resource")
	_expect(run_manager_source.find("map_data.get(\"run_tuning\")") >= 0, "RunManager should read run tuning from map_data")
	_expect(run_manager_source.find("map_data.get(\"visual_data\")") >= 0, "RunManager should read arena visuals from map_data")


func _check_default_map_tile_library() -> void:
	var map_data := load("res://resources/maps/default_map.tres")
	if map_data == null:
		return

	var tile_library: Resource = map_data.get("tile_library") as Resource
	_expect(tile_library != null, "Default map tile library should exist")
	if tile_library == null:
		return

	_expect(tile_library.get("tile_size") == Vector2i(256, 256), "Cyber test zone tiles should keep 256x256 source cells")
	_expect((tile_library.get("ground_base_tiles") as Array).size() >= 6, "Cyber test zone should have enough base ground tiles")
	_expect((tile_library.get("ground_detail_tiles") as Array).size() >= 6, "Cyber test zone should have enough detail ground tiles")
	_expect((tile_library.get("neon_detail_tiles") as Array).size() >= 4, "Cyber test zone should have neon detail tiles")
	_expect((tile_library.get("decals") as Array).size() >= 16, "Cyber test zone should have transparent decal assets")
	_expect((tile_library.get("hazard_visuals") as Array).size() >= 16, "Cyber test zone should have hazard visual assets")
	_expect((tile_library.get("hazard_ground_tiles") as Array).size() >= 16, "Cyber test zone should have hazard ground tile assets")

	for property_name in [
		"ground_base_tiles",
		"ground_detail_tiles",
		"neon_detail_tiles",
		"decals",
		"hazard_visuals",
		"hazard_ground_tiles",
	]:
		for texture in tile_library.get(property_name):
			_expect(texture is Texture2D, "Map tile library %s should only contain Texture2D entries" % property_name)


func _check_game_root_scene() -> void:
	var instance := _instantiate_scene("res://scenes/main/game_root.tscn")
	if instance == null:
		return

	root.add_child(instance)
	_expect(instance.get_node_or_null("ArenaVisual") != null, "GameRoot should include ArenaVisual")
	_expect(instance.get_node_or_null("ArenaBounds") != null, "GameRoot should include ArenaBounds")
	_expect(instance.get_node_or_null("Pickups") != null, "GameRoot should include Pickups container")
	_remove_instance(instance)


func _check_special_enemy_scene(scene_path: String, expects_boss: bool) -> void:
	var enemy := _instantiate_scene(scene_path) as EnemyController
	if enemy == null:
		return

	root.add_child(enemy)
	_expect(enemy.enemy_data != null, "%s should have enemy_data" % scene_path)
	if enemy.enemy_data != null:
		if expects_boss:
			_expect(enemy.enemy_data.is_boss, "%s should be marked as boss" % scene_path)
		else:
			_expect(enemy.enemy_data.is_elite, "%s should be marked as elite" % scene_path)
		_expect(enemy.enemy_data.max_health > 100.0, "%s should have special enemy health budget" % scene_path)
		_expect(enemy.enemy_data.experience_reward > 3, "%s should reward more XP than normal enemies" % scene_path)
	_remove_instance(enemy)


func _check_combat_feedback_resource() -> void:
	var feedback := load("res://resources/combat/default_combat_feedback.tres")
	if feedback == null:
		_failures.append("Failed to load default combat feedback")
		return

	_expect(float(feedback.get("explosion_effect_duration")) > 0.0, "Combat feedback needs positive explosion_effect_duration")
	_expect(float(feedback.get("explosion_effect_ring_width")) > 0.0, "Combat feedback needs positive explosion_effect_ring_width")
	_expect(feedback.get("explosion_effect_ring_color") is Color, "Combat feedback needs explosion_effect_ring_color")
	_expect(feedback.get("explosion_effect_fill_color") is Color, "Combat feedback needs explosion_effect_fill_color")


func _check_combat_feedback_readability_hooks() -> void:
	var feedback := load("res://resources/combat/default_combat_feedback.tres")
	if feedback == null:
		return

	_expect(feedback.get("damage_number_elite_color") is Color, "Combat feedback needs elite damage number color")
	_expect(feedback.get("damage_number_boss_color") is Color, "Combat feedback needs boss damage number color")
	var flash_duration: Variant = feedback.get("player_hit_flash_duration")
	_expect(flash_duration != null and float(flash_duration) > 0.0, "Combat feedback needs positive player hit flash duration")
	_expect(feedback.get("player_hit_flash_color") is Color, "Combat feedback needs player hit flash color")
	var pressure_warning_duration: Variant = feedback.get("pressure_warning_duration")
	var pressure_warning_ring_width: Variant = feedback.get("pressure_warning_ring_width")
	var pressure_warning_marker_size: Variant = feedback.get("pressure_warning_marker_size")
	var pressure_warning_marker_width: Variant = feedback.get("pressure_warning_marker_width")
	var pressure_warning_countdown_width: Variant = feedback.get("pressure_warning_countdown_width")
	var pressure_warning_edge_marker_count: Variant = feedback.get("pressure_warning_edge_marker_count")
	var pressure_warning_edge_marker_size: Variant = feedback.get("pressure_warning_edge_marker_size")
	var pressure_impact_duration: Variant = feedback.get("pressure_impact_duration")
	var pressure_impact_ring_width: Variant = feedback.get("pressure_impact_ring_width")
	var pressure_impact_burst_count: Variant = feedback.get("pressure_impact_burst_count")
	var pressure_impact_burst_length: Variant = feedback.get("pressure_impact_burst_length")
	var pressure_impact_burst_width: Variant = feedback.get("pressure_impact_burst_width")
	_expect(pressure_warning_duration != null and float(pressure_warning_duration) > 0.0, "Combat feedback needs positive pressure warning duration")
	_expect(pressure_warning_ring_width != null and float(pressure_warning_ring_width) > 0.0, "Combat feedback needs pressure warning ring width")
	_expect(feedback.get("pressure_warning_ring_color") is Color, "Combat feedback needs pressure warning ring color")
	_expect(feedback.get("pressure_warning_fill_color") is Color, "Combat feedback needs pressure warning fill color")
	_expect(pressure_warning_marker_size != null and float(pressure_warning_marker_size) > 0.0, "Combat feedback needs pressure warning marker size")
	_expect(pressure_warning_marker_width != null and float(pressure_warning_marker_width) > 0.0, "Combat feedback needs pressure warning marker width")
	_expect(feedback.get("pressure_warning_marker_color") is Color, "Combat feedback needs pressure warning marker color")
	_expect(pressure_warning_countdown_width != null and float(pressure_warning_countdown_width) > 0.0, "Combat feedback needs pressure warning countdown width")
	_expect(feedback.get("pressure_warning_countdown_color") is Color, "Combat feedback needs pressure warning countdown color")
	_expect(pressure_warning_edge_marker_count != null and int(pressure_warning_edge_marker_count) > 0, "Combat feedback needs pressure warning edge markers")
	_expect(pressure_warning_edge_marker_size != null and float(pressure_warning_edge_marker_size) > 0.0, "Combat feedback needs pressure warning edge marker size")
	_expect(feedback.get("pressure_warning_edge_marker_color") is Color, "Combat feedback needs pressure warning edge marker color")
	_expect(pressure_impact_duration != null and float(pressure_impact_duration) > 0.0, "Combat feedback needs pressure impact duration")
	_expect(pressure_impact_ring_width != null and float(pressure_impact_ring_width) > 0.0, "Combat feedback needs pressure impact ring width")
	_expect(feedback.get("pressure_impact_ring_color") is Color, "Combat feedback needs pressure impact ring color")
	_expect(feedback.get("pressure_impact_fill_color") is Color, "Combat feedback needs pressure impact fill color")
	_expect(pressure_impact_burst_count != null and int(pressure_impact_burst_count) > 0, "Combat feedback needs pressure impact burst count")
	_expect(pressure_impact_burst_length != null and float(pressure_impact_burst_length) > 0.0, "Combat feedback needs pressure impact burst length")
	_expect(pressure_impact_burst_width != null and float(pressure_impact_burst_width) > 0.0, "Combat feedback needs pressure impact burst width")
	_expect(feedback.get("pressure_impact_burst_color") is Color, "Combat feedback needs pressure impact burst color")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	_expect(enemy_source.find("damage_number_boss_color") >= 0, "EnemyController should use boss damage number feedback")
	_expect(enemy_source.find("damage_number_elite_color") >= 0, "EnemyController should use elite damage number feedback")
	var pressure_executor_source := FileAccess.get_file_as_string("res://scripts/enemies/pressure_enemy_behavior_executor.gd")
	_expect(pressure_executor_source.find("PressureWarningEffect") >= 0, "PressureEnemyBehaviorExecutor should spawn pressure warning effects")
	_expect(pressure_executor_source.find("PressureImpactEffect") >= 0, "PressureEnemyBehaviorExecutor should spawn pressure impact effects")

	var warning_source := FileAccess.get_file_as_string("res://scripts/effects/pressure_warning_effect.gd")
	_expect(warning_source.find("draw_line") >= 0, "Pressure warning effect should draw a center marker")
	_expect(warning_source.find("draw_colored_polygon") >= 0, "Pressure warning effect should draw edge danger markers")
	_expect(warning_source.find("pressure_warning_countdown") >= 0, "Pressure warning effect should draw countdown feedback")

	var impact_source := FileAccess.get_file_as_string("res://scripts/effects/pressure_impact_effect.gd")
	_expect(impact_source.find("pressure_impact_burst") >= 0, "Pressure impact effect should draw burst feedback")

	var player_source := FileAccess.get_file_as_string("res://scripts/player/player_controller.gd")
	_expect(player_source.find("player_hit_flash_color") >= 0, "PlayerController should use player hit flash feedback")


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
	var projectile := _instantiate_scene("res://scenes/weapons/projectile.tscn") as ProjectileController
	if projectile == null:
		return

	var first_target := DamageProbe.new()
	var second_target := DamageProbe.new()
	root.add_child(projectile)
	root.add_child(first_target)
	root.add_child(second_target)
	first_target.add_to_group("enemies")
	second_target.add_to_group("enemies")

	var profile := ShotProfile.new()
	profile.damage = 10.0
	profile.pierce_count = 0
	profile.explosion_radius = 0.0
	projectile.configure(profile, Vector2.RIGHT)
	projectile.call("_on_body_entered", first_target)
	projectile.call("_on_body_entered", second_target)

	_expect(is_equal_approx(first_target.damage_taken, 10.0), "Non-piercing projectile should damage the first enemy once")
	_expect(is_zero_approx(second_target.damage_taken), "Non-piercing projectile should ignore later enemies after first hit")
	_remove_instance(second_target)
	_remove_instance(first_target)
	_remove_instance(projectile)


func _check_projectile_explosion_damage_multiplier() -> void:
	var projectile := _instantiate_scene("res://scenes/weapons/projectile.tscn") as ProjectileController
	if projectile == null:
		return

	var primary_target := DamageProbe.new()
	var nearby_target := DamageProbe.new()
	root.add_child(projectile)
	root.add_child(primary_target)
	root.add_child(nearby_target)
	primary_target.add_to_group("enemies")
	nearby_target.add_to_group("enemies")
	projectile.global_position = Vector2.ZERO
	primary_target.global_position = Vector2.ZERO
	nearby_target.global_position = Vector2(20.0, 0.0)

	var profile := ShotProfile.new()
	profile.damage = 10.0
	profile.explosion_radius = 40.0
	projectile.configure(profile, Vector2.RIGHT)
	projectile.set("explosion_damage_mult", 0.25)
	HitResolver.resolve_projectile_hit(primary_target, projectile)

	_expect(is_equal_approx(primary_target.damage_taken, 10.0), "Explosion projectile should deal full damage to primary target")
	_expect(is_equal_approx(nearby_target.damage_taken, 2.5), "Explosion splash damage should use projectile explosion_damage_mult")
	_remove_instance(nearby_target)
	_remove_instance(primary_target)
	_remove_instance(projectile)


func _check_projectile_world_collision_rules() -> void:
	var projectile := _instantiate_scene("res://scenes/weapons/projectile.tscn") as ProjectileController
	if projectile == null:
		return

	root.add_child(projectile)
	var profile := ShotProfile.new()
	profile.can_pierce_world = false
	projectile.configure(profile, Vector2.RIGHT)
	_expect((projectile.collision_mask & CollisionLayers.WORLD) != 0, "Projectile should scan WORLD collisions by default")
	_expect(not projectile.can_pierce_world, "Projectile should default to stopping on world collisions")
	var world_obstacle := _create_test_world_obstacle(Vector2.ZERO, Vector2(32.0, 32.0))
	root.add_child(world_obstacle)
	projectile.call("_on_body_entered", world_obstacle)
	_expect(projectile.is_queued_for_deletion(), "Non-world-piercing projectile should queue_free after hitting WORLD")
	_remove_instance(world_obstacle)
	_remove_instance(projectile)

	var piercing_projectile := _instantiate_scene("res://scenes/weapons/projectile.tscn") as ProjectileController
	if piercing_projectile == null:
		return
	root.add_child(piercing_projectile)
	var piercing_profile := ShotProfile.new()
	piercing_profile.can_pierce_world = true
	piercing_projectile.configure(piercing_profile, Vector2.RIGHT)
	_expect(piercing_projectile.can_pierce_world, "Projectile should read can_pierce_world from ShotProfile")
	_expect((piercing_projectile.collision_mask & CollisionLayers.WORLD) == 0, "World-piercing projectile should not scan WORLD collisions")
	_remove_instance(piercing_projectile)


func _check_enemy_soft_separation() -> void:
	var player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	var first_enemy := _instantiate_scene("res://scenes/enemies/enemy_basic.tscn") as EnemyController
	var second_enemy := _instantiate_scene("res://scenes/enemies/enemy_basic.tscn") as EnemyController
	if player == null or first_enemy == null or second_enemy == null:
		return

	root.add_child(player)
	root.add_child(first_enemy)
	root.add_child(second_enemy)
	player.global_position = Vector2(420.0, 0.0)
	first_enemy.global_position = Vector2(0.0, 0.0)
	second_enemy.global_position = Vector2(10.0, 0.0)

	var initial_distance := first_enemy.global_position.distance_to(second_enemy.global_position)
	for _step in range(6):
		first_enemy._physics_process(0.1)
		second_enemy._physics_process(0.1)
	var final_distance := first_enemy.global_position.distance_to(second_enemy.global_position)

	_expect(final_distance > initial_distance + 6.0, "Enemies should softly separate instead of overlapping in a stack")
	_remove_instance(second_enemy)
	_remove_instance(first_enemy)
	_remove_instance(player)


func _check_enemy_obstacle_navigation() -> void:
	var player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	var enemy := _instantiate_scene("res://scenes/enemies/enemy_basic.tscn") as EnemyController
	if player == null or enemy == null:
		return

	var obstacle := _create_test_world_obstacle(Vector2.ZERO, Vector2(96.0, 140.0))
	root.add_child(player)
	root.add_child(enemy)
	root.add_child(obstacle)
	player.global_position = Vector2(180.0, 0.0)
	enemy.global_position = Vector2(-160.0, 0.0)
	enemy.call("_reset_navigation_stuck")
	var initial_distance := enemy.global_position.distance_to(player.global_position)
	var initial_y := enemy.global_position.y
	for _step in range(24):
		enemy._physics_process(0.1)
	var final_distance := enemy.global_position.distance_to(player.global_position)

	_expect(absf(enemy.global_position.y - initial_y) > 16.0, "Enemy should steer sideways when a world obstacle blocks the direct chase line")
	_expect(final_distance < initial_distance, "Enemy obstacle navigation should still make progress toward the player")
	_remove_instance(obstacle)
	_remove_instance(enemy)
	_remove_instance(player)


func _check_enemy_obstacle_escape_navigation_hooks() -> void:
	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	_expect(enemy_source.find("_recover_from_slide_collisions") >= 0, "EnemyController should recover when slide collisions show it is stuck on a world obstacle")
	_expect(enemy_source.find("_get_detour_angle_multiplier") >= 0, "EnemyController should expand detour angle when regular obstacle steering is stuck")
	_expect(enemy_source.find("_choose_clearer_direction") >= 0, "EnemyController should choose from more than two obstacle detour directions")


func _check_enemy_skill_executor_split() -> void:
	var base_executor_path := "res://scripts/enemies/enemy_skill_executor.gd"
	var dash_executor_path := "res://scripts/enemies/dash_skill_executor.gd"
	_expect(FileAccess.file_exists(base_executor_path), "EnemySkillExecutor base script should own the common skill executor contract")
	_expect(FileAccess.file_exists(dash_executor_path), "DashSkillExecutor should own dash-specific enemy skill behavior")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	_expect(enemy_source.find("_skill_executors") >= 0, "EnemyController should route enemy skills through an executor list")
	_expect(enemy_source.find("DashEnemySkillDataScript") == -1, "EnemyController should not preload dash-specific skill data")
	_expect(enemy_source.find("BossDashWarningEffect") == -1, "EnemyController should not spawn dash warning effects directly")
	_expect(enemy_source.find("_begin_active_dash") == -1, "EnemyController should not contain dash phase implementation details")
	_expect(enemy_source.find("_try_dash_hit_target") == -1, "EnemyController should not contain dash hit implementation details")

	if FileAccess.file_exists(base_executor_path):
		var base_executor_source := FileAccess.get_file_as_string(base_executor_path)
		_expect(base_executor_source.find("func can_start(") >= 0, "EnemySkillExecutor should expose can_start")
		_expect(base_executor_source.find("func start(") >= 0, "EnemySkillExecutor should expose start")
		_expect(base_executor_source.find("func update(") >= 0, "EnemySkillExecutor should expose update")
		_expect(base_executor_source.find("func finish(") >= 0, "EnemySkillExecutor should expose finish")

	if FileAccess.file_exists(dash_executor_path):
		var dash_executor_source := FileAccess.get_file_as_string(dash_executor_path)
		_expect(dash_executor_source.find("extends \"res://scripts/enemies/enemy_skill_executor.gd\"") >= 0, "DashSkillExecutor should inherit the common executor contract")
		_expect(dash_executor_source.find("DashEnemySkillData") >= 0, "DashSkillExecutor should own dash skill data matching")
		_expect(dash_executor_source.find("BossDashWarningEffect") >= 0, "DashSkillExecutor should own dash warning effects")
		_expect(dash_executor_source.find("take_damage") >= 0, "DashSkillExecutor should own dash hit damage")


func _check_enemy_behavior_executor_split() -> void:
	var base_executor_path := "res://scripts/enemies/enemy_behavior_executor.gd"
	var pressure_executor_path := "res://scripts/enemies/pressure_enemy_behavior_executor.gd"
	var touch_executor_path := "res://scripts/enemies/touch_damage_behavior_executor.gd"
	_expect(FileAccess.file_exists(base_executor_path), "EnemyBehaviorExecutor base script should own the common behavior executor contract")
	_expect(FileAccess.file_exists(pressure_executor_path), "PressureEnemyBehaviorExecutor should own PRESSURE enemy behavior")
	_expect(FileAccess.file_exists(touch_executor_path), "TouchDamageBehaviorExecutor should own enemy contact damage")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	_expect(enemy_source.find("_behavior_executors") >= 0, "EnemyController should route enemy behaviors through an executor list")
	_expect(enemy_source.find("TouchDamageBehaviorExecutor") >= 0, "EnemyController should register touch damage behavior through an executor")
	_expect(enemy_source.find("PressureWarningEffect") == -1, "EnemyController should not spawn pressure warning effects directly")
	_expect(enemy_source.find("PressureImpactEffect") == -1, "EnemyController should not spawn pressure impact effects directly")
	_expect(enemy_source.find("_pressure_warning_remaining") == -1, "EnemyController should not own pressure warning state")
	_expect(enemy_source.find("_try_pressure_damage") == -1, "EnemyController should not contain pressure behavior implementation details")
	_expect(enemy_source.find("_resolve_pressure_warning") == -1, "EnemyController should not contain pressure warning resolution details")
	_expect(enemy_source.find("_touch_cooldown_remaining") == -1, "EnemyController should not own touch damage cooldown state")
	_expect(enemy_source.find("_try_touch_damage") == -1, "EnemyController should not contain touch damage implementation details")
	_expect(enemy_source.find("get_touch_damage") == -1, "EnemyController should not read touch damage values directly")
	_expect(enemy_source.find("get_player_knockback") == -1, "EnemyController should not read touch player knockback directly")

	if FileAccess.file_exists(base_executor_path):
		var base_executor_source := FileAccess.get_file_as_string(base_executor_path)
		_expect(base_executor_source.find("func matches(") >= 0, "EnemyBehaviorExecutor should expose matches")
		_expect(base_executor_source.find("func tick(") >= 0, "EnemyBehaviorExecutor should expose tick")
		_expect(base_executor_source.find("func update(") >= 0, "EnemyBehaviorExecutor should expose update")
		_expect(base_executor_source.find("func update_contact(") >= 0, "EnemyBehaviorExecutor should expose update_contact")
		_expect(base_executor_source.find("func reset(") >= 0, "EnemyBehaviorExecutor should expose reset")

	if FileAccess.file_exists(pressure_executor_path):
		var pressure_executor_source := FileAccess.get_file_as_string(pressure_executor_path)
		_expect(pressure_executor_source.find("extends \"res://scripts/enemies/enemy_behavior_executor.gd\"") >= 0, "PressureEnemyBehaviorExecutor should inherit the common behavior contract")
		_expect(pressure_executor_source.find("PressureWarningEffect") >= 0, "PressureEnemyBehaviorExecutor should own pressure warning effects")
		_expect(pressure_executor_source.find("PressureImpactEffect") >= 0, "PressureEnemyBehaviorExecutor should own pressure impact effects")
		_expect(pressure_executor_source.find("take_damage") >= 0, "PressureEnemyBehaviorExecutor should own pressure delayed damage")

	if FileAccess.file_exists(touch_executor_path):
		var touch_executor_source := FileAccess.get_file_as_string(touch_executor_path)
		_expect(touch_executor_source.find("extends \"res://scripts/enemies/enemy_behavior_executor.gd\"") >= 0, "TouchDamageBehaviorExecutor should inherit the common behavior contract")
		_expect(touch_executor_source.find("_cooldown_remaining") >= 0, "TouchDamageBehaviorExecutor should own touch cooldown state")
		_expect(touch_executor_source.find("get_touch_damage") >= 0, "TouchDamageBehaviorExecutor should own touch damage values")
		_expect(touch_executor_source.find("get_touch_knockback") >= 0, "TouchDamageBehaviorExecutor should own enemy touch hit reaction")
		_expect(touch_executor_source.find("get_player_knockback") >= 0, "TouchDamageBehaviorExecutor should own player touch knockback")
		_expect(touch_executor_source.find("get_touch_interval") >= 0, "TouchDamageBehaviorExecutor should own touch cooldown duration")


func _check_boss_wide_body_navigation_and_state() -> void:
	var player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	var boss := _instantiate_scene("res://scenes/enemies/enemy_boss_overseer.tscn") as EnemyController
	if player == null or boss == null:
		return

	var dash_skill := load("res://resources/enemies/skills/boss_dash.tres")
	var boss_skill_pool := load("res://resources/enemies/skill_pools/boss_overseer_skill_pool.tres")
	_expect(dash_skill != null, "Boss dash skill template should load")
	_expect(boss_skill_pool != null, "Boss Overseer skill pool should load")
	if dash_skill != null:
		_expect(dash_skill.get("id") == &"boss_dash", "Boss dash skill should have a stable id")
		_expect(dash_skill.get("display_name") != "", "Boss dash skill needs a Chinese display name")
		_expect(dash_skill.get_script() == DashEnemySkillDataScript, "Boss dash skill should use a dash-specific skill subclass")
		_expect(float(dash_skill.get("cooldown")) > 0.0, "Boss dash skill needs positive cooldown")
		_expect(float(dash_skill.get("weight")) > 0.0, "Boss dash skill needs positive common weight")
		_expect(float(dash_skill.get("windup_duration")) > 0.0, "Boss dash skill needs positive windup duration")
		_expect(float(dash_skill.get("dash_speed")) > 0.0, "Boss dash skill needs positive dash speed")
		_expect(float(dash_skill.get("dash_duration")) > 0.0, "Boss dash skill needs positive dash duration")
		_expect(float(dash_skill.get("recover_duration")) > 0.0, "Boss dash skill needs positive recover duration")
		_expect(float(dash_skill.get("damage")) > 0.0, "Boss dash skill needs positive damage")
		_expect(float(dash_skill.get("knockback")) > 0.0, "Boss dash skill needs positive knockback")
		_expect(float(dash_skill.get("warning_length")) > 0.0, "Boss dash skill needs positive warning length")
		_expect(float(dash_skill.get("warning_width")) > 0.0, "Boss dash skill needs positive warning width")
	var base_skill_source := FileAccess.get_file_as_string("res://resources/enemies/enemy_skill_data.gd")
	_expect(base_skill_source.find("dash_speed") == -1, "EnemySkillData base class should not define dash-specific values")
	_expect(base_skill_source.find("warning_length") == -1, "EnemySkillData base class should not define warning-shape values")
	var dash_skill_source := FileAccess.get_file_as_string("res://resources/enemies/skills/dash_enemy_skill_data.gd")
	_expect(dash_skill_source.find("extends \"res://resources/enemies/enemy_skill_data.gd\"") >= 0, "Dash skill data should inherit common enemy skill data")
	if boss_skill_pool != null:
		var skills: Array = boss_skill_pool.get("skills")
		_expect(not skills.is_empty(), "Boss skill pool should reserve at least one skill slot")
		_expect(skills.has(dash_skill), "Boss skill pool should include the dash skill template")
	if boss.enemy_data != null:
		var resolved_pool := boss.enemy_data.get_skill_pool()
		_expect(resolved_pool == boss_skill_pool, "Boss enemy data should resolve its independent skill pool from its template")

	var shoulder_obstacle := _create_test_world_obstacle(Vector2(86.0, 40.0), Vector2(30.0, 20.0))
	var effect_container := Node2D.new()
	root.add_child(player)
	root.add_child(boss)
	root.add_child(shoulder_obstacle)
	root.add_child(effect_container)
	current_scene = effect_container
	player.global_position = Vector2(220.0, 0.0)
	boss.global_position = Vector2.ZERO
	boss.call("_reset_navigation_stuck")
	var center_clearance: float = boss.call("_get_center_world_clearance", Vector2.RIGHT, 140.0)
	var wide_clearance: float = boss.call("_get_world_clearance", Vector2.RIGHT, 140.0)
	_expect(is_equal_approx(center_clearance, 140.0), "Boss center ray should stay clear in the shoulder obstacle probe")
	_expect(wide_clearance < center_clearance, "Boss wide body probe should detect shoulder obstacles")

	_expect(boss.has_method("begin_boss_windup"), "Boss should expose a windup state entry for future skills")
	_expect(boss.has_method("begin_boss_dash"), "Boss should expose a dash state entry for future skills")
	_expect(boss.has_method("begin_boss_recover"), "Boss should expose a recover state entry for future skills")
	_expect(boss.has_method("get_combat_state"), "Boss should expose combat state for skill tests")
	boss.begin_boss_windup(0.2)
	_expect(int(boss.get_combat_state()) == 1, "Boss windup entry should leave chase state")
	boss.begin_boss_dash(Vector2.RIGHT, 120.0, 0.2)
	_expect(int(boss.get_combat_state()) == 2, "Boss dash entry should switch to dash state")
	boss.begin_boss_recover(0.2)
	_expect(int(boss.get_combat_state()) == 3, "Boss recover entry should switch to recover state")
	boss.return_to_chase()
	_expect(int(boss.get_combat_state()) == 0, "Boss should return to chase after skill states")
	if dash_skill != null:
		boss.call("_start_enemy_skill", dash_skill, Vector2.RIGHT)
		_expect(int(boss.get_combat_state()) == 1, "Boss skill template should start from windup")
		_expect(effect_container.get_child_count() > 0, "Boss dash skill should spawn a warning effect")
		boss._physics_process(float(dash_skill.get("windup_duration")) + 0.05)
		_expect(int(boss.get_combat_state()) == 2, "Boss dash skill should enter dash after windup")
		var skill_cooldowns: Dictionary = boss.get("_skill_cooldowns")
		_expect(float(skill_cooldowns.get(dash_skill.get("id"), 0.0)) > 0.0, "Boss dash skill should set cooldown from template")
		boss.return_to_chase()

	current_scene = null
	_remove_instance(effect_container)
	_remove_instance(shoulder_obstacle)
	_remove_instance(boss)
	_remove_instance(player)


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
	var ranged_data := load("res://resources/enemies/enemy_ranged.tres") as EnemyData
	var shield_data := load("res://resources/enemies/enemy_shield.tres") as EnemyData
	_expect(ranged_data != null, "Ranged pressure enemy data should load")
	_expect(shield_data != null, "Shield enemy data should load")
	if ranged_data != null:
		_expect(ranged_data.has_method("get_behavior_type"), "EnemyData should expose resolved behavior type")
		_expect(ranged_data.has_method("get_pressure_interval"), "EnemyData should expose resolved pressure interval")
		_expect(ranged_data.has_method("get_pressure_range"), "EnemyData should expose resolved pressure range")
		_expect(ranged_data.has_method("get_pressure_radius"), "EnemyData should expose resolved pressure warning radius")
		_expect(ranged_data.has_method("get_pressure_warning_duration"), "EnemyData should expose resolved pressure warning duration")
		if ranged_data.has_method("get_behavior_type"):
			_expect(ranged_data.get_behavior_type() == ENEMY_BEHAVIOR_PRESSURE, "Ranged pressure enemy should use PRESSURE behavior")
		if ranged_data.has_method("get_pressure_interval"):
			_expect(ranged_data.get_pressure_interval() > 0.0, "Pressure enemy should resolve pressure interval")
		if ranged_data.has_method("get_pressure_range"):
			_expect(ranged_data.get_pressure_range() > ranged_data.get_stop_distance(), "Pressure enemy range should exceed stop distance")
		if ranged_data.has_method("get_pressure_radius"):
			_expect(ranged_data.get_pressure_radius() > 0.0, "Pressure enemy should resolve warning radius")
		if ranged_data.has_method("get_pressure_warning_duration"):
			_expect(ranged_data.get_pressure_warning_duration() > 0.0, "Pressure enemy should resolve warning duration")
	if shield_data != null:
		_expect(shield_data.has_method("get_behavior_type"), "EnemyData should expose resolved behavior type")
		_expect(shield_data.has_method("get_knockback_taken_mult"), "EnemyData should expose resolved knockback taken multiplier")
		if shield_data.has_method("get_behavior_type"):
			_expect(shield_data.get_behavior_type() == ENEMY_BEHAVIOR_SHIELD, "Shield enemy should use SHIELD behavior")
		if shield_data.has_method("get_knockback_taken_mult"):
			_expect(shield_data.get_knockback_taken_mult() < 1.0, "Shield enemy should reduce incoming knockback")

	var player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	var pressure_enemy := _instantiate_scene("res://scenes/enemies/enemy_ranged.tscn") as EnemyController
	var shield_enemy := _instantiate_scene("res://scenes/enemies/enemy_shield.tscn") as EnemyController
	if player != null and pressure_enemy != null:
		var effect_container := Node2D.new()
		root.add_child(effect_container)
		current_scene = effect_container
		root.add_child(player)
		root.add_child(pressure_enemy)
		player.global_position = Vector2.ZERO
		pressure_enemy.global_position = Vector2(120.0, 0.0)
		if player.health <= 0.0:
			player.health = player.max_health
		var initial_health := player.health
		pressure_enemy._physics_process(0.1)
		_expect(player.health == initial_health, "PRESSURE enemy should warn before dealing damage")
		_expect(effect_container.get_child_count() > 0, "PRESSURE enemy should spawn a warning circle effect")
		var warning_effect_count := effect_container.get_child_count()
		if ranged_data.has_method("get_pressure_warning_duration"):
			pressure_enemy._physics_process(ranged_data.get_pressure_warning_duration() + 0.05)
			_expect(player.health < initial_health, "PRESSURE enemy should damage player after warning if still in the marked area")
			_expect(effect_container.get_child_count() > warning_effect_count, "PRESSURE enemy should spawn an impact effect on hit")
		_remove_instance(pressure_enemy)
		_remove_instance(player)
		current_scene = null
		_remove_instance(effect_container)
	var dodge_player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	var dodge_enemy := _instantiate_scene("res://scenes/enemies/enemy_ranged.tscn") as EnemyController
	if dodge_player != null and dodge_enemy != null:
		var dodge_effect_container := Node2D.new()
		root.add_child(dodge_effect_container)
		current_scene = dodge_effect_container
		root.add_child(dodge_player)
		root.add_child(dodge_enemy)
		dodge_player.global_position = Vector2.ZERO
		dodge_enemy.global_position = Vector2(120.0, 0.0)
		if dodge_player.health <= 0.0:
			dodge_player.health = dodge_player.max_health
		var dodge_initial_health := dodge_player.health
		dodge_enemy._physics_process(0.1)
		dodge_player.global_position = Vector2(0.0, 120.0)
		if ranged_data != null and ranged_data.has_method("get_pressure_warning_duration"):
			dodge_enemy._physics_process(ranged_data.get_pressure_warning_duration() + 0.05)
			_expect(is_equal_approx(dodge_player.health, dodge_initial_health), "PRESSURE enemy warning should be avoidable by leaving the marked area")
		_remove_instance(dodge_enemy)
		_remove_instance(dodge_player)
		current_scene = null
		_remove_instance(dodge_effect_container)
	if shield_enemy != null:
		root.add_child(shield_enemy)
		shield_enemy.apply_hit_reaction(Vector2.RIGHT, 100.0)
		_expect(shield_enemy.velocity.length() < 100.0, "SHIELD enemy should reduce incoming hit reaction")
		_remove_instance(shield_enemy)


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
	var character := load("res://resources/characters/character_core_runner.tres")
	if character == null:
		_failures.append("Failed to load default character resource")
		return

	_check_character_fields(character, "Default character")

	var template := load("res://resources/characters/character_template.tres")
	if template == null:
		_failures.append("Failed to load character template resource")
	else:
		_check_character_fields(template, "Character template")

	var player := _instantiate_scene("res://scenes/player/player.tscn") as PlayerController
	if player == null:
		return
	root.add_child(player)
	_expect(player.character_data != null, "Player scene should assign default character_data")
	if player.character_data != null:
		_expect(is_equal_approx(player.move_speed, float(player.character_data.get("move_speed"))), "Player should apply character move_speed")
		_expect(is_equal_approx(player.max_health, float(player.character_data.get("max_health"))), "Player should apply character max_health")
		_expect(is_equal_approx(player.get_luck(), float(player.character_data.get("luck"))), "Player should apply character luck")
	_remove_instance(player)


func _check_default_character_pool() -> void:
	var pool := load("res://resources/characters/default_character_pool.tres") as Resource
	if pool == null:
		_failures.append("Failed to load default character pool")
		return

	var characters: Array = pool.get("characters")
	_expect(not characters.is_empty(), "Default character pool needs at least one character")
	_expect(characters.size() >= 3, "Default character pool should include first-pass character variety")
	var default_character: Resource = pool.call("get_default_character") as Resource
	_expect(default_character != null, "Default character pool should resolve default character")
	for character in characters:
		if character != null:
			_check_character_fields(character, "Pooled character %s" % character.get("id"))
	if default_character != null:
		_check_character_fields(default_character, "Default pooled character")


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
	var pool := load("res://resources/upgrades/default_upgrade_pool.tres") as UpgradePoolData
	if pool == null:
		_failures.append("Failed to load default upgrade pool")
		return

	var option_count: int = pool.option_count
	var options: Array = pool.options
	_expect(option_count == 3, "Default upgrade pool should present three options")
	_expect(pool.max_module_count > 0, "Default upgrade pool should configure a positive module cap")
	_expect(pool.common_rarity_weight > pool.rare_rarity_weight, "Common upgrades should refresh more often than rare upgrades")
	_expect(pool.rare_rarity_weight > pool.epic_rarity_weight, "Rare upgrades should refresh more often than epic upgrades")
	_expect(pool.epic_rarity_weight > pool.legendary_rarity_weight, "Epic upgrades should refresh more often than legendary upgrades")
	_expect(options.size() >= option_count, "Default upgrade pool needs enough options")
	for option in options:
		_expect(option != null, "Upgrade pool should not contain null options")
		if option != null:
			_expect(option.display_name != "", "Upgrade option %s needs Chinese display_name" % option.id)
			_expect(option.weight > 0.0, "Upgrade option %s needs positive weight" % option.id)
			_expect(pool.get_rarity_weight(option.rarity) > 0.0, "Upgrade option %s needs positive rarity weight" % option.id)
			_expect(option.upgrade_type == UpgradeOptionData.UpgradeType.MODULE, "Default upgrade pool should only install modules: %s" % option.id)
			_expect(option.module != null, "Module upgrade %s needs module data" % option.id)
			_expect(option.stat_modifiers.is_empty(), "Module install option %s should not carry stat_modifiers" % option.id)
			_expect(option.general_modifiers.is_empty(), "Module install option %s should not carry general_modifiers" % option.id)
			if option.module != null:
				_expect(int(option.module.rarity) == int(option.rarity), "Module upgrade %s should match module rarity" % option.id)


func _check_module_skill_pool() -> void:
	var pool := load("res://resources/upgrades/default_module_skill_pool.tres") as UpgradePoolData
	if pool == null:
		_failures.append("Failed to load default module skill pool")
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
	_expect(pool.option_count == 3, "Default module skill pool should present three options")
	_expect(pool.common_rarity_weight > pool.rare_rarity_weight, "Module skill common weight should exceed rare weight")
	_expect(pool.rare_rarity_weight > pool.epic_rarity_weight, "Module skill rare weight should exceed epic weight")
	_expect(pool.epic_rarity_weight > pool.legendary_rarity_weight, "Module skill epic weight should exceed legendary weight")
	for option in pool.options:
		_expect(option != null, "Module skill pool should not contain null options")
		if option == null:
			continue
		_expect(option.display_name != "", "Module skill %s needs Chinese display_name" % option.id)
		_expect(option.weight > 0.0, "Module skill %s needs positive weight" % option.id)
		_expect(option.upgrade_type == UpgradeOptionData.UpgradeType.STAT, "Module skill %s should use STAT type" % option.id)
		_expect(not option.stat_modifiers.is_empty(), "Module skill %s should declare stat_modifiers" % option.id)
		_expect(option.general_modifiers.is_empty(), "Module skill %s should not use general_modifiers" % option.id)
		_expect(not option.required_module_ids.is_empty(), "Module skill %s should declare required_module_ids" % option.id)
		_expect(pool.get_rarity_weight(option.rarity) > 0.0, "Module skill %s needs positive rarity weight" % option.id)
		if option.rarity == UpgradeOptionData.Rarity.LEGENDARY:
			has_legendary_option = true
		if not option.stat_modifiers.is_empty():
			effect_stat_option_count += 1
			_expect(not (option.stat_modifiers.has(&"explosion_radius_add") and option.stat_modifiers.has(&"explosion_damage_mult_add")), "Module skill %s should not mix explosion radius and splash damage" % option.id)
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
			_expect(option.required_module_ids.has(&"piercing_round"), "Piercing firepower should depend on piercing module")
		if option.id == &"upgrade_wide_spread":
			has_wide_spread = true
			_expect(option.required_module_ids.has(&"spread_fire"), "Wide spread should depend on spread fire module")
		if option.id == &"upgrade_blast_aftershock":
			has_blast_aftershock = true
			_expect(option.required_module_ids.has(&"explosive_payload"), "Blast aftershock should depend on explosive payload module")
	_expect(effect_stat_option_count >= 8, "Default module skill pool should include resource-driven module skills")
	_expect(has_blast_radius_boost, "Default upgrade pool should include a separate blast radius upgrade")
	_expect(has_splash_damage_boost, "Default upgrade pool should include a separate splash damage upgrade")
	_expect(has_luck_boost, "Default module skill pool should include luck module skill")
	_expect(has_attack_speed_boost, "Default module skill pool should include attack speed module skill")
	_expect(has_attack_range_boost, "Default module skill pool should include attack range module skill")
	_expect(has_crit_chance_boost, "Default module skill pool should include crit chance module skill")
	_expect(has_crit_damage_boost, "Default module skill pool should include crit damage module skill")
	_expect(has_piercing_firepower, "Default module skill pool should include piercing firepower upgrade")
	_expect(has_wide_spread, "Default module skill pool should include wide spread upgrade")
	_expect(has_blast_aftershock, "Default module skill pool should include blast aftershock upgrade")
	_expect(has_legendary_option, "Default upgrade pool should include at least one legendary option")


func _check_general_skill_pool() -> void:
	var pool := load("res://resources/upgrades/default_general_skill_pool.tres") as UpgradePoolData
	if pool == null:
		_failures.append("Failed to load default general skill pool")
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
	_expect(pool.common_rarity_weight > pool.rare_rarity_weight, "General skill pool common weight should exceed rare weight")
	_expect(pool.rare_rarity_weight > pool.epic_rarity_weight, "General skill pool rare weight should exceed epic weight")
	_expect(pool.epic_rarity_weight > pool.legendary_rarity_weight, "General skill pool epic weight should exceed legendary weight")
	for option in pool.options:
		_expect(option != null, "General skill pool should not contain null options")
		if option == null:
			continue
		_expect(option.upgrade_type == UpgradeOptionData.UpgradeType.GENERAL, "General skill %s should use GENERAL upgrade type" % option.id)
		_expect(not option.general_modifiers.is_empty(), "General skill %s should declare general_modifiers" % option.id)
		_expect(option.stat_modifiers.is_empty(), "General skill %s should not use weapon stat_modifiers" % option.id)
		_expect(not _has_module_skill_stat(option.general_modifiers), "General skill %s should not use module skill stats" % option.id)
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
			_failures.append("Only XP gain general skills should have legendary rarity: %s" % option.id)
	_expect(has_magnet_range, "General skill pool should include XP magnet range skill")
	_expect(has_health_recovery, "General skill pool should include health recovery skill")
	_expect(has_move_speed, "General skill pool should include move speed skill")
	_expect(has_xp_gain, "General skill pool should include XP gain speed skill")
	_expect(has_legendary_xp_gain, "General skill pool should include legendary XP gain speed skill")
	_expect(has_epic_magnet_multiplier, "General skill pool should include epic XP magnet multiplier skill")
	_expect(_has_common_rare_epic(magnet_rarities), "XP magnet range should have common, rare and epic variants")
	_expect(_has_common_rare_epic(health_rarities), "Health recovery should have common, rare and epic variants")
	_expect(_has_common_rare_epic(move_speed_rarities), "Move speed should have common, rare and epic variants")
	_expect(_has_common_rare_epic(xp_gain_rarities), "XP gain speed should have common, rare and epic variants")


func _check_upgrade_filtering_rules() -> void:
	var pool := load("res://resources/upgrades/default_upgrade_pool.tres") as UpgradePoolData
	var module_skill_pool := load("res://resources/upgrades/default_module_skill_pool.tres") as UpgradePoolData
	if pool == null or module_skill_pool == null:
		return

	var build_state := BuildState.new()
	build_state.default_fire_mode = null
	build_state.default_payload = null
	root.add_child(build_state)

	var upgrade_manager := UpgradeManager.new()
	root.add_child(upgrade_manager)
	upgrade_manager.upgrade_pool = pool
	upgrade_manager.module_skill_pool = module_skill_pool
	upgrade_manager._build_state = build_state

	var pierce_boost := _find_upgrade_option(module_skill_pool, &"upgrade_pierce_boost")
	if pierce_boost != null:
		_expect(not upgrade_manager._can_offer(pierce_boost), "Pierce boost should not appear before piercing module is current")
		var piercing_module := load("res://resources/modules/payload_piercing.tres") as ModuleData
		build_state.install_module(piercing_module, false, false)
		_expect(upgrade_manager._can_offer(pierce_boost), "Pierce boost should appear after piercing module is current")

	var luck_boost := _find_upgrade_option(module_skill_pool, &"upgrade_luck_boost")
	if luck_boost != null:
		_expect(upgrade_manager._can_offer(luck_boost), "Luck boost should appear when a required starting module is current")

	var module_option := _find_upgrade_option(pool, &"upgrade_burst_fire")
	if module_option != null:
		build_state.acquired_module_ids = [&"burst_fire"]
		_expect(not upgrade_manager._can_offer(module_option), "Already acquired modules should wait for the future replacement path")
		var capped_module_ids: Array[StringName] = []
		for index in range(pool.max_module_count):
			capped_module_ids.append(StringName("module_%d" % index))
		build_state.acquired_module_ids = capped_module_ids
		_expect(not upgrade_manager._can_offer(module_option), "Module upgrades should stop appearing after module cap")

	_remove_instance(upgrade_manager)
	_remove_instance(build_state)


func _check_upgrade_pool_decoupling() -> void:
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
	root.add_child(build_state)
	var normal_payload := load("res://resources/modules/payload_normal.tres") as ModuleData
	build_state.install_module(normal_payload, false, false)

	var upgrade_manager := UpgradeManager.new()
	root.add_child(upgrade_manager)
	upgrade_manager.upgrade_pool = empty_module_pool
	upgrade_manager.module_skill_pool = module_skill_pool
	upgrade_manager.general_skill_pool = general_pool
	upgrade_manager._build_state = build_state

	var options := upgrade_manager.request_options()
	_expect(options.has(stat_option), "Module skill pool should still offer options when module install pool is empty")
	_expect(options.has(general_option), "General skill pool should still offer options when module install pool is empty")
	_remove_instance(upgrade_manager)
	_remove_instance(build_state)



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
	var normal_template := load("res://resources/enemies/templates/enemy_template_normal.tres")
	var boss_template := load("res://resources/enemies/templates/enemy_template_boss.tres")
	_expect(normal_template != null, "Enemy normal template should exist")
	_expect(boss_template != null, "Enemy boss template should exist")
	if boss_template != null:
		_expect(boss_template.get("is_boss"), "Boss template should be marked as boss")

	var enemy_paths := [
		"res://resources/enemies/enemy_basic.tres",
		"res://resources/enemies/enemy_fast.tres",
		"res://resources/enemies/enemy_tank.tres",
		"res://resources/enemies/enemy_swarm.tres",
		"res://resources/enemies/enemy_ranged.tres",
		"res://resources/enemies/enemy_shield.tres",
		"res://resources/enemies/enemy_elite_brute.tres",
		"res://resources/enemies/enemy_boss_overseer.tres",
	]
	var ids: Array[StringName] = []
	for path in enemy_paths:
		var enemy := load(path) as EnemyData
		_expect(enemy != null, "%s should load as EnemyData" % path)
		if enemy == null:
			continue
		_expect(enemy.get("template") != null, "%s should use an enemy template" % path)
		_expect(enemy.has_method("get_max_health"), "%s should expose resolved max health" % path)
		_expect(enemy.has_method("get_move_speed"), "%s should expose resolved move speed" % path)
		_expect(enemy.has_method("get_path_probe_distance"), "%s should expose resolved path probe distance" % path)
		_expect(enemy.has_method("get_path_avoidance_strength"), "%s should expose resolved path avoidance strength" % path)
		_expect(enemy.has_method("get_path_body_probe_scale"), "%s should expose resolved path body probe scale" % path)
		_expect(enemy.has_method("get_path_stuck_time"), "%s should expose resolved path stuck time" % path)
		if enemy.has_method("get_max_health"):
			_expect(enemy.get_max_health() > 0.0, "%s should resolve positive max health" % path)
		if enemy.has_method("get_move_speed"):
			_expect(enemy.get_move_speed() > 0.0, "%s should resolve positive move speed" % path)
		if enemy.has_method("get_path_probe_distance"):
			_expect(enemy.get_path_probe_distance() > 0.0, "%s should resolve positive path probe distance" % path)
		if enemy.has_method("get_path_avoidance_strength"):
			_expect(enemy.get_path_avoidance_strength() > 0.0, "%s should resolve positive path avoidance strength" % path)
		if enemy.has_method("get_path_body_probe_scale"):
			_expect(enemy.get_path_body_probe_scale() > 0.0, "%s should resolve positive path body probe scale" % path)
		if enemy.has_method("get_path_stuck_time"):
			_expect(enemy.get_path_stuck_time() > 0.0, "%s should resolve positive path stuck time" % path)
		_expect(not ids.has(enemy.id), "Enemy id should be unique: %s" % enemy.id)
		ids.append(enemy.id)
	_expect(ids.size() >= 8, "Enemy resources should include several first-pass monster types")


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
	var source := FileAccess.get_file_as_string("res://docs/map_architecture.md")
	_expect(not source.is_empty(), "Map architecture documentation should exist")
	_expect(source.find("MapData") >= 0, "Map architecture documentation should describe MapData")
	_expect(source.find("ArenaVisual") >= 0, "Map architecture documentation should describe ArenaVisual")
	_expect(source.find("ArenaBounds") >= 0, "Map architecture documentation should describe ArenaBounds")
	_expect(source.find("WorldCollisionLayer") >= 0, "Map architecture documentation should describe collision layer ownership")
	_expect(source.find("HazardAreaLayer") >= 0, "Map architecture documentation should describe hazard layer ownership")


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


func _has_common_rare_epic(rarities: Array[int]) -> bool:
	return (
		rarities.has(UpgradeOptionData.Rarity.COMMON)
		and rarities.has(UpgradeOptionData.Rarity.RARE)
		and rarities.has(UpgradeOptionData.Rarity.EPIC)
	)


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
