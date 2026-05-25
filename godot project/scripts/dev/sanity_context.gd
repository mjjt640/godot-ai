class_name SanityContext
extends RefCounted

var tree: SceneTree
var root: Node
var failures: Array[String]
var removed_xp_movement_key: String


func _init(scene_tree: SceneTree, root_node: Node, failure_list: Array[String], removed_key: String) -> void:
	tree = scene_tree
	root = root_node
	failures = failure_list
	removed_xp_movement_key = removed_key


func expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)


func instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		failures.append("Failed to load %s" % scene_path)
		return null

	var instance := packed_scene.instantiate()
	if instance == null:
		failures.append("Failed to instantiate %s" % scene_path)
	return instance


func remove_instance(instance: Node) -> void:
	root.remove_child(instance)
	instance.free()


func collect_descendants(node: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	if node == null:
		return descendants
	for child in node.get_children():
		descendants.append(child)
		descendants.append_array(collect_descendants(child))
	return descendants


func create_test_world_obstacle(position: Vector2, size: Vector2, collision_layer: int) -> StaticBody2D:
	var obstacle := StaticBody2D.new()
	obstacle.name = "NavigationTestObstacle"
	obstacle.collision_layer = collision_layer
	obstacle.collision_mask = 0
	obstacle.global_position = position
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	shape.shape = rectangle
	obstacle.add_child(shape)
	return obstacle
