class_name WorldMapChecks
extends RefCounted


func check_arena_bounds_scene(ctx, collision_layers) -> void:
	var instance: Node = ctx.instantiate_scene("res://scenes/world/arena_bounds.tscn")
	if instance == null:
		return

	ctx.root.add_child(instance)
	ctx.expect(instance.get_child_count() == 4, "ArenaBounds should create four world walls")
	for child in instance.get_children():
		var wall := child as StaticBody2D
		if wall == null:
			ctx.failures.append("ArenaBounds child %s is not StaticBody2D" % child.name)
		else:
			ctx.expect(wall.collision_layer == collision_layers.WORLD, "ArenaBounds wall %s should use WORLD layer" % wall.name)
			ctx.expect(wall.collision_mask == 0, "ArenaBounds wall %s should not scan masks" % wall.name)
	ctx.remove_instance(instance)


func check_arena_visual_scene(ctx, collision_layers) -> void:
	var instance: Node = ctx.instantiate_scene("res://scenes/world/arena_visual.tscn")
	if instance == null:
		return

	ctx.root.add_child(instance)
	var expected_layers := [
		"GroundBaseLayer",
		"GroundDetailLayer",
		"NeonDetailLayer",
		"PropVisualLayer",
		"ObstacleVisualLayer",
		"HazardVisualLayer",
		"BoundaryVisualLayer",
		"WorldCollisionLayer",
		"HazardAreaLayer",
	]
	var previous_z_index := -1000000
	for layer_name in expected_layers:
		var layer := instance.get_node_or_null(layer_name) as Node2D
		ctx.expect(layer != null, "ArenaVisual should include %s" % layer_name)
		if layer != null:
			ctx.expect(layer.z_index > previous_z_index, "ArenaVisual layer %s should keep stable ascending z_index order" % layer_name)
			previous_z_index = layer.z_index

	var world_collision_layer: Node = instance.get_node_or_null("WorldCollisionLayer")
	ctx.expect(world_collision_layer != null, "ArenaVisual should isolate obstacle collision in WorldCollisionLayer")
	var obstacle_count := 0
	for child in ctx.collect_descendants(world_collision_layer):
		if child is StaticBody2D:
			obstacle_count += 1
			var obstacle := child as StaticBody2D
			ctx.expect(obstacle.collision_layer == collision_layers.WORLD, "ArenaVisual obstacle %s should use WORLD layer" % obstacle.name)
			ctx.expect(obstacle.collision_mask == 0, "ArenaVisual obstacle %s should not scan masks" % obstacle.name)
	ctx.expect(obstacle_count >= 0, "ArenaVisual should allow map styles without resource-driven obstacles")
	ctx.remove_instance(instance)


