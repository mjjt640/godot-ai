class_name MapTileLibraryData
extends Resource

@export var tile_size: Vector2i = Vector2i(256, 256)
@export var background_texture: Texture2D
@export var ground_base_tiles: Array[Texture2D] = []
@export var ground_detail_tiles: Array[Texture2D] = []
@export var neon_detail_tiles: Array[Texture2D] = []
@export var decals: Array[Texture2D] = []
@export var hazard_visuals: Array[Texture2D] = []
@export var hazard_ground_tiles: Array[Texture2D] = []
@export var prop_visuals: Array[Texture2D] = []
@export var obstacle_visuals: Array[Texture2D] = []
@export var background_texture_path: String = ""
@export var ground_base_tile_paths: Array[String] = []
@export var prop_visual_paths: Array[String] = []
@export var obstacle_visual_paths: Array[String] = []
