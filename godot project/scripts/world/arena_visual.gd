class_name ArenaVisual
extends Node2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const ArenaVisualDrawLayerScript = preload("res://scripts/world/arena_visual_draw_layer.gd")

const DRAW_LAYER_GROUND_BASE := 0
const DRAW_LAYER_GROUND_DETAIL := 1
const DRAW_LAYER_NEON_DETAIL := 2
const DRAW_LAYER_BOUNDARY_VISUAL := 3

const LAYER_DEFINITIONS := [
	{"name": "GroundBaseLayer", "z_index": -80},
	{"name": "GroundDetailLayer", "z_index": -70},
	{"name": "NeonDetailLayer", "z_index": -60},
	{"name": "PropVisualLayer", "z_index": -20},
	{"name": "HazardVisualLayer", "z_index": -10},
	{"name": "BoundaryVisualLayer", "z_index": 40},
	{"name": "WorldCollisionLayer", "z_index": 50},
	{"name": "HazardAreaLayer", "z_index": 60},
]

@export var run_tuning: RunTuningData = preload("res://resources/runs/default_run_tuning.tres")
@export var visual_data: Resource = preload("res://resources/world/visuals/default_arena_visual.tres")

var _layers: Dictionary = {}
var _draw_layers: Array[Node2D] = []


func _ready() -> void:
	_ensure_layers()
	_configure_draw_layers()
	_rebuild_obstacles()
	_rebuild_hazards()


func configure(tuning: RunTuningData, data: Resource = null) -> void:
	run_tuning = tuning
	if data != null:
		visual_data = data
	_ensure_layers()
	_configure_draw_layers()
	_rebuild_obstacles()
	_rebuild_hazards()


func _ensure_layers() -> void:
	_layers.clear()
	for layer_definition in LAYER_DEFINITIONS:
		var layer_name := String(layer_definition["name"])
		var layer := get_node_or_null(layer_name) as Node2D
		if layer == null:
			layer = _create_layer(layer_name)
			add_child(layer)
		layer.z_index = int(layer_definition["z_index"])
		layer.y_sort_enabled = false
		_layers[layer_name] = layer

	_ensure_draw_layer("GroundBaseLayer", DRAW_LAYER_GROUND_BASE)
	_ensure_draw_layer("GroundDetailLayer", DRAW_LAYER_GROUND_DETAIL)
	_ensure_draw_layer("NeonDetailLayer", DRAW_LAYER_NEON_DETAIL)
	_ensure_draw_layer("BoundaryVisualLayer", DRAW_LAYER_BOUNDARY_VISUAL)


func _create_layer(layer_name: String) -> Node2D:
	var layer := Node2D.new()
	layer.name = layer_name
	return layer


func _ensure_draw_layer(layer_name: String, layer_kind: int) -> void:
	var layer := _layers[layer_name] as Node2D
	var draw_layer := layer.get_node_or_null("DrawLayer") as Node2D
	if draw_layer == null:
		draw_layer = ArenaVisualDrawLayerScript.new()
		draw_layer.name = "DrawLayer"
		layer.add_child(draw_layer)
	draw_layer.set("layer_kind", layer_kind)
	if not _draw_layers.has(draw_layer):
		_draw_layers.append(draw_layer)


func _configure_draw_layers() -> void:
	for draw_layer in _draw_layers:
		if is_instance_valid(draw_layer):
			draw_layer.call("configure", run_tuning, visual_data)


func _rebuild_obstacles() -> void:
	_clear_layer("PropVisualLayer")
	_clear_layer("WorldCollisionLayer")

	if visual_data == null:
		return

	var obstacles: Array = visual_data.get("obstacles")
	var obstacle_index := 0
	for obstacle_data in obstacles:
		if obstacle_data == null:
			continue
		_add_obstacle(obstacle_data, obstacle_index)
		obstacle_index += 1


func _rebuild_hazards() -> void:
	_clear_layer("HazardVisualLayer")
	_clear_layer("HazardAreaLayer")

	if visual_data == null:
		return

	var hazards: Array = visual_data.get("hazards")
	var hazard_index := 0
	for hazard_data in hazards:
		if hazard_data == null:
			continue
		_add_hazard(hazard_data, hazard_index)
		hazard_index += 1


func _add_obstacle(obstacle_data: Resource, obstacle_index: int) -> void:
	var collision_layer := _layers["WorldCollisionLayer"] as Node2D
	var visual_layer := _layers["PropVisualLayer"] as Node2D
	if collision_layer == null or visual_layer == null:
		return

	var obstacle_position: Vector2 = obstacle_data.get("position")
	var obstacle_size: Vector2 = obstacle_data.get("size")
	var obstacle_color: Color = obstacle_data.get("color")

	var obstacle := StaticBody2D.new()
	obstacle.name = "Obstacle_%02d" % [obstacle_index + 1]
	obstacle.collision_layer = CollisionLayers.WORLD
	obstacle.collision_mask = 0
	obstacle.position = obstacle_position

	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = obstacle_size
	shape.shape = rectangle
	obstacle.add_child(shape)
	collision_layer.add_child(obstacle)

	var visual := Polygon2D.new()
	visual.name = "ObstacleVisual_%02d" % [obstacle_index + 1]
	visual.position = obstacle_position
	var half_size: Vector2 = obstacle_size * 0.5
	visual.color = obstacle_color
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	visual_layer.add_child(visual)


func _add_hazard(hazard_data: Resource, hazard_index: int) -> void:
	var area_layer := _layers["HazardAreaLayer"] as Node2D
	var visual_layer := _layers["HazardVisualLayer"] as Node2D
	if area_layer == null or visual_layer == null:
		return

	var hazard_position: Vector2 = hazard_data.get("position")
	var hazard_size: Vector2 = hazard_data.get("size")
	var hazard_color: Color = hazard_data.get("color")

	var hazard := Area2D.new()
	hazard.name = "Hazard_%02d" % [hazard_index + 1]
	hazard.collision_layer = 0
	hazard.collision_mask = CollisionLayers.PLAYER
	hazard.monitoring = true
	hazard.monitorable = false
	hazard.position = hazard_position

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var rectangle := RectangleShape2D.new()
	rectangle.size = hazard_size
	shape.shape = rectangle
	hazard.add_child(shape)

	var visual := Polygon2D.new()
	visual.name = "HazardVisual_%02d" % [hazard_index + 1]
	visual.position = hazard_position
	var half_size: Vector2 = hazard_size * 0.5
	visual.color = hazard_color
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	visual_layer.add_child(visual)

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

	area_layer.add_child(hazard)


func _clear_layer(layer_name: String) -> void:
	var layer := _layers.get(layer_name) as Node
	if layer == null:
		return
	for child in layer.get_children():
		if child.get_script() == ArenaVisualDrawLayerScript:
			continue
		layer.remove_child(child)
		child.queue_free()