func check_arena_tile_layers(ctx) -> void:
	var map_data := load("res://resources/maps/default_map.tres")
	ctx.expect(map_data != null, "Default map data should exist before tile layer check")
	if map_data == null:
		return

	var instance := ctx.instantiate_scene("res://scenes/world/arena_visual.tscn") as ArenaVisual
	if instance == null:
		return

	ctx.root.add_child(instance)
	instance.configure(map_data.get("run_tuning"), map_data.get("visual_data"), map_data.get("tile_library"), map_data.get("tile_layout"))
	var map_background := instance.get_node_or_null("GroundBaseLayer/MapBackground")
	var ground_base := instance.get_node_or_null("GroundBaseLayer/GeneratedBaseTiles")
	var ground_detail := instance.get_node_or_null("GroundDetailLayer/GeneratedDetailTiles")
	var decals := instance.get_node_or_null("GroundDetailLayer/GeneratedDecals")
	var neon := instance.get_node_or_null("NeonDetailLayer/GeneratedNeonTiles")
	var prop_visual_count := 0
	var obstacle_visual_count := 0
	var placed_obstacle_count := 0
	var prop_visual_layer := instance.get_node_or_null("PropVisualLayer")
	var obstacle_visual_layer := instance.get_node_or_null("ObstacleVisualLayer")
	var world_collision_layer := instance.get_node_or_null("WorldCollisionLayer")
	var hazard_texture_count := 0
	var hazard_visual_layer := instance.get_node_or_null("HazardVisualLayer")
	for child in ctx.collect_descendants(hazard_visual_layer):
		if child is Sprite2D and child.name.begins_with("HazardTexture"):
			hazard_texture_count += 1
	for child in ctx.collect_descendants(prop_visual_layer):
		if child is Sprite2D and (child.name.begins_with("RandomProp") or child.name.begins_with("ArenaProp")):
			prop_visual_count += 1
		ctx.expect(not (child is Sprite2D and child.name.begins_with("RandomObstacleVisual")), "Obstacle visuals should not live in PropVisualLayer")
	for child in ctx.collect_descendants(obstacle_visual_layer):
		if child is Sprite2D and (child.name.begins_with("RandomObstacleVisual") or child.name.begins_with("ArenaObstacleVisual")):
			obstacle_visual_count += 1
	for child in ctx.collect_descendants(world_collision_layer):
		if child is StaticBody2D and (child.name.begins_with("RandomObstacle") or child.name.begins_with("ArenaObstacle")):
			placed_obstacle_count += 1
			var shape := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
			ctx.expect(shape != null, "Ancient arena generated obstacle %s should include a collision shape" % child.name)
			if shape != null:
				var rectangle := shape.shape as RectangleShape2D
				ctx.expect(rectangle != null, "Ancient arena generated obstacle %s should use rectangle collision" % child.name)
				ctx.expect(shape.position.y > 0.0, "Ancient arena generated obstacle %s should collide at the bottom footprint" % child.name)
				if rectangle != null:
					ctx.expect(rectangle.size.y < 220.0, "Ancient arena generated obstacle %s collision should not cover the full tall sprite" % child.name)

	ctx.expect(map_background == null, "Ancient arena map should not use the discarded generated full-map background")
	ctx.expect(ground_base == null, "Ancient arena map should remove unsuitable open-source base floor TileMap cells")
	ctx.expect(ground_detail == null, "Cyber test zone should not generate old ground detail tiles")
	ctx.expect(decals == null, "Cyber test zone should not generate old decal tiles")
	ctx.expect(neon == null, "Cyber test zone should not generate old neon detail tiles")
	ctx.expect(prop_visual_count == 0, "Ancient arena map should remove generated AI decorative props")
	ctx.expect(obstacle_visual_count == 0, "Ancient arena map should remove generated AI obstacle props")
	ctx.expect(obstacle_visual_layer != null, "Ancient arena map should keep obstacle visuals on a dedicated layer")
	ctx.expect(placed_obstacle_count == 0, "Ancient arena map should remove generated AI obstacle collision bodies")
	ctx.expect(hazard_texture_count == 0, "Cyber test zone should hide placeholder hazard sticker textures")
	ctx.remove_instance(instance)


func check_arena_hazards(ctx, collision_layers) -> void:
	var instance: Node = ctx.instantiate_scene("res://scenes/world/arena_visual.tscn")
	if instance == null:
		return

	ctx.root.add_child(instance)
	var hazard_area_layer: Node = instance.get_node_or_null("HazardAreaLayer")
	ctx.expect(hazard_area_layer != null, "ArenaVisual should isolate hazard gameplay areas in HazardAreaLayer")
	var hazards: Array[Area2D] = []
	for child in ctx.collect_descendants(hazard_area_layer):
		if child is Area2D and child.name.begins_with("Hazard"):
			hazards.append(child)
	ctx.expect(hazards.is_empty(), "Cyber test zone should not create old resource-driven hazards")
	if not hazards.is_empty():
		var hazard := hazards[0]
		ctx.expect(hazard.collision_layer == 0, "ArenaVisual hazard should not block physical movement")
		ctx.expect(hazard.collision_mask == collision_layers.PLAYER, "ArenaVisual hazard should only scan player layer")
		ctx.expect(hazard.get_node_or_null("DamageTimer") != null, "ArenaVisual hazard should create periodic damage timer")
	ctx.remove_instance(instance)


