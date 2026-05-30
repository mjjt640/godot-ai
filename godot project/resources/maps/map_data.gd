class_name MapData
extends Resource

const ArenaVisualData = preload("res://resources/world/visuals/arena_visual_data.gd")

@export var id: StringName = &"default_map"
@export var display_name: String = "默认地图"
@export var run_tuning: RunTuningData
@export var visual_data: ArenaVisualData
@export var tile_library: Resource
@export var tile_layout: Resource
