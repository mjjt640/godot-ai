class_name ArenaVisual
extends Node2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const ArenaVisualDrawLayerScript = preload("res://scripts/world/arena_visual_draw_layer.gd")
const ArenaTilePainterScript = preload("res://scripts/world/arena_tile_painter.gd")

const DRAW_LAYER_GROUND_BASE := 0
const DRAW_LAYER_GROUND_DETAIL := 1
const DRAW_LAYER_NEON_DETAIL := 2
const DRAW_LAYER_BOUNDARY_VISUAL := 3
const BACKGROUND_SPRITE_NAME := "MapBackground"

const LAYER_DEFINITIONS := [
	{"name": "GroundBaseLayer", "z_index": -80},
	{"name": "GroundDetailLayer", "z_index": -70},
	{"name": "NeonDetailLayer", "z_index": -60},
	{"name": "PropVisualLayer", "z_index": -20},
	{"name": "ObstacleVisualLayer", "z_index": -15},
	{"name": "HazardVisualLayer", "z_index": -10},
	{"name": "BoundaryVisualLayer", "z_index": 40},
	{"name": "WorldCollisionLayer", "z_index": 50},
	{"name": "HazardAreaLayer", "z_index": 60},
]

@export var run_tuning: RunTuningData = preload("res://resources/runs/default_run_tuning.tres")
@export var visual_data: Resource = preload("res://resources/world/visuals/default_arena_visual.tres")
@export var tile_library: Resource
@export var tile_layout: Resource

var _layers: Dictionary = {}
var _draw_layers: Array[Node2D] = []
var _tile_painter := ArenaTilePainterScript.new()


func _ready() -> void:
	_ensure_layers()
	_configure_draw_layers()
	_rebuild_background()
	_rebuild_tiles()
	_rebuild_obstacles()
	_rebuild_hazards()


func configure(tuning: RunTuningData, data: Resource = null, library: Resource = null, layout: Resource = null) -> void:
	run_tuning = tuning
	if data != null:
		visual_data = data
	tile_library = library
	tile_layout = layout
	_ensure_layers()
	_configure_draw_layers()
	_rebuild_background()
	_rebuild_tiles()
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
			draw_layer.call("configure", run_tuning, visual_data, tile_layout)


func _rebuild_tiles() -> void:
	_tile_painter.rebuild(_layers, run_tuning, tile_library, tile_layout)


func _rebuild_background() -> void:
	var layer := _layers.get("GroundBaseLayer") as Node2D
	if layer == null:
		return

	var existing := layer.get_node_or_null(BACKGROUND_SPRITE_NAME)
	if existing != null:
		layer.remove_child(existing)
		existing.queue_free()

	if run_tuning == null or tile_library == null or tile_layout == null:
		return
	var should_draw: Variant = tile_layout.get("draw_background_texture")
	if should_draw == null or not bool(should_draw):
		return

	var texture := _get_tile_library_background_texture()
	if texture == null:
		return

	var texture_size := texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return

	var sprite := Sprite2D.new()
	sprite.name = BACKGROUND_SPRITE_NAME
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.z_index = 1
	sprite.position = Vector2.ZERO
	var margin := _get_layout_vector2("background_world_margin", Vector2.ZERO)
	var world_size := run_tuning.arena_half_extents * 2.0 + margin * 2.0
	sprite.scale = Vector2(world_size.x / texture_size.x, world_size.y / texture_size.y)
	layer.add_child(sprite)


func _rebuild_obstacles() -> void:
	_clear_layer("PropVisualLayer")
	_clear_layer("ObstacleVisualLayer")
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
	if _uses_curated_arena_layout():
		_add_curated_arena_props()
		_add_curated_arena_obstacles(obstacle_index)
	else:
		_add_random_props()
		_add_random_obstacles(obstacle_index)


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
	var visual_layer := _layers["ObstacleVisualLayer"] as Node2D
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