func check_world_resource_grouping(ctx) -> void:
	var map_data_source := FileAccess.get_file_as_string("res://resources/maps/map_data.gd")
	ctx.expect(map_data_source.find("res://resources/world/visuals/arena_visual_data.gd") >= 0, "MapData should preload ArenaVisualData from resources/world/visuals")

	var arena_visual_source := FileAccess.get_file_as_string("res://scripts/world/arena_visual.gd")
	ctx.expect(arena_visual_source.find("res://resources/world/visuals/default_arena_visual.tres") >= 0, "ArenaVisual should load default visual data from resources/world/visuals")

	var default_map = load("res://resources/maps/default_map.tres")
	if default_map != null and default_map.visual_data != null:
		var visual_path := String(default_map.visual_data.resource_path)
		ctx.expect(visual_path.contains("/resources/world/visuals/"), "Default map visual resource should live under resources/world/visuals")

	var default_visual = load("res://resources/world/visuals/default_arena_visual.tres")
	ctx.expect(default_visual != null, "Default arena visual resource should exist under resources/world/visuals")
	if default_visual != null:
		for obstacle in default_visual.obstacles:
			if obstacle == null:
				continue
			var obstacle_path := String(obstacle.resource_path)
			ctx.expect(obstacle_path.contains("/resources/world/obstacles/"), "ArenaVisualData obstacles should live under resources/world/obstacles")
		for hazard in default_visual.hazards:
			if hazard == null:
				continue
			var hazard_path := String(hazard.resource_path)
			ctx.expect(hazard_path.contains("/resources/world/hazards/"), "ArenaVisualData hazards should live under resources/world/hazards")

	ctx.expect(FileAccess.file_exists("res://resources/world/visuals/arena_visual_data.gd"), "ArenaVisualData script should live under resources/world/visuals")
	ctx.expect(FileAccess.file_exists("res://resources/world/hazards/hazard_data.gd"), "HazardData script should live under resources/world/hazards")
	ctx.expect(FileAccess.file_exists("res://resources/world/obstacles/obstacle_data.gd"), "ObstacleData script should live under resources/world/obstacles")


func check_default_map_data(ctx) -> void:
	var map_data := load("res://resources/maps/default_map.tres")
	ctx.expect(map_data != null, "Default map data should exist")
	if map_data == null:
		return

	ctx.expect(map_data.get("id") == &"cyber_test_zone", "Default map should point to the first playable cyber test zone")
	ctx.expect(map_data.get("display_name") == "破损古代竞技场", "Default map display name should describe the ancient arena style")
	ctx.expect(map_data.get("run_tuning") != null, "Default map data should reference run tuning")
	ctx.expect(map_data.get("visual_data") != null, "Default map data should reference arena visual data")
	var run_tuning := map_data.get("run_tuning") as RunTuningData
	if run_tuning != null:
		ctx.expect(run_tuning.arena_half_extents.x >= 3600.0, "First playable map should be wide enough for survivor-style roaming")
		ctx.expect(run_tuning.arena_half_extents.y >= 2200.0, "First playable map should be tall enough for survivor-style roaming")
		ctx.expect(run_tuning.minimum_spawn_distance < run_tuning.spawn_radius, "First playable map should leave spawn ring space")
	var visual_data: Resource = map_data.get("visual_data") as Resource
	if visual_data != null:
		var obstacles: Array = visual_data.get("obstacles") as Array
		var hazards: Array = visual_data.get("hazards") as Array
		ctx.expect(obstacles.is_empty(), "First playable map should remove old decorative obstacle chunks before the new style pass")
		ctx.expect(hazards.is_empty(), "First playable map should remove old decorative hazards before the new style pass")
	ctx.expect(map_data.get("tile_library") != null, "Default map data should reference a tile library")
	ctx.expect(map_data.get("tile_layout") != null, "Default map data should reference a tile layout")

	var run_manager_source := FileAccess.get_file_as_string("res://scripts/run/run_manager.gd")
	ctx.expect(run_manager_source.find("@export var map_data") >= 0, "RunManager should expose a single map_data selection resource")
	ctx.expect(run_manager_source.find("map_data.get(\"run_tuning\")") >= 0, "RunManager should read run tuning from map_data")
	ctx.expect(run_manager_source.find("map_data.get(\"visual_data\")") >= 0, "RunManager should read arena visuals from map_data")
	ctx.expect(run_manager_source.find("map_data.get(\"tile_library\")") >= 0, "RunManager should read tile library from map_data")
	ctx.expect(run_manager_source.find("map_data.get(\"tile_layout\")") >= 0, "RunManager should read tile layout from map_data")


