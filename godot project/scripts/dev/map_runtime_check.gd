extends SceneTree

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var scene := load("res://scenes/main/game_root.tscn") as PackedScene
	if scene == null:
		_failures.append("Failed to load game_root.tscn")
		_finish()
		return

	var root_node := scene.instantiate()
	if root_node == null:
		_failures.append("Failed to instantiate game_root.tscn")
		_finish()
		return

	root.add_child(root_node)
	await process_frame
	await physics_frame

	var run_manager := root_node as RunManager
	_expect(run_manager != null, "GameRoot should use RunManager")
	if run_manager != null:
		_expect(run_manager.map_data != null, "RunManager should have map_data")
		if run_manager.map_data != null:
			_expect(run_manager.map_data.get("id") == &"cyber_test_zone", "Runtime map should be cyber_test_zone")
		_expect(run_manager.run_tuning.arena_half_extents == Vector2(3800.0, 2400.0), "Runtime arena should use cyber_test_zone size")
		_expect(run_manager.run_tuning.spawn_radius == 980.0, "Runtime spawn radius should come from cyber_test_zone")

	var arena_bounds := root_node.get_node_or_null("ArenaBounds")
	_expect(arena_bounds != null, "GameRoot should include ArenaBounds")
	if arena_bounds != null:
		_expect(arena_bounds.get_child_count() == 4, "ArenaBounds should create four walls")

	var arena_visual := root_node.get_node_or_null("ArenaVisual")
	_expect(arena_visual != null, "GameRoot should include ArenaVisual")
	if arena_visual != null:
		var world_collision_layer := arena_visual.get_node_or_null("WorldCollisionLayer")
		var hazard_area_layer := arena_visual.get_node_or_null("HazardAreaLayer")
		var map_background := arena_visual.get_node_or_null("GroundBaseLayer/MapBackground")
		var ground_base_layer := arena_visual.get_node_or_null("GroundBaseLayer/GeneratedBaseTiles")
		var detail_layer := arena_visual.get_node_or_null("GroundDetailLayer/GeneratedDetailTiles")
		var decal_layer := arena_visual.get_node_or_null("GroundDetailLayer/GeneratedDecals")
		var neon_layer := arena_visual.get_node_or_null("NeonDetailLayer/GeneratedNeonTiles")
		_expect(world_collision_layer != null, "ArenaVisual should include WorldCollisionLayer")
		_expect(hazard_area_layer != null, "ArenaVisual should include HazardAreaLayer")
		_expect(map_background == null, "Runtime map should not use the discarded generated background image")
		_expect(ground_base_layer == null, "Runtime map should remove unsuitable open-source floor tile visuals")
		_expect(detail_layer == null, "Runtime map should not generate old detail tile visuals")
		_expect(decal_layer == null, "Runtime map should not generate old decal visuals")
		_expect(neon_layer == null, "Runtime map should not generate old neon tile visuals")

		var obstacle_count := 0
		for child in _collect_descendants(world_collision_layer):
			if child is StaticBody2D:
				obstacle_count += 1
				_expect(child.collision_layer == CollisionLayers.WORLD, "Runtime obstacles should use WORLD layer")
				_expect(child.collision_mask == 0, "Runtime obstacles should not scan masks")
				if child.name.begins_with("ArenaObstacle") or child.name.begins_with("RandomObstacle"):
					var shape := child.get_node_or_null("CollisionShape2D") as CollisionShape2D
					_expect(shape != null, "Runtime generated obstacles should include a collision shape")
					if shape != null:
						var rectangle := shape.shape as RectangleShape2D
						_expect(rectangle != null, "Runtime generated obstacle collision should use a rectangle shape")
						_expect(shape.position.y > 0.0, "Runtime generated obstacle collision should sit on the bottom footprint")
						if rectangle != null:
							_expect(rectangle.size.y < 220.0, "Runtime generated obstacle collision should not cover the full tall sprite")
		_expect(obstacle_count == 0, "Runtime map should remove generated AI obstacle collision bodies")

		var hazard_count := 0
		for child in _collect_descendants(hazard_area_layer):
			if child is Area2D and child.name.begins_with("Hazard"):
				hazard_count += 1
				_expect(child.collision_layer == 0, "Runtime hazards should not block movement")
				_expect(child.collision_mask == CollisionLayers.PLAYER, "Runtime hazards should scan player only")
		_expect(hazard_count == 0, "Runtime cyber_test_zone should remove old sparse hazards")

	root.remove_child(root_node)
	root_node.free()
	_finish()


func _collect_descendants(node: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	if node == null:
		return descendants
	for child in node.get_children():
		descendants.append(child)
		descendants.append_array(_collect_descendants(child))
	return descendants


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("map_runtime_check passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)