func _add_random_props() -> void:
	if tile_library == null or tile_layout == null or run_tuning == null:
		return

	var textures: Array = _get_tile_library_textures("prop_visuals", "prop_visual_paths")
	if textures.is_empty():
		return

	var visual_layer := _layers["PropVisualLayer"] as Node2D
	if visual_layer == null:
		return

	var prop_count: int = max(int(tile_layout.get("random_prop_count")), 0)
	var min_origin_distance: float = max(float(tile_layout.get("random_prop_min_distance_from_origin")), 0.0)
	var scale_range: Vector2 = tile_layout.get("prop_scale_range")
	var scale_multiplier := _get_layout_float("prop_visual_scale_multiplier", 1.0)
	var tint := _get_layout_color("prop_tint", Color.WHITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tile_layout.get("random_seed")) + 101

	for index in range(prop_count):
		var texture := textures[rng.randi_range(0, textures.size() - 1)] as Texture2D
		if texture == null:
			continue
		var position := _random_arena_position(rng, min_origin_distance)
		var sprite := _create_texture_sprite("RandomProp_%02d" % [index + 1], texture, position, rng.randf_range(scale_range.x, scale_range.y) * scale_multiplier, rng, tint)
		visual_layer.add_child(sprite)


func _add_curated_arena_props() -> void:
	if tile_library == null or run_tuning == null:
		return

	var textures: Array = _get_tile_library_textures("prop_visuals", "prop_visual_paths")
	if textures.is_empty():
		return

	var visual_layer := _layers["PropVisualLayer"] as Node2D
	if visual_layer == null:
		return

	var scale_multiplier := _get_layout_float("prop_visual_scale_multiplier", 1.0)
	var tint := _get_layout_color("prop_tint", Color.WHITE)
	var placements := [
		{"position": Vector2(-3300.0, -1760.0), "texture": 0, "scale": 0.34, "rotation": -0.08, "alpha": 0.94},
		{"position": Vector2(-2890.0, -2020.0), "texture": 1, "scale": 0.30, "rotation": 0.04, "alpha": 0.90},
		{"position": Vector2(-2220.0, -2140.0), "texture": 2, "scale": 0.32, "rotation": -0.03, "alpha": 0.92},
		{"position": Vector2(-980.0, -2180.0), "texture": 3, "scale": 0.27, "rotation": 0.02, "alpha": 0.86},
		{"position": Vector2(1040.0, -2190.0), "texture": 4, "scale": 0.29, "rotation": -0.02, "alpha": 0.88},
		{"position": Vector2(2260.0, -2110.0), "texture": 5, "scale": 0.33, "rotation": 0.05, "alpha": 0.92},
		{"position": Vector2(2940.0, -1900.0), "texture": 6, "scale": 0.30, "rotation": -0.04, "alpha": 0.90},
		{"position": Vector2(3360.0, -1580.0), "texture": 7, "scale": 0.35, "rotation": 0.06, "alpha": 0.94},
		{"position": Vector2(-3560.0, -760.0), "texture": 8, "scale": 0.28, "rotation": -0.04, "alpha": 0.84},
		{"position": Vector2(-3600.0, 740.0), "texture": 9, "scale": 0.31, "rotation": 0.03, "alpha": 0.86},
		{"position": Vector2(3560.0, -680.0), "texture": 10, "scale": 0.32, "rotation": 0.05, "alpha": 0.86},
		{"position": Vector2(3600.0, 780.0), "texture": 11, "scale": 0.29, "rotation": -0.03, "alpha": 0.84},
		{"position": Vector2(-3260.0, 1580.0), "texture": 12, "scale": 0.34, "rotation": 0.06, "alpha": 0.92},
		{"position": Vector2(-2760.0, 1960.0), "texture": 13, "scale": 0.29, "rotation": -0.02, "alpha": 0.88},
		{"position": Vector2(-1260.0, 2190.0), "texture": 14, "scale": 0.30, "rotation": -0.04, "alpha": 0.84},
		{"position": Vector2(960.0, 2130.0), "texture": 15, "scale": 0.28, "rotation": 0.03, "alpha": 0.82},
		{"position": Vector2(2420.0, 2020.0), "texture": 1, "scale": 0.31, "rotation": 0.04, "alpha": 0.89},
		{"position": Vector2(3240.0, 1680.0), "texture": 3, "scale": 0.35, "rotation": -0.05, "alpha": 0.93},
	]
	for index in range(placements.size()):
		var placement: Dictionary = placements[index]
		var texture := textures[int(placement["texture"]) % textures.size()] as Texture2D
		if texture == null:
			continue
		var sprite := _create_curated_texture_sprite(
			"ArenaProp_%02d" % [index + 1],
			texture,
			placement["position"] as Vector2,
			float(placement["scale"]) * scale_multiplier,
			float(placement["rotation"]),
			float(placement["alpha"]),
			tint
		)
		visual_layer.add_child(sprite)


