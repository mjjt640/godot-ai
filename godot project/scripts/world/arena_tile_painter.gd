class_name ArenaTilePainter
extends RefCounted

const ArenaTileBatchLayerScript = preload("res://scripts/world/arena_tile_batch_layer.gd")
const ArenaTileMapLayerScript = preload("res://scripts/world/arena_tile_map_layer.gd")

const BASE_CONTAINER_NAME := "GeneratedBaseTiles"
const DETAIL_CONTAINER_NAME := "GeneratedDetailTiles"
const DECAL_CONTAINER_NAME := "GeneratedDecals"
const NEON_CONTAINER_NAME := "GeneratedNeonTiles"

var _alpha_bleed_texture_cache: Dictionary = {}


func rebuild(layers: Dictionary, run_tuning: RunTuningData, tile_library: Resource, tile_layout: Resource) -> void:
	_clear_generated(layers)
	if run_tuning == null or tile_library == null or tile_layout == null:
		return

	var tile_world_size: Vector2 = _get_vector2(tile_layout, "tile_world_size", Vector2(256.0, 256.0))
	if tile_world_size.x <= 0.0 or tile_world_size.y <= 0.0:
		return

	var half_extents: Vector2 = run_tuning.arena_half_extents
	var columns: int = int(ceil((half_extents.x * 2.0) / tile_world_size.x))
	var rows: int = int(ceil((half_extents.y * 2.0) / tile_world_size.y))
	var origin: Vector2 = -half_extents + tile_world_size * 0.5
	var edge_overlap: float = _get_float(tile_layout, "tile_edge_overlap", 0.0)

	if _get_bool(tile_layout, "draw_base_tiles", true):
		_paint_base_tiles(layers, tile_library, tile_layout, origin, tile_world_size, columns, rows, edge_overlap)
	_paint_spaced_tiles(layers, "GroundDetailLayer", DETAIL_CONTAINER_NAME, _get_array(tile_library, "ground_detail_tiles"), "GroundDetail", origin, tile_world_size, columns, rows, _get_vector2i(tile_layout, "ground_detail_spacing", Vector2i(4, 3)), _get_vector2i(tile_layout, "ground_detail_phase", Vector2i(1, 1)), _get_float(tile_layout, "ground_detail_alpha", 0.58), edge_overlap)
	_paint_spaced_tiles(layers, "GroundDetailLayer", DECAL_CONTAINER_NAME, _get_array(tile_library, "decals"), "Decal", origin, tile_world_size, columns, rows, _get_vector2i(tile_layout, "decal_spacing", Vector2i(5, 4)), _get_vector2i(tile_layout, "decal_phase", Vector2i(2, 2)), _get_float(tile_layout, "decal_alpha", 0.52), edge_overlap)
	_paint_spaced_tiles(layers, "NeonDetailLayer", NEON_CONTAINER_NAME, _get_array(tile_library, "neon_detail_tiles"), "NeonTile", origin, tile_world_size, columns, rows, _get_vector2i(tile_layout, "neon_spacing", Vector2i(7, 5)), _get_vector2i(tile_layout, "neon_phase", Vector2i(3, 2)), _get_float(tile_layout, "neon_alpha", 0.76), edge_overlap)


func _paint_base_tiles(layers: Dictionary, tile_library: Resource, tile_layout: Resource, origin: Vector2, tile_world_size: Vector2, columns: int, rows: int, edge_overlap: float) -> void:
	var base_tiles: Array = _get_texture_array(tile_library, "ground_base_tiles", "ground_base_tile_paths")
	if base_tiles.is_empty():
		return
	base_tiles = _prepare_base_tiles(base_tiles, tile_layout)

	var container: Node = _get_tile_map_container(layers, "GroundBaseLayer", BASE_CONTAINER_NAME)
	if container == null:
		return

	var tile_pixel_size: Vector2i = _get_vector2i(tile_layout, "base_tile_texture_size", Vector2i(tile_world_size))
	var tile_set_info := _build_base_tile_set(base_tiles, tile_pixel_size)
	var tile_set := tile_set_info["tile_set"] as TileSet
	var source_ids: Array = tile_set_info["source_ids"] as Array
	var cells := _build_base_tile_cells(source_ids, tile_world_size, columns, rows, tile_layout)
	container.scale = Vector2(tile_world_size.x / float(tile_pixel_size.x), tile_world_size.y / float(tile_pixel_size.y))
	container.call("set_tile_cells", tile_set, cells)


