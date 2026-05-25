class_name ArenaVisualDrawLayer
extends Node2D

enum LayerKind {
	GROUND_BASE,
	GROUND_DETAIL,
	NEON_DETAIL,
	BOUNDARY_VISUAL,
}

@export var layer_kind: LayerKind = LayerKind.GROUND_BASE

var _run_tuning: RunTuningData
var _visual_data: Resource


func configure(tuning: RunTuningData, data: Resource) -> void:
	_run_tuning = tuning
	_visual_data = data
	queue_redraw()


func _draw() -> void:
	if _run_tuning == null or _visual_data == null:
		return

	var half_extents := _run_tuning.arena_half_extents
	var rect := Rect2(-half_extents, half_extents * 2.0)
	match layer_kind:
		LayerKind.GROUND_BASE:
			_draw_ground_base(rect)
		LayerKind.GROUND_DETAIL:
			_draw_ground_detail(rect)
		LayerKind.NEON_DETAIL:
			_draw_neon_detail(rect)
		LayerKind.BOUNDARY_VISUAL:
			_draw_boundary(rect)


func _draw_ground_base(rect: Rect2) -> void:
	draw_rect(rect, _get_color("arena_color", Color(0.05, 0.06, 0.08, 1.0)), true)


func _draw_ground_detail(rect: Rect2) -> void:
	_draw_grid(rect)
	_draw_panel_lines(rect)
	_draw_cracks(rect)


func _draw_grid(rect: Rect2) -> void:
	var grid_size := _get_float("grid_size", 128.0)
	if grid_size <= 0.0:
		return

	var grid_color := _get_color("grid_color", Color(0.14, 0.26, 0.29, 0.45))
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), grid_color, 1.0)
		x += grid_size

	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), grid_color, 1.0)
		y += grid_size


func _draw_panel_lines(rect: Rect2) -> void:
	var panel_size := _get_float("panel_size", 384.0)
	if panel_size <= 0.0:
		return

	var panel_color := _get_color("panel_line_color", Color(0.03, 0.04, 0.055, 0.7))
	var panel_width := _get_float("panel_line_width", 2.0)
	var x := rect.position.x
	while x <= rect.end.x:
		draw_line(Vector2(x, rect.position.y), Vector2(x, rect.end.y), panel_color, panel_width)
		x += panel_size

	var y := rect.position.y
	while y <= rect.end.y:
		draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), panel_color, panel_width)
		y += panel_size


func _draw_cracks(rect: Rect2) -> void:
	var panel_size := _get_float("panel_size", 384.0)
	if panel_size <= 0.0:
		return

	var crack_color := _get_color("crack_color", Color(0.01, 0.012, 0.018, 0.75))
	var crack_width := maxf(_get_float("panel_line_width", 2.0) * 0.75, 1.0)
	var x := rect.position.x + panel_size * 0.55
	var column := 0
	while x < rect.end.x:
		var y := rect.position.y + panel_size * (0.45 + float(column % 3) * 0.35)
		while y < rect.end.y:
			var start := Vector2(x, y)
			draw_polyline(PackedVector2Array([
				start,
				start + Vector2(panel_size * 0.1, panel_size * 0.06),
				start + Vector2(panel_size * 0.18, -panel_size * 0.04),
			]), crack_color, crack_width)
			y += panel_size * 1.8
		x += panel_size * 1.35
		column += 1


func _draw_neon_detail(rect: Rect2) -> void:
	var interval := _get_float("neon_lane_interval", 512.0)
	if interval <= 0.0:
		return

	var cyan := _get_color("neon_cyan_color", Color(0.0, 0.95, 0.95, 0.62))
	var pink := _get_color("neon_pink_color", Color(1.0, 0.08, 0.64, 0.54))
	var line_width := _get_float("neon_line_width", 3.0)
	var y := rect.position.y + interval
	var index := 0
	while y < rect.end.y:
		var color := cyan if index % 2 == 0 else pink
		var inset := interval * (0.3 + float(index % 3) * 0.12)
		draw_line(Vector2(rect.position.x + inset, y), Vector2(rect.end.x - inset, y), color, line_width)
		draw_circle(Vector2(rect.position.x + inset, y), line_width * 1.5, color)
		draw_circle(Vector2(rect.end.x - inset, y), line_width * 1.5, color)
		y += interval
		index += 1

	var x := rect.position.x + interval * 1.5
	index = 0
	while x < rect.end.x:
		var color := pink if index % 2 == 0 else cyan
		var inset := interval * 0.5
		draw_line(Vector2(x, rect.position.y + inset), Vector2(x, rect.end.y - inset), color, maxf(line_width - 1.0, 1.0))
		x += interval * 2.0
		index += 1


func _draw_boundary(rect: Rect2) -> void:
	var line_width := _get_float("boundary_line_width", 5.0)
	var glow_color := _get_color("boundary_glow_color", Color(1.0, 0.08, 0.65, 0.24))
	var boundary_color := _get_color("boundary_color", Color(0.0, 0.95, 0.95, 0.75))
	draw_rect(rect, glow_color, false, line_width * 2.5)
	draw_rect(rect, boundary_color, false, line_width)


func _get_color(property_name: String, default_value: Color) -> Color:
	var value: Variant = _visual_data.get(property_name)
	if value is Color:
		return value
	return default_value


func _get_float(property_name: String, default_value: float) -> float:
	var value: Variant = _visual_data.get(property_name)
	if value == null:
		return default_value
	return float(value)