func _add_random_obstacles(start_index: int) -> void:
	if tile_library == null or tile_layout == null or run_tuning == null:
		return

	var textures: Array = _get_tile_library_textures("obstacle_visuals", "obstacle_visual_paths")
	if textures.is_empty():
		return

	var collision_layer := _layers["WorldCollisionLayer"] as Node2D
	var visual_layer := _layers["ObstacleVisualLayer"] as Node2D
	if collision_layer == null or visual_layer == null:
		return

	var obstacle_count: int = max(int(tile_layout.get("random_obstacle_count")), 0)
	var min_origin_distance: float = max(float(tile_layout.get("random_obstacle_min_distance_from_origin")), 0.0)
	var min_spacing: float = max(float(tile_layout.get("random_obstacle_min_spacing")), 0.0)
	var scale_range: Vector2 = tile_layout.get("obstacle_scale_range")
	var collision_scale: float = max(float(tile_layout.get("obstacle_collision_scale")), 0.05)
	var scale_multiplier := _get_layout_float("obstacle_visual_scale_multiplier", 1.0)
	var tint := _get_layout_color("obstacle_tint", Color.WHITE)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tile_layout.get("random_seed")) + 303
	var placed_positions: Array[Vector2] = []
	var attempts := 0

	while placed_positions.size() < obstacle_count and attempts < obstacle_count * 24:
		attempts += 1
		var position := _random_arena_position(rng, min_origin_distance)
		if not _is_far_from_positions(position, placed_positions, min_spacing):
			continue

		var texture := textures[rng.randi_range(0, textures.size() - 1)] as Texture2D
		if texture == null:
			continue

		var scale := rng.randf_range(scale_range.x, scale_range.y) * scale_multiplier
		var obstacle_index := start_index + placed_positions.size()
		var sprite := _create_texture_sprite("RandomObstacleVisual_%02d" % [obstacle_index + 1], texture, position, scale, rng, tint)
		visual_layer.add_child(sprite)

		var obstacle := StaticBody2D.new()
		obstacle.name = "RandomObstacle_%02d" % [obstacle_index + 1]
		obstacle.collision_layer = CollisionLayers.WORLD
		obstacle.collision_mask = 0
		obstacle.position = position

		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rectangle := RectangleShape2D.new()
		rectangle.size = _texture_collision_size(texture, scale, collision_scale)
		shape.shape = rectangle
		shape.position = _texture_collision_offset(texture, scale)
		obstacle.add_child(shape)
		collision_layer.add_child(obstacle)
		placed_positions.append(position)


func _add_curated_arena_obstacles(start_index: int) -> void:
	if tile_library == null or tile_layout == null:
		return

	var textures: Array = _get_tile_library_textures("obstacle_visuals", "obstacle_visual_paths")
	if textures.is_empty():
		return

	var collision_layer := _layers["WorldCollisionLayer"] as Node2D
	var visual_layer := _layers["ObstacleVisualLayer"] as Node2D
	if collision_layer == null or visual_layer == null:
		return

	var collision_scale: float = max(float(tile_layout.get("obstacle_collision_scale")), 0.05)
	var scale_multiplier := _get_layout_float("obstacle_visual_scale_multiplier", 1.0)
	var tint := _get_layout_color("obstacle_tint", Color.WHITE)
	var placements := [
		{"position": Vector2(-3440.0, -1860.0), "texture": 0, "scale": 0.50, "rotation": -0.05},
		{"position": Vector2(-2760.0, -2160.0), "texture": 1, "scale": 0.43, "rotation": 0.03},
		{"position": Vector2(2800.0, -2120.0), "texture": 2, "scale": 0.46, "rotation": 0.04},
		{"position": Vector2(3420.0, -1810.0), "texture": 3, "scale": 0.52, "rotation": -0.04},
		{"position": Vector2(-3480.0, 1840.0), "texture": 4, "scale": 0.50, "rotation": 0.06},
		{"position": Vector2(-2780.0, 2150.0), "texture": 5, "scale": 0.44, "rotation": -0.02},
		{"position": Vector2(2820.0, 2110.0), "texture": 6, "scale": 0.47, "rotation": -0.05},
		{"position": Vector2(3440.0, 1810.0), "texture": 7, "scale": 0.53, "rotation": 0.03},
		{"position": Vector2(-3680.0, -1120.0), "texture": 8, "scale": 0.42, "rotation": -0.04},
		{"position": Vector2(-3660.0, 1200.0), "texture": 9, "scale": 0.44, "rotation": 0.05},
		{"position": Vector2(3680.0, -1100.0), "texture": 10, "scale": 0.42, "rotation": 0.04},
		{"position": Vector2(3660.0, 1210.0), "texture": 11, "scale": 0.44, "rotation": -0.04},
		{"position": Vector2(-1520.0, -2260.0), "texture": 12, "scale": 0.40, "rotation": 0.02},
		{"position": Vector2(1580.0, -2260.0), "texture": 13, "scale": 0.41, "rotation": -0.03},
		{"position": Vector2(-1600.0, 2260.0), "texture": 14, "scale": 0.42, "rotation": -0.02},
		{"position": Vector2(1540.0, 2250.0), "texture": 15, "scale": 0.42, "rotation": 0.03},
	]
	for index in range(placements.size()):
		var placement: Dictionary = placements[index]
		var texture := textures[int(placement["texture"]) % textures.size()] as Texture2D
		if texture == null:
			continue

		var position := placement["position"] as Vector2
		var scale := float(placement["scale"]) * scale_multiplier
		var obstacle_index := start_index + index
		var sprite := _create_curated_texture_sprite(
			"ArenaObstacleVisual_%02d" % [obstacle_index + 1],
			texture,
			position,
			scale,
			float(placement["rotation"]),
			0.96,
			tint
		)
		visual_layer.add_child(sprite)

		var obstacle := StaticBody2D.new()
		obstacle.name = "ArenaObstacle_%02d" % [obstacle_index + 1]
		obstacle.collision_layer = CollisionLayers.WORLD
		obstacle.collision_mask = 0
		obstacle.position = position

		var shape := CollisionShape2D.new()
		shape.name = "CollisionShape2D"
		var rectangle := RectangleShape2D.new()
		rectangle.size = _texture_collision_size(texture, scale, collision_scale)
		shape.shape = rectangle
		shape.position = _texture_collision_offset(texture, scale)
		obstacle.add_child(shape)
		collision_layer.add_child(obstacle)


