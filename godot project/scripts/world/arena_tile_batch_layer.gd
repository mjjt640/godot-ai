class_name ArenaTileBatchLayer
extends Node2D

const ArenaTileChunkLayerScript = preload("res://scripts/world/arena_tile_chunk_layer.gd")

const CHUNK_WORLD_SIZE := 768.0

var tile_count: int = 0
var chunk_count: int = 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func set_tiles(items: Array[Dictionary]) -> void:
	_clear_chunks()
	tile_count = items.size()
	var buckets: Dictionary = {}
	for item in items:
		var position: Vector2 = item.get("position", Vector2.ZERO)
		var chunk_coord := Vector2i(int(floor(position.x / CHUNK_WORLD_SIZE)), int(floor(position.y / CHUNK_WORLD_SIZE)))
		var key := "%d_%d" % [chunk_coord.x, chunk_coord.y]
		var chunk_origin := Vector2(float(chunk_coord.x) * CHUNK_WORLD_SIZE, float(chunk_coord.y) * CHUNK_WORLD_SIZE)
		var chunk_item: Dictionary = item.duplicate()
		chunk_item["position"] = position - chunk_origin
		if not buckets.has(key):
			buckets[key] = {
				"origin": chunk_origin,
				"items": [],
			}
		var bucket: Dictionary = buckets[key] as Dictionary
		var bucket_items: Array = bucket["items"] as Array
		bucket_items.append(chunk_item)

	for key in buckets.keys():
		var bucket: Dictionary = buckets[key] as Dictionary
		var chunk := ArenaTileChunkLayerScript.new()
		chunk.name = "Chunk_%s" % String(key)
		chunk.position = bucket["origin"] as Vector2
		add_child(chunk)
		chunk.call("set_tiles", bucket["items"])
	chunk_count = get_child_count()


func _clear_chunks() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
