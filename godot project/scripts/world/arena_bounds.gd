class_name ArenaBounds
extends Node2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")

@export var run_tuning: RunTuningData = preload("res://resources/runs/default_run_tuning.tres")


func _ready() -> void:
	_rebuild()


func configure(tuning: RunTuningData) -> void:
	run_tuning = tuning
	if is_inside_tree():
		_rebuild()


func _rebuild() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

	var half_extents := run_tuning.arena_half_extents
	var thickness := run_tuning.arena_wall_thickness
	_add_wall("TopWall", Vector2(0.0, -half_extents.y - thickness * 0.5), Vector2(half_extents.x * 2.0 + thickness * 2.0, thickness))
	_add_wall("BottomWall", Vector2(0.0, half_extents.y + thickness * 0.5), Vector2(half_extents.x * 2.0 + thickness * 2.0, thickness))
	_add_wall("LeftWall", Vector2(-half_extents.x - thickness * 0.5, 0.0), Vector2(thickness, half_extents.y * 2.0 + thickness * 2.0))
	_add_wall("RightWall", Vector2(half_extents.x + thickness * 0.5, 0.0), Vector2(thickness, half_extents.y * 2.0 + thickness * 2.0))


func _add_wall(wall_name: String, position: Vector2, size: Vector2) -> void:
	var wall := StaticBody2D.new()
	wall.name = wall_name
	wall.collision_layer = CollisionLayers.WORLD
	wall.collision_mask = 0
	wall.position = position

	var collision_shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = size
	collision_shape.shape = rectangle
	wall.add_child(collision_shape)

	add_child(wall)
