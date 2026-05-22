class_name BossDashWarningEffect
extends Node2D

var warning_length: float = 300.0
var warning_width: float = 88.0
var ring_width: float = 4.0
var ring_color: Color = Color(1.0, 0.18, 0.08, 0.9)
var fill_color: Color = Color(1.0, 0.08, 0.04, 0.2)


func play(skill: Resource) -> void:
	if skill != null:
		warning_length = maxf(float(skill.get("warning_length")), 1.0)
		warning_width = maxf(float(skill.get("warning_width")), 1.0)
		ring_width = maxf(float(skill.get("warning_ring_width")), 1.0)
		ring_color = skill.get("warning_color")
		fill_color = skill.get("warning_fill_color")

	queue_redraw()
	var duration := maxf(float(skill.get("windup_duration")) if skill != null else 0.35, 0.05)
	modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, duration * 0.35)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.65)
	tween.finished.connect(queue_free)


func _draw() -> void:
	var rect := Rect2(0.0, -warning_width * 0.5, warning_length, warning_width)
	draw_rect(rect, fill_color, true)
	draw_rect(rect, ring_color, false, ring_width)
	draw_line(Vector2.ZERO, Vector2(warning_length, 0.0), ring_color, ring_width, true)
