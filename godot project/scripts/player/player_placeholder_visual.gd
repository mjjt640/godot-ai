class_name PlayerPlaceholderVisual
extends Node2D

@export var body_color: Color = Color(0.36, 0.78, 0.68, 1.0)
@export var shield_color: Color = Color(0.64, 0.86, 0.76, 1.0)
@export var outline_color: Color = Color(0.08, 0.06, 0.07, 1.0)
@export_range(0.0, 0.5, 0.01) var movement_deadzone: float = 0.05

var _facing_sign: float = 1.0
var _move_vector: Vector2 = Vector2.ZERO


func _ready() -> void:
	queue_redraw()


func _process(_delta: float) -> void:
	if _move_vector.length_squared() > movement_deadzone * movement_deadzone:
		queue_redraw()


func set_move_vector(move_vector: Vector2) -> void:
	_move_vector = move_vector
	if move_vector.length_squared() > movement_deadzone * movement_deadzone and absf(move_vector.x) > 0.01:
		_facing_sign = signf(move_vector.x)
	queue_redraw()


func _draw() -> void:
	var bob := 0.0
	if _move_vector.length_squared() > movement_deadzone * movement_deadzone:
		bob = sin(Time.get_ticks_msec() * 0.018) * 1.5

	_draw_polygon_with_outline(PackedVector2Array([
		Vector2(-12.0, 11.0 + bob),
		Vector2(0.0, -19.0 + bob),
		Vector2(14.0, 10.0 + bob),
		Vector2(6.0, 20.0 + bob),
		Vector2(-8.0, 20.0 + bob),
	]), body_color)
	_draw_polygon_with_outline(PackedVector2Array([
		Vector2(9.0 * _facing_sign, -2.0 + bob),
		Vector2(21.0 * _facing_sign, 4.0 + bob),
		Vector2(14.0 * _facing_sign, 15.0 + bob),
		Vector2(4.0 * _facing_sign, 10.0 + bob),
	]), shield_color)
	draw_line(Vector2(-7.0 * _facing_sign, 2.0 + bob), Vector2(-22.0 * _facing_sign, -14.0 + bob), outline_color, 5.0)
	draw_line(Vector2(-7.0 * _facing_sign, 2.0 + bob), Vector2(-22.0 * _facing_sign, -14.0 + bob), Color(0.78, 0.55, 0.48, 1.0), 2.5)


func _draw_polygon_with_outline(points: PackedVector2Array, fill_color: Color) -> void:
	draw_colored_polygon(points, fill_color)
	for index in range(points.size()):
		draw_line(points[index], points[(index + 1) % points.size()], outline_color, 4.0)