func check_default_map_tile_library(ctx) -> void:
	var map_data := load("res://resources/maps/default_map.tres")
	if map_data == null:
		return

	var tile_library: Resource = map_data.get("tile_library") as Resource
	ctx.expect(tile_library != null, "Default map tile library should exist")
	if tile_library == null:
		return

	ctx.expect(tile_library.get("tile_size") == Vector2i(256, 256), "Ancient arena should reset tile metadata after removing unsuitable open-source tiles")
	var background_texture_path := String(tile_library.get("background_texture_path"))
	ctx.expect(background_texture_path.is_empty(), "Ancient arena should not reference the discarded generated full-map background")
	ctx.expect((tile_library.get("ground_base_tile_paths") as Array).is_empty(), "Ancient arena should remove unsuitable open-source base ground tile paths")
	ctx.expect((tile_library.get("ground_detail_tiles") as Array).is_empty(), "Cyber test zone should remove old detail ground tiles")
	ctx.expect((tile_library.get("neon_detail_tiles") as Array).is_empty(), "Cyber test zone should remove old neon detail tiles")
	ctx.expect((tile_library.get("decals") as Array).is_empty(), "Cyber test zone should remove old decal assets")
	ctx.expect((tile_library.get("hazard_visuals") as Array).is_empty(), "Cyber test zone should remove old hazard visual assets")
	ctx.expect((tile_library.get("hazard_ground_tiles") as Array).is_empty(), "Cyber test zone should remove old hazard ground tile assets")
	ctx.expect((tile_library.get("prop_visual_paths") as Array).is_empty(), "Ancient arena should remove generated decorative prop texture paths")
	ctx.expect((tile_library.get("obstacle_visual_paths") as Array).is_empty(), "Ancient arena should remove generated obstacle texture paths")

	for property_name in [
		"ground_base_tiles",
		"ground_detail_tiles",
		"neon_detail_tiles",
		"decals",
		"hazard_visuals",
		"hazard_ground_tiles",
		"prop_visuals",
		"obstacle_visuals",
	]:
		for texture in tile_library.get(property_name):
			ctx.expect(texture is Texture2D, "Map tile library %s should only contain Texture2D entries" % property_name)

	for property_name in [
		"ground_base_tile_paths",
		"prop_visual_paths",
		"obstacle_visual_paths",
	]:
		for texture_path in tile_library.get(property_name):
			ctx.expect(FileAccess.file_exists(String(texture_path)), "Map tile library path should exist: %s" % String(texture_path))

	var tile_layout: Resource = map_data.get("tile_layout") as Resource
	ctx.expect(tile_layout != null, "Default map tile layout should exist")
	if tile_layout != null:
		ctx.expect(bool(tile_layout.get("use_curated_arena_layout")), "First playable map should use curated arena tile placement instead of full random scatter")
		ctx.expect(not bool(tile_layout.get("draw_background_texture")), "Ancient arena should not draw the discarded generated full-map background")
		ctx.expect(tile_layout.get("background_world_margin") == Vector2.ZERO, "Ancient arena should not reserve margin for generated backgrounds")
		ctx.expect(bool(tile_layout.get("draw_ground_base_color")), "Ancient arena should draw a temporary base color after removing unsuitable tiles")
		ctx.expect(not bool(tile_layout.get("draw_base_tiles")), "Ancient arena should not render unsuitable open-source repeated base TileMap")
		ctx.expect(tile_layout.get("tile_world_size") == Vector2(256.0, 256.0), "Cyber test zone should reset tile world size after removing unsuitable tiles")
		ctx.expect(tile_layout.get("base_tile_texture_size") == Vector2i(256, 256), "Ancient arena should reset tile source metadata after removing unsuitable tiles")
		ctx.expect(tile_layout.get("base_source_cell_size") == Vector2i.ZERO, "Ancient arena fallback tile mode should draw complete cut tile textures")
		ctx.expect(is_zero_approx(float(tile_layout.get("tile_edge_overlap"))), "Tile layout should not rely on overlap once source tiles are square")
		ctx.expect(is_equal_approx(float(tile_layout.get("base_tile_draw_scale")), 1.0), "Base floor tiles should not visually overlap after alpha bleed padding")
		ctx.expect(not bool(tile_layout.get("base_tile_alpha_bleed")), "Base floor tiles should be preprocessed instead of alpha-bleeding at runtime")
		ctx.expect(not bool(tile_layout.get("base_dual_grid_enabled")), "Base floor should not use overlapping dual grids after edge padding")
		ctx.expect(tile_layout.get("ground_detail_spacing") is Vector2i, "Tile layout should configure ground detail spacing")
		ctx.expect(tile_layout.get("decal_spacing") is Vector2i, "Tile layout should configure decal spacing")
		ctx.expect(tile_layout.get("neon_spacing") is Vector2i, "Tile layout should configure neon spacing")
		ctx.expect(not bool(tile_layout.get("draw_procedural_neon_lines")), "Cyber test zone should disable procedural long neon guide lines")
		ctx.expect(not bool(tile_layout.get("draw_hazard_textures")), "Cyber test zone should not show placeholder hazard sticker textures")
		ctx.expect(is_zero_approx(float(tile_layout.get("hazard_fill_alpha"))), "Cyber test zone should not draw solid colored hazard rectangles")
		ctx.expect(int(tile_layout.get("random_prop_count")) == 0, "Ancient arena should remove random decorative prop placement until a suitable prop set is selected")
		ctx.expect(int(tile_layout.get("random_obstacle_count")) == 0, "Ancient arena should remove generated obstacle placement until a suitable obstacle set is selected")


