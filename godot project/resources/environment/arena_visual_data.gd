class_name ArenaVisualData
extends Resource

@export var arena_color: Color = Color(0.05, 0.06, 0.08, 1.0)
@export var grid_color: Color = Color(0.08, 0.23, 0.26, 0.46)
@export var panel_line_color: Color = Color(0.015, 0.018, 0.026, 0.78)
@export var crack_color: Color = Color(0.005, 0.006, 0.01, 0.86)
@export var neon_cyan_color: Color = Color(0.0, 0.92, 0.95, 0.62)
@export var neon_pink_color: Color = Color(1.0, 0.08, 0.62, 0.52)
@export var boundary_color: Color = Color(0.0, 0.9, 0.92, 0.78)
@export var boundary_glow_color: Color = Color(1.0, 0.08, 0.62, 0.24)
@export var grid_size: float = 128.0
@export var panel_size: float = 384.0
@export var panel_line_width: float = 2.0
@export var neon_lane_interval: float = 512.0
@export var neon_line_width: float = 3.0
@export var boundary_line_width: float = 5.0
@export var obstacles: Array[Resource] = []
@export var hazards: Array[Resource] = []