func _build_base_tile_set(base_tiles: Array, tile_pixel_size: Vector2i) -> Dictionary:
	var tile_set := TileSet.new()
	tile_set.tile_size = tile_pixel_size
	var source_ids: Array[int] = []
	for texture in base_tiles:
		var tile_texture := texture as Texture2D
		if tile_texture == null:
			continue
		var source := TileSetAtlasSource.new()
		source.texture = tile_texture
		source.texture_region_size = tile_pixel_size
		source.create_tile(Vector2i.ZERO)
		source_ids.append(tile_set.add_source(source))
	return {
		"tile_set": tile_set,
		"source_ids": source_ids,
	}


func _build_base_tile_cells(source_ids: Array, tile_world_size: Vector2, columns: int, rows: int, tile_layout: Resource = null) -> Array[Dictionary]:
	var cells: Array[Dictionary] = []
	if source_ids.is_empty():
		return cells

	var start_cell := Vector2i(-int(ceil(float(columns) * 0.5)) - 1, -int(ceil(float(rows) * 0.5)) - 1)
	for y in range(rows + 2):
		for x in range(columns + 2):
			var map_coord := start_cell + Vector2i(x, y)
			var source_index := _base_tile_index(map_coord.x, map_coord.y, source_ids.size())
			if _get_bool(tile_layout, "use_curated_arena_layout", false):
				source_index = _curated_arena_tile_index(map_coord, columns, rows, source_ids.size(), tile_layout)
			var source_id := int(source_ids[source_index])
			cells.append({
				"coords": map_coord,
				"source_id": source_id,
			})
	return cells


func _curated_arena_tile_index(map_coord: Vector2i, columns: int, rows: int, count: int, tile_layout: Resource) -> int:
	var half_columns := maxf(float(columns) * 0.5, 1.0)
	var half_rows := maxf(float(rows) * 0.5, 1.0)
	var normalized := Vector2(float(map_coord.x) / half_columns, float(map_coord.y) / half_rows)
	var radius := normalized.length()
	var lane_width := 0.16
	var in_cross_lane := absf(normalized.x) <= lane_width or absf(normalized.y) <= lane_width
	var in_central_plaza := radius <= 0.36
	var in_outer_ring := radius >= 0.74
	var in_broken_corner := absf(normalized.x) >= 0.58 and absf(normalized.y) >= 0.52
	var scar_seed := _tile_hash(map_coord.x + 13, map_coord.y + 7)
	var in_scattered_rubble := radius > 0.48 and scar_seed % 17 == 0

	if in_central_plaza:
		return _pick_index_from_layout(tile_layout, "arena_center_tile_indices", map_coord, count)
	if in_cross_lane:
		return _pick_index_from_layout(tile_layout, "arena_lane_tile_indices", map_coord, count)
	if in_broken_corner or in_scattered_rubble:
		return _pick_index_from_layout(tile_layout, "arena_rubble_tile_indices", map_coord, count)
	if in_outer_ring:
		return _pick_index_from_layout(tile_layout, "arena_ring_tile_indices", map_coord, count)
	return _pick_index_from_layout(tile_layout, "arena_center_tile_indices", map_coord, count)


func _pick_index_from_layout(tile_layout: Resource, property_name: String, map_coord: Vector2i, count: int) -> int:
	var indices := _get_array(tile_layout, property_name)
	if indices.is_empty():
		return _base_tile_index(map_coord.x, map_coord.y, count)
	var selected := int(indices[_tile_hash(map_coord.x + property_name.length(), map_coord.y - property_name.length()) % indices.size()])
	return clampi(selected, 0, count - 1)


func _paint_spaced_tiles(
	layers: Dictionary,
	layer_name: String,
	container_name: String,
	textures: Array,
	sprite_prefix: String,
	origin: Vector2,
	tile_world_size: Vector2,
	columns: int,
	rows: int,
	spacing: Vector2i,
	phase: Vector2i,
	alpha: float,
	edge_overlap: float
) -> void:
	if textures.is_empty() or spacing.x <= 0 or spacing.y <= 0:
		return

	var container: Node2D = _get_container(layers, layer_name, container_name)
	if container == null:
		return

	var items: Array[Dictionary] = []
	for y in range(rows):
		for x in range(columns):
			if (x + phase.x) % spacing.x != 0 or (y + phase.y) % spacing.y != 0:
				continue
			var texture: Texture2D = textures[_detail_tile_index(x, y, textures.size())] as Texture2D
			_append_tile_item(items, texture, origin + Vector2(x * tile_world_size.x, y * tile_world_size.y), tile_world_size, alpha, edge_overlap)
	container.call("set_tiles", items)


