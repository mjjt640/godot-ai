class_name ArenaTileMapLayer
extends TileMapLayer

var tile_count: int = 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func set_tile_cells(next_tile_set: TileSet, cells: Array[Dictionary]) -> void:
	clear()
	tile_set = next_tile_set
	tile_count = cells.size()
	for cell in cells:
		var coords: Vector2i = cell.get("coords", Vector2i.ZERO)
		var source_id := int(cell.get("source_id", -1))
		if source_id < 0:
			continue
		set_cell(coords, source_id, Vector2i.ZERO)
