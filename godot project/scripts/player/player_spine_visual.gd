class_name PlayerSpineVisual
extends Node2D

@export var skeleton_path := "res://art/characters/p0001/p0001.skel"
@export var atlas_path := "res://art/characters/p0001/p0001.atlas"
@export var idle_animation := "idle"
@export var move_animation := "move"
@export var visual_scale := 0.42
@export var vertical_offset := 36.0
@export_range(0.0, 0.5, 0.01) var movement_deadzone := 0.05

var _spine_sprite: Node
var _animation_name: StringName = &""
var _facing_sign := 1.0


func _ready() -> void:
	_create_spine_sprite()
	_set_animation(&"idle")


func set_move_vector(move_vector: Vector2) -> void:
	if _spine_sprite == null:
		return

	if absf(move_vector.x) > movement_deadzone:
		_facing_sign = signf(move_vector.x)
		_apply_facing()

	if move_vector.length_squared() <= movement_deadzone * movement_deadzone:
		_set_animation(&"idle")
		return

	_set_animation(&"move")


func _create_spine_sprite() -> void:
	if not ClassDB.class_exists("SpineSprite"):
		push_warning("SpineSprite class is unavailable; p0001 visual cannot be created.")
		return

	var skeleton_file_res: Variant = ClassDB.instantiate("SpineSkeletonFileResource")
	var atlas_res: Variant = ClassDB.instantiate("SpineAtlasResource")
	var skeleton_data_res: Variant = ClassDB.instantiate("SpineSkeletonDataResource")
	if skeleton_file_res == null or atlas_res == null or skeleton_data_res == null:
		push_warning("Spine resources are unavailable; p0001 visual cannot be created.")
		return

	skeleton_file_res.call("load_from_file", ProjectSettings.globalize_path(skeleton_path))
	atlas_res.call("load_from_atlas_file", ProjectSettings.globalize_path(atlas_path))
	skeleton_data_res.set("skeleton_file_res", skeleton_file_res)
	skeleton_data_res.set("atlas_res", atlas_res)
	if skeleton_data_res.has_method("is_skeleton_data_loaded") and not bool(skeleton_data_res.call("is_skeleton_data_loaded")):
		push_warning("p0001 Spine skeleton failed to load.")
		return

	_spine_sprite = ClassDB.instantiate("SpineSprite") as Node2D
	if _spine_sprite == null:
		push_warning("SpineSprite instance could not be created.")
		return

	_spine_sprite.name = "SpineSprite"
	_spine_sprite.set("skeleton_data_res", skeleton_data_res)
	_spine_sprite.position = Vector2(0.0, vertical_offset)
	_spine_sprite.scale = Vector2(visual_scale, visual_scale)
	add_child(_spine_sprite)
	_apply_facing()


func _set_animation(next_animation: StringName) -> void:
	if _spine_sprite == null or _animation_name == next_animation:
		return

	var animation_to_play := idle_animation
	if next_animation == &"move":
		animation_to_play = move_animation
	if animation_to_play.is_empty() or not _spine_sprite.has_method("get_animation_state"):
		return

	var animation_state: Variant = _spine_sprite.call("get_animation_state")
	if animation_state == null:
		return

	animation_state.call("set_animation", animation_to_play, true, 0)
	_animation_name = next_animation


func _apply_facing() -> void:
	if _spine_sprite == null or not _spine_sprite.has_method("get_skeleton"):
		return

	var skeleton: Variant = _spine_sprite.call("get_skeleton")
	if skeleton != null and skeleton.has_method("set_scale_x"):
		skeleton.call("set_scale_x", _facing_sign)