func _get_container(layers: Dictionary, layer_name: String, container_name: String) -> Node2D:
	var layer: Node2D = layers.get(layer_name) as Node2D
	if layer == null:
		return null

	var container: Node2D = layer.get_node_or_null(container_name) as Node2D
	if container == null:
		container = ArenaTileBatchLayerScript.new()
		container.name = container_name
		layer.add_child(container)
	return container


func _get_tile_map_container(layers: Dictionary, layer_name: String, container_name: String) -> Node:
	var layer: Node2D = layers.get(layer_name) as Node2D
	if layer == null:
		return null

	var container: Node = layer.get_node_or_null(container_name)
	if container == null:
		container = ArenaTileMapLayerScript.new()
		container.name = container_name
		layer.add_child(container)
	return container


func _clear_generated(layers: Dictionary) -> void:
	for pair in [
		["GroundBaseLayer", BASE_CONTAINER_NAME],
		["GroundDetailLayer", DETAIL_CONTAINER_NAME],
		["GroundDetailLayer", DECAL_CONTAINER_NAME],
		["NeonDetailLayer", NEON_CONTAINER_NAME],
	]:
		var layer: Node2D = layers.get(pair[0]) as Node2D
		if layer == null:
			continue
		var container: Node = layer.get_node_or_null(pair[1])
		if container != null:
			layer.remove_child(container)
			container.queue_free()


func _append_tile_item(items: Array[Dictionary], texture: Texture2D, position: Vector2, target_size: Vector2, alpha: float, edge_overlap: float = 0.0, color: Color = Color.WHITE, source_rect: Rect2 = Rect2()) -> void:
	if texture == null:
		return
	items.append({
		"texture": texture,
		"position": position,
		"size": target_size,
		"alpha": alpha,
		"edge_overlap": edge_overlap,
		"color": color,
		"source_rect": source_rect,
	})


func _base_tile_index(x: int, y: int, count: int) -> int:
	return _tile_hash(x, y) % count


func _detail_tile_index(x: int, y: int, count: int) -> int:
	return _tile_hash(x + 17, y + 29) % count


func _tile_hash(x: int, y: int) -> int:
	return abs((x * 92837111 + y * 689287499 + x * y * 283923481) % 2147483647)


func _tile_tint(x: int, y: int) -> Color:
	var seed: int = _tile_hash(x + 5, y + 11)
	var shade: float = 0.98 + float(seed % 6) * 0.003
	return Color(shade, shade, shade, 1.0)


func _prepare_base_tiles(base_tiles: Array, tile_layout: Resource) -> Array:
	if not _get_bool(tile_layout, "base_tile_alpha_bleed", false):
		return base_tiles

	var iterations: int = maxi(int(tile_layout.get("base_tile_alpha_bleed_iterations")), 0)
	if iterations <= 0:
		return base_tiles

	var output_size: Vector2i = _get_vector2i(tile_layout, "base_tile_texture_size", Vector2i(128, 128))
	var prepared_tiles: Array = []
	for texture in base_tiles:
		var base_texture := texture as Texture2D
		if base_texture == null:
			continue
		prepared_tiles.append(_get_alpha_bleed_texture(base_texture, iterations, output_size))
	return prepared_tiles


