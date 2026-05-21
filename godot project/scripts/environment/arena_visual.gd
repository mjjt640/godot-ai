class_name ArenaVisual
extends Node2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")

@export var run_tuning: RunTuningData = preload("res://resources/runs/default_run_tuning.tres")
@export var visual_data: Resource = preload("res://resources/environment/default_arena_visual.tres")

var _obstacle_nodes: Array[Node2D] = []
var _hazard_nodes: Array[Area2D] = []


func _ready() -> void:
	_rebuild_obstacles()
	_rebuild_hazards()


func configure(tuning: RunTuningData) -> void:
	run_tuning = tuning
	queue_redraw()
	_rebuild_obstacles()
	_rebuild_hazards()


func _draw() -> void:
	if run_tuning == null or visual_data == null:
		return

	var half_extents := run_tuning.arena_half_extents
	var rect := Rect2(-half_extents, half_extents * 2.0)
	draw_rect(rect, visual_data.get("arena_color"), true)
	_draw_grid(rect)
	draw_rect(rect, visual_data.get("boundary_color"), false, float(visual_data.get("boundary_line_width")))


func _draw_grid(rect: Rect2) -> void:
	var grid_size: float = float(visual_data.get("grid_size"))
	if grid_size <= 0.0:
		return

	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), visual_data.get("grid_color"), 1.0)
		x += grid_size

	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), visual_data.get("grid_color"), 1.0)
		y += grid_size


func _rebuild_obstacles() -> void:
	for obstacle_node in _obstacle_nodes:
		if is_instance_valid(obstacle_node):
			remove_child(obstacle_node)
			obstacle_node.queue_free()
	_obstacle_nodes.clear()

	if visual_data == null:
		return

	var obstacles: Array = visual_data.get("obstacles")
	for obstacle_data in obstacles:
		if obstacle_data == null:
			continue
		_add_obstacle(obstacle_data)


func _rebuild_hazards() -> void:
	for hazard_node in _hazard_nodes:
		if is_instance_valid(hazard_node):
			remove_child(hazard_node)
			hazard_node.queue_free()
	_hazard_nodes.clear()

	if visual_data == null:
		return

	var hazards: Array = visual_data.get("hazards")
	for hazard_data in hazards:
		if hazard_data == null:
			continue
		_add_hazard(hazard_data)


func _add_obstacle(obstacle_data: Resource) -> void:
	var obstacle := StaticBody2D.new()
	obstacle.name = "Obstacle"
	obstacle.collision_layer = CollisionLayers.WORLD
	obstacle.collision_mask = 0
	obstacle.position = obstacle_data.get("position")

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	var obstacle_size: Vector2 = obstacle_data.get("size")
	rectangle.size = obstacle_size
	shape.shape = rectangle
	obstacle.add_child(shape)

	var visual := Polygon2D.new()
	var half_size: Vector2 = obstacle_size * 0.5
	visual.color = obstacle_data.get("color")
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	obstacle.add_child(visual)

	add_child(obstacle)
	_obstacle_nodes.append(obstacle)


func _add_hazard(hazard_data: Resource) -> void:
	var hazard := Area2D.new()
	hazard.name = "Hazard"
	hazard.collision_layer = 0
	hazard.collision_mask = CollisionLayers.PLAYER
	hazard.monitoring = true
	hazard.monitorable = false
	hazard.position = hazard_data.get("position")

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	var hazard_size: Vector2 = hazard_data.get("size")
	rectangle.size = hazard_size
	shape.shape = rectangle
	hazard.add_child(shape)

	var visual := Polygon2D.new()
	var half_size: Vector2 = hazard_size * 0.5
	visual.color = hazard_data.get("color")
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	hazard.add_child(visual)

	var timer := Timer.new()
	timer.name = "DamageTimer"
	timer.wait_time = max(float(hazard_data.get("trigger_interval")), 0.05)
	timer.one_shot = false
	timer.autostart = false
	hazard.add_child(timer)

	var tracked_bodies: Array[Node] = []
	hazard.body_entered.connect(func(body: Node) -> void:
		if body.has_method("take_damage") and not tracked_bodies.has(body):
			tracked_bodies.append(body)
		if not tracked_bodies.is_empty() and timer.is_stopped():
			timer.start()
	)
	hazard.body_exited.connect(func(body: Node) -> void:
		tracked_bodies.erase(body)
		if tracked_bodies.is_empty():
			timer.stop()
	)
	timer.timeout.connect(func() -> void:
		for body in tracked_bodies.duplicate():
			if not is_instance_valid(body):
				tracked_bodies.erase(body)
				continue
			body.call("take_damage", float(hazard_data.get("damage")))
		if tracked_bodies.is_empty():
			timer.stop()
	)

	add_child(hazard)
	_hazard_nodes.append(hazard)