func check_game_root_scene(ctx) -> void:
	var instance: Node = ctx.instantiate_scene("res://scenes/main/game_root.tscn")
	if instance == null:
		return

	ctx.root.add_child(instance)
	ctx.expect(instance.get_node_or_null("ArenaVisual") != null, "GameRoot should include ArenaVisual")
	ctx.expect(instance.get_node_or_null("ArenaBounds") != null, "GameRoot should include ArenaBounds")
	ctx.expect(instance.get_node_or_null("Pickups") != null, "GameRoot should include Pickups container")
	ctx.remove_instance(instance)


func check_map_documentation(ctx) -> void:
	var source := FileAccess.get_file_as_string("res://docs/architecture/map_architecture.md")
	ctx.expect(not source.is_empty(), "Map architecture documentation should exist")
	ctx.expect(source.find("MapData") >= 0, "Map architecture documentation should describe MapData")
	ctx.expect(source.find("ArenaVisual") >= 0, "Map architecture documentation should describe ArenaVisual")
	ctx.expect(source.find("ArenaBounds") >= 0, "Map architecture documentation should describe ArenaBounds")
	ctx.expect(source.find("WorldCollisionLayer") >= 0, "Map architecture documentation should describe collision layer ownership")
	ctx.expect(source.find("HazardAreaLayer") >= 0, "Map architecture documentation should describe hazard layer ownership")


func check_legacy_paths_removed(ctx) -> void:
	for legacy_path in [
		"res://docs/map_architecture.md",
		"res://docs/project_structure.md",
		"res://docs/character_asset_spec.md",
		"res://docs/character_node_structure.md",
		"res://resources/world/default_arena_visual.tres",
		"res://resources/world/cyber_test_zone_visual.tres",
		"res://resources/world/arena_visual_data.gd",
		"res://resources/world/hazard_data.gd",
		"res://resources/world/obstacle_data.gd",
		"res://resources/upgrades/default_upgrade_pool.tres",
		"res://resources/upgrades/default_module_skill_pool.tres",
		"res://resources/upgrades/default_general_skill_pool.tres",
		"res://resources/modules/fire_burst.tres",
		"res://resources/modules/fire_quick_single.tres",
		"res://resources/modules/fire_single_shot.tres",
		"res://resources/modules/fire_spread.tres",
		"res://resources/modules/payload_explosive.tres",
		"res://resources/modules/payload_normal.tres",
		"res://resources/modules/payload_piercing.tres",
	]:
		ctx.expect(not FileAccess.file_exists(legacy_path), "Legacy path should be removed: %s" % legacy_path)
