extends SceneTree

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")

class DamageProbe:
	extends CharacterBody2D

	var damage_taken: float = 0.0

	func take_damage(amount: float) -> void:
		damage_taken += amount

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var arena := _instantiate_scene("res://scenes/environment/arena_visual.tscn") as ArenaVisual
	if arena == null:
		_finish()
		return

	root.add_child(arena)
	var hazard_area_layer := arena.get_node_or_null("HazardAreaLayer")
	_expect(hazard_area_layer != null, "ArenaVisual should isolate hazard gameplay areas in HazardAreaLayer")
	var hazards := _collect_hazards(arena)
	_expect(not hazards.is_empty(), "ArenaVisual should create resource-driven hazards")
	if not hazards.is_empty():
		var hazard := hazards[0]
		_expect(hazard.collision_layer == 0, "ArenaVisual hazard should not block physical movement")
		_expect(hazard.collision_mask == CollisionLayers.PLAYER, "ArenaVisual hazard should only scan player layer")

		var shape := hazard.get_node_or_null("CollisionShape2D") as CollisionShape2D
		_expect(shape != null and shape.shape is RectangleShape2D, "ArenaVisual hazard should create a rectangle collision shape")

		var timer := hazard.get_node_or_null("DamageTimer") as Timer
		_expect(timer != null, "ArenaVisual hazard should create a periodic damage timer")
		if timer != null:
			var probe := DamageProbe.new()
			probe.collision_layer = CollisionLayers.PLAYER
			root.add_child(probe)
			hazard.body_entered.emit(probe)
			timer.timeout.emit()
			_expect(is_equal_approx(probe.damage_taken, 8.0), "ArenaVisual hazard should apply resource damage on timer tick")
			hazard.body_exited.emit(probe)
			timer.timeout.emit()
			_expect(is_equal_approx(probe.damage_taken, 8.0), "ArenaVisual hazard should stop damaging bodies after exit")
			root.remove_child(probe)
			probe.free()

	root.remove_child(arena)
	arena.free()
	_finish()


func _collect_hazards(node: Node) -> Array[Area2D]:
	var hazards: Array[Area2D] = []
	var hazard_area_layer := node.get_node_or_null("HazardAreaLayer")
	if hazard_area_layer == null:
		return hazards
	for child in _collect_descendants(hazard_area_layer):
		if child is Area2D and child.name.begins_with("Hazard"):
			hazards.append(child)
	return hazards


func _collect_descendants(node: Node) -> Array[Node]:
	var descendants: Array[Node] = []
	for child in node.get_children():
		descendants.append(child)
		descendants.append_array(_collect_descendants(child))
	return descendants


func _instantiate_scene(scene_path: String) -> Node:
	var packed_scene := load(scene_path) as PackedScene
	if packed_scene == null:
		_failures.append("Failed to load %s" % scene_path)
		return null

	var instance := packed_scene.instantiate()
	if instance == null:
		_failures.append("Failed to instantiate %s" % scene_path)
	return instance


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("arena_hazard_check passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)
