class_name PressureImpactEffect
extends Node2D

var radius: float = 44.0
var duration: float = 0.16
var ring_width: float = 6.0
var ring_color: Color = Color(1.0, 0.78, 0.28, 0.95)
var fill_color: Color = Color(1.0, 0.36, 0.08, 0.24)
var burst_count: int = 10
var burst_length: float = 16.0
var burst_width: float = 3.0
var burst_color: Color = Color(1.0, 0.94, 0.48, 0.95)


func play(effect_radius: float, feedback: Resource) -> void:
	radius = maxf(effect_radius, 1.0)
	if feedback != null:
		duration = maxf(float(feedback.get("pressure_impact_duration")), 0.04)
		ring_width = maxf(float(feedback.get("pressure_impact_ring_width")), 1.0)
		ring_color = feedback.get("pressure_impact_ring_color")
		fill_color = feedback.get("pressure_impact_fill_color")
		burst_count = maxi(int(feedback.get("pressure_impact_burst_count")), 0)
		burst_length = maxf(float(feedback.get("pressure_impact_burst_length")), 0.0)
		burst_width = maxf(float(feedback.get("pressure_impact_burst_width")), 1.0)
		burst_color = feedback.get("pressure_impact_burst_color")

	scale = Vector2.ONE * 0.55
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.18, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, ring_color, ring_width, true)
	for index in range(burst_count):
		var direction := Vector2.RIGHT.rotated(TAU * float(index) / float(burst_count))
		draw_line(direction * radius, direction * (radius + burst_length), burst_color, burst_width, true)