func _get_alpha_bleed_texture(texture: Texture2D, iterations: int, output_size: Vector2i) -> Texture2D:
	var cache_key := "%s:%d:%s" % [String(texture.resource_path), iterations, output_size]
	if texture.resource_path.is_empty():
		cache_key = "%s:%d" % [str(texture.get_rid()), iterations]
	if _alpha_bleed_texture_cache.has(cache_key):
		return _alpha_bleed_texture_cache[cache_key]

	var image := texture.get_image()
	if image == null or image.is_empty():
		_alpha_bleed_texture_cache[cache_key] = texture
		return texture

	image.convert(Image.FORMAT_RGBA8)
	var fallback_color := _average_opaque_color(image)
	var working := image.duplicate()
	var size: Vector2i = working.get_size()
	for _iteration in range(iterations):
		var next_image := working.duplicate()
		var changed := false
		for y in range(size.y):
			for x in range(size.x):
				var current: Color = working.get_pixel(x, y)
				if current.a >= 0.99:
					continue
				var neighbor_color := _average_neighbor_color(working, x, y)
				if neighbor_color.a <= 0.0:
					continue
				next_image.set_pixel(x, y, Color(neighbor_color.r, neighbor_color.g, neighbor_color.b, 1.0))
				changed = true
		working = next_image
		if not changed:
			break

	for y in range(size.y):
		for x in range(size.x):
			var current: Color = working.get_pixel(x, y)
			if current.a < 0.99:
				working.set_pixel(x, y, fallback_color)
	working.resize(output_size.x, output_size.y, Image.INTERPOLATE_LANCZOS)

	var prepared_texture := ImageTexture.create_from_image(working)
	_alpha_bleed_texture_cache[cache_key] = prepared_texture
	return prepared_texture


func _average_neighbor_color(image: Image, x: int, y: int) -> Color:
	var size: Vector2i = image.get_size()
	var color_sum := Vector3.ZERO
	var count := 0
	for offset_y in range(-1, 2):
		for offset_x in range(-1, 2):
			if offset_x == 0 and offset_y == 0:
				continue
			var sample_x := x + offset_x
			var sample_y := y + offset_y
			if sample_x < 0 or sample_y < 0 or sample_x >= size.x or sample_y >= size.y:
				continue
			var color: Color = image.get_pixel(sample_x, sample_y)
			if color.a < 0.5:
				continue
			color_sum += Vector3(color.r, color.g, color.b)
			count += 1
	if count == 0:
		return Color.TRANSPARENT
	return Color(color_sum.x / count, color_sum.y / count, color_sum.z / count, 1.0)


func _average_opaque_color(image: Image) -> Color:
	var size: Vector2i = image.get_size()
	var color_sum := Vector3.ZERO
	var count := 0
	for y in range(size.y):
		for x in range(size.x):
			var color: Color = image.get_pixel(x, y)
			if color.a < 0.5:
				continue
			color_sum += Vector3(color.r, color.g, color.b)
			count += 1
	if count == 0:
		return Color(0.36, 0.37, 0.32, 1.0)
	return Color(color_sum.x / count, color_sum.y / count, color_sum.z / count, 1.0)


func _source_cell_rect(texture: Texture2D, cell_size: Vector2i, x: int, y: int) -> Rect2:
	if texture == null or cell_size.x <= 0 or cell_size.y <= 0:
		return Rect2()

	var texture_size: Vector2 = texture.get_size()
	if texture_size.x < float(cell_size.x) or texture_size.y < float(cell_size.y):
		return Rect2()

	var columns: int = max(int(texture_size.x / float(cell_size.x)), 1)
	var rows: int = max(int(texture_size.y / float(cell_size.y)), 1)
	var seed: int = _tile_hash(x + 31, y + 43)
	var source_x: int = seed % columns
	var source_y: int = int(seed / columns) % rows
	return Rect2(Vector2(source_x * cell_size.x, source_y * cell_size.y), Vector2(cell_size))


func _get_array(resource: Resource, property_name: String) -> Array:
	if resource == null:
		return []
	var value: Variant = resource.get(property_name)
	if value is Array:
		return value
	return []


func _get_texture_array(resource: Resource, texture_property_name: String, path_property_name: String) -> Array:
	var textures := _get_array(resource, texture_property_name)
	if not textures.is_empty():
		return textures

	var texture_paths := _get_array(resource, path_property_name)
	for texture_path in texture_paths:
		var texture := _load_texture_from_path(String(texture_path))
		if texture != null:
			textures.append(texture)
	return textures


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


func _get_vector2(resource: Resource, property_name: String, default_value: Vector2) -> Vector2:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value is Vector2:
		return value
	return default_value


func _get_vector2i(resource: Resource, property_name: String, default_value: Vector2i) -> Vector2i:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value is Vector2i:
		return value
	return default_value


func _get_float(resource: Resource, property_name: String, default_value: float) -> float:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value == null:
		return default_value
	return float(value)


func _get_bool(resource: Resource, property_name: String, default_value: bool) -> bool:
	if resource == null:
		return default_value
	var value: Variant = resource.get(property_name)
	if value == null:
		return default_value
	return bool(value)
