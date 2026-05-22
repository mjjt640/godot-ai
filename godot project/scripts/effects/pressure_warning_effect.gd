class_name PressureWarningEffect
extends Node2D

var radius: float = 44.0
var duration: float = 0.45
var ring_width: float = 4.0
var ring_color: Color = Color(1.0, 0.12, 0.08, 0.95)
var fill_color: Color = Color(1.0, 0.06, 0.03, 0.18)
var marker_size: float = 14.0
var marker_width: float = 3.0
var marker_color: Color = Color(1.0, 0.92, 0.72, 0.95)
var countdown_width: float = 7.0
var countdown_color: Color = Color(1.0, 0.88, 0.28, 0.95)
var edge_marker_count: int = 4
var edge_marker_size: float = 9.0
var edge_marker_color: Color = Color(1.0, 0.2, 0.12, 0.9)
var _elapsed: float = 0.0


func play(effect_radius: float, warning_duration: float, feedback: Resource) -> void:
	radius = maxf(effect_radius, 1.0)
	duration = maxf(warning_duration, 0.05)
	if feedback != null:
		ring_width = maxf(float(feedback.get("pressure_warning_ring_width")), 1.0)
		ring_color = feedback.get("pressure_warning_ring_color")
		fill_color = feedback.get("pressure_warning_fill_color")
		marker_size = maxf(float(feedback.get("pressure_warning_marker_size")), 2.0)
		marker_width = maxf(float(feedback.get("pressure_warning_marker_width")), 1.0)
		marker_color = feedback.get("pressure_warning_marker_color")
		countdown_width = maxf(float(feedback.get("pressure_warning_countdown_width")), 1.0)
		countdown_color = feedback.get("pressure_warning_countdown_color")
		edge_marker_count = maxi(int(feedback.get("pressure_warning_edge_marker_count")), 0)
		edge_marker_size = maxf(float(feedback.get("pressure_warning_edge_marker_size")), 1.0)
		edge_marker_color = feedback.get("pressure_warning_edge_marker_color")

	scale = Vector2.ONE * 0.35
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)


func _process(delta: float) -> void:
	_elapsed = minf(_elapsed + delta, duration)
	queue_redraw()


func _draw() -> void:
	var remaining := 1.0 - clampf(_elapsed / duration, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, ring_color, ring_width, true)
	draw_arc(Vector2.ZERO, radius + countdown_width * 0.45, -PI * 0.5, -PI * 0.5 + TAU * remaining, 96, countdown_color, countdown_width, true)
	_draw_edge_markers()
	draw_line(Vector2(-marker_size, 0.0), Vector2(marker_size, 0.0), marker_color, marker_width, true)
	draw_line(Vector2(0.0, -marker_size), Vector2(0.0, marker_size), marker_color, marker_width, true)


func _draw_edge_markers() -> void:
	if edge_marker_count <= 0:
		return

	for index in range(edge_marker_count):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(edge_marker_count))
		var tangent := direction.orthogonal()
		var tip := direction * (radius - edge_marker_size * 0.35)
		var base := direction * (radius - edge_marker_size * 1.35)
		var points := PackedVector2Array([
			tip,
			base + tangent * edge_marker_size * 0.55,
			base - tangent * edge_marker_size * 0.55,
		])
		draw_colored_polygon(points, edge_marker_color)
