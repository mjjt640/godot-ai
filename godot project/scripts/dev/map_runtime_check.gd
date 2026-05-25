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
		_expect(run_manager.run_tuning.arena_half_extents == Vector2(2600.0, 1600.0), "Runtime arena should use cyber_test_zone size")
		_expect(run_manager.run_tuning.spawn_radius == 760.0, "Runtime spawn radius should come from cyber_test_zone")

	var arena_bounds := root_node.get_node_or_null("ArenaBounds")
	_expect(arena_bounds != null, "GameRoot should include ArenaBounds")
	if arena_bounds != null:
		_expect(arena_bounds.get_child_count() == 4, "ArenaBounds should create four walls")

	var arena_visual := root_node.get_node_or_null("ArenaVisual")
	_expect(arena_visual != null, "GameRoot should include ArenaVisual")
	if arena_visual != null:
		var world_collision_layer := arena_visual.get_node_or_null("WorldCollisionLayer")
		var hazard_area_layer := arena_visual.get_node_or_null("HazardAreaLayer")
		_expect(world_collision_layer != null, "ArenaVisual should include WorldCollisionLayer")
		_expect(hazard_area_layer != null, "ArenaVisual should include HazardAreaLayer")

		var obstacle_count := 0
		for child in _collect_descendants(world_collision_layer):
			if child is StaticBody2D:
				obstacle_count += 1
				_expect(child.collision_layer == CollisionLayers.WORLD, "Runtime obstacles should use WORLD layer")
				_expect(child.collision_mask == 0, "Runtime obstacles should not scan masks")
		_expect(obstacle_count == 10, "Runtime cyber_test_zone should create 10 simple obstacle chunks")

		var hazard_count := 0
		for child in _collect_descendants(hazard_area_layer):
			if child is Area2D and child.name.begins_with("Hazard"):
				hazard_count += 1
				_expect(child.collision_layer == 0, "Runtime hazards should not block movement")
				_expect(child.collision_mask == CollisionLayers.PLAYER, "Runtime hazards should scan player only")
		_expect(hazard_count == 2, "Runtime cyber_test_zone should create 2 sparse hazards")

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
