class_name ArenaVisualData
extends Resource

@export var arena_color: Color = Color(0.18, 0.22, 0.2, 1.0)
@export var grid_color: Color = Color(0.3, 0.38, 0.34, 0.55)
@export var boundary_color: Color = Color(0.74, 0.93, 0.75, 0.68)
@export var grid_size: float = 120.0
@export var boundary_line_width: float = 5.0
@export var obstacles: Array[Resource] = []
@export var hazards: Array[Resource] = []
