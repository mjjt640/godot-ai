class_name ExplosionHitEffect
extends Node2D

var radius: float = 32.0
var duration: float = 0.18
var ring_width: float = 5.0
var ring_color: Color = Color(1.0, 0.56, 0.18, 0.9)
var fill_color: Color = Color(1.0, 0.32, 0.12, 0.18)


func play(effect_radius: float, feedback: Resource) -> void:
	radius = maxf(effect_radius, 1.0)
	if feedback != null:
		duration = maxf(float(feedback.get("explosion_effect_duration")), 0.01)
		ring_width = maxf(float(feedback.get("explosion_effect_ring_width")), 1.0)
		ring_color = feedback.get("explosion_effect_ring_color")
		fill_color = feedback.get("explosion_effect_fill_color")

	scale = Vector2.ONE * 0.18
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.finished.connect(queue_free)


func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 96, ring_color, ring_width, true)