func _create_texture_sprite(sprite_name: String, texture: Texture2D, sprite_position: Vector2, sprite_scale: float, rng: RandomNumberGenerator, tint: Color = Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = sprite_position
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.rotation = rng.randf_range(-0.08, 0.08)
	sprite.modulate = Color(tint.r, tint.g, tint.b, rng.randf_range(0.86, 1.0) * tint.a)
	return sprite


func _create_curated_texture_sprite(sprite_name: String, texture: Texture2D, sprite_position: Vector2, sprite_scale: float, sprite_rotation: float, alpha: float, tint: Color = Color.WHITE) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.name = sprite_name
	sprite.texture = texture
	sprite.centered = true
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = sprite_position
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.rotation = sprite_rotation
	sprite.modulate = Color(tint.r, tint.g, tint.b, clampf(alpha * tint.a, 0.0, 1.0))
	return sprite


func _random_arena_position(rng: RandomNumberGenerator, min_origin_distance: float) -> Vector2:
	var half_extents := run_tuning.arena_half_extents
	for _attempt in range(24):
		var position := Vector2(
			rng.randf_range(-half_extents.x + 260.0, half_extents.x - 260.0),
			rng.randf_range(-half_extents.y + 220.0, half_extents.y - 220.0)
		)
		if position.length() >= min_origin_distance:
			return position
	return Vector2(min_origin_distance, 0.0)


func _uses_curated_arena_layout() -> bool:
	if tile_layout == null:
		return false
	var value: Variant = tile_layout.get("use_curated_arena_layout")
	return value != null and bool(value)


func _is_far_from_positions(position: Vector2, positions: Array[Vector2], min_spacing: float) -> bool:
	for other_position in positions:
		if position.distance_to(other_position) < min_spacing:
			return false
	return true


func _get_layout_vector2(property_name: String, default_value: Vector2) -> Vector2:
	if tile_layout == null:
		return default_value
	var value: Variant = tile_layout.get(property_name)
	if value is Vector2:
		return value
	return default_value


func _get_layout_float(property_name: String, default_value: float) -> float:
	if tile_layout == null:
		return default_value
	var value: Variant = tile_layout.get(property_name)
	if value == null:
		return default_value
	return float(value)


func _get_layout_color(property_name: String, default_value: Color) -> Color:
	if tile_layout == null:
		return default_value
	var value: Variant = tile_layout.get(property_name)
	if value is Color:
		return value
	return default_value


func _texture_collision_size(texture: Texture2D, sprite_scale: float, collision_scale: float) -> Vector2:
	var texture_size := texture.get_size()
	var footprint_scale := _get_layout_vector2("obstacle_collision_footprint_scale", Vector2.ONE)
	return Vector2(
		max(texture_size.x * sprite_scale * collision_scale * footprint_scale.x, 36.0),
		max(texture_size.y * sprite_scale * collision_scale * footprint_scale.y, 36.0)
	)


func _texture_collision_offset(texture: Texture2D, sprite_scale: float) -> Vector2:
	var texture_size := texture.get_size()
	var offset := _get_layout_vector2("obstacle_collision_footprint_offset", Vector2.ZERO)
	return Vector2(texture_size.x * sprite_scale * offset.x, texture_size.y * sprite_scale * offset.y)


func _get_tile_library_textures(texture_property_name: String, path_property_name: String) -> Array:
	if tile_library == null:
		return []

	var textures: Array = tile_library.get(texture_property_name) as Array
	if not textures.is_empty():
		return textures

	var texture_paths: Array = tile_library.get(path_property_name) as Array
	for texture_path in texture_paths:
		var texture := _load_texture_from_path(String(texture_path))
		if texture != null:
			textures.append(texture)
	return textures


func _get_tile_library_background_texture() -> Texture2D:
	if tile_library == null:
		return null

	var texture: Texture2D = tile_library.get("background_texture") as Texture2D
	if texture != null:
		return texture

	var texture_path_value: Variant = tile_library.get("background_texture_path")
	if texture_path_value == null:
		return null
	return _load_texture_from_path(String(texture_path_value))


func _load_texture_from_path(texture_path: String) -> Texture2D:
	if texture_path.is_empty():
		return null

	if texture_path.get_extension().to_lower() == "png":
		var image := Image.load_from_file(ProjectSettings.globalize_path(texture_path))
		if image != null and not image.is_empty():
			return ImageTexture.create_from_image(image)

	var texture := load(texture_path) as Texture2D
	if texture != null:
		return texture

	var image := Image.load_from_file(ProjectSettings.globalize_path(texture_path))
	if image == null or image.is_empty():
		return null

	return ImageTexture.create_from_image(image)


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
	if tile_layout != null and tile_layout.get("hazard_fill_alpha") != null:
		visual.color.a = clampf(float(tile_layout.get("hazard_fill_alpha")), 0.0, 1.0)
	visual.polygon = PackedVector2Array([
		Vector2(-half_size.x, -half_size.y),
		Vector2(half_size.x, -half_size.y),
		Vector2(half_size.x, half_size.y),
		Vector2(-half_size.x, half_size.y),
	])
	visual_layer.add_child(visual)
	_add_hazard_texture_visual(visual_layer, hazard_position, hazard_size, hazard_index)

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


func _add_hazard_texture_visual(visual_layer: Node2D, hazard_position: Vector2, hazard_size: Vector2, hazard_index: int) -> void:
	if tile_library == null:
		return
	if tile_layout != null:
		var should_draw: Variant = tile_layout.get("draw_hazard_textures")
		if should_draw != null and not bool(should_draw):
			return

	var textures: Array = tile_library.get("hazard_ground_tiles") as Array
	if textures.is_empty():
		textures = tile_library.get("hazard_visuals") as Array
	if textures.is_empty():
		return

	var alpha := 0.82
	if tile_layout != null and tile_layout.get("hazard_texture_alpha") != null:
		alpha = float(tile_layout.get("hazard_texture_alpha"))
	if alpha <= 0.0:
		return

	var texture := textures[hazard_index % textures.size()] as Texture2D
	if texture == null:
		return

	var sprite := Sprite2D.new()
	sprite.name = "HazardTexture_%02d" % [hazard_index + 1]
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	sprite.position = hazard_position
	var texture_size := texture.get_size()
	if texture_size.x > 0.0 and texture_size.y > 0.0:
		sprite.scale = Vector2(hazard_size.x / texture_size.x, hazard_size.y / texture_size.y)
	sprite.modulate = Color(1.0, 1.0, 1.0, clampf(alpha, 0.0, 1.0))
	visual_layer.add_child(sprite)


func _clear_layer(layer_name: String) -> void:
	var layer := _layers.get(layer_name) as Node
	if layer == null:
		return
	for child in layer.get_children():
		if child.get_script() == ArenaVisualDrawLayerScript:
			continue
		layer.remove_child(child)
		child.queue_free()
