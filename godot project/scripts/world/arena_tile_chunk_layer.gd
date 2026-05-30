class_name ArenaTileChunkLayer
extends Node2D

var _items: Array = []


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func set_tiles(items: Array) -> void:
	_items = items
	queue_redraw()


func _draw() -> void:
	for item in _items:
		var texture := item.get("texture") as Texture2D
		if texture == null:
			continue
		var position: Vector2 = item.get("position", Vector2.ZERO)
		var size: Vector2 = item.get("size", Vector2.ZERO)
		var alpha := clampf(float(item.get("alpha", 1.0)), 0.0, 1.0)
		var color: Color = item.get("color", Color(1.0, 1.0, 1.0, alpha))
		color.a *= alpha
		var overlap := maxf(float(item.get("edge_overlap", 0.0)), 0.0)
		var rect := Rect2(position - size * 0.5 - Vector2.ONE * overlap, size + Vector2.ONE * overlap * 2.0)
		var source_rect: Rect2 = item.get("source_rect", Rect2())
		if source_rect.size.x > 0.0 and source_rect.size.y > 0.0:
			draw_texture_rect_region(texture, rect, source_rect, color)
		else:
			draw_texture_rect(texture, rect, false, color)
