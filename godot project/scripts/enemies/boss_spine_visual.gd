class_name BossSpineVisual
extends Node2D

@export var skeleton_path := "res://art/enemies/m20001/m20001.skel"
@export var atlas_path := "res://art/enemies/m20001/m20001.atlas"
@export var idle_animation := "idle"
@export var move_animation := "move"
@export var windup_animation := "skill01"
@export var attack_animation := "attack01"
@export var recover_animation := "idle"
@export var death_animation := "death"
@export var visual_scale := 0.64
@export var vertical_offset := 34.0
@export var default_faces_right := false
@export_range(0.0, 0.5, 0.01) var movement_deadzone := 0.05

var _spine_sprite: Node2D
var _animation_name: StringName = &""
var _animation_loop: bool = true
var _facing_scale_x: float = 1.0


func _ready() -> void:
	_create_spine_sprite()
	play_idle()


func set_move_vector(move_vector: Vector2) -> void:
	if absf(move_vector.x) > movement_deadzone:
		face_direction(move_vector)

	if move_vector.length_squared() <= movement_deadzone * movement_deadzone:
		play_idle()
		return
	play_move()


func face_direction(direction: Vector2) -> void:
	if absf(direction.x) <= movement_deadzone:
		return

	var facing_sign := signf(direction.x)
	_facing_scale_x = facing_sign if default_faces_right else -facing_sign
	_apply_facing()


func play_idle() -> void:
	_set_animation(idle_animation, true)


func play_move() -> void:
	_set_animation(move_animation, true)


func play_windup() -> void:
	_set_animation(windup_animation, false)


func play_attack() -> void:
	_set_animation(attack_animation, false)


func play_recover() -> void:
	_set_animation(recover_animation, true)


func play_death() -> void:
	_set_animation(death_animation, false)


func _create_spine_sprite() -> void:
	if not ClassDB.class_exists("SpineSprite"):
		push_warning("SpineSprite class is unavailable; m20001 visual cannot be created.")
		return

	var skeleton_file_res: Variant = ClassDB.instantiate("SpineSkeletonFileResource")
	var atlas_res: Variant = ClassDB.instantiate("SpineAtlasResource")
	var skeleton_data_res: Variant = ClassDB.instantiate("SpineSkeletonDataResource")
	if skeleton_file_res == null or atlas_res == null or skeleton_data_res == null:
		push_warning("Spine resources are unavailable; m20001 visual cannot be created.")
		return

	skeleton_file_res.call("load_from_file", ProjectSettings.globalize_path(skeleton_path))
	atlas_res.call("load_from_atlas_file", ProjectSettings.globalize_path(atlas_path))
	skeleton_data_res.set("skeleton_file_res", skeleton_file_res)
	skeleton_data_res.set("atlas_res", atlas_res)
	if skeleton_data_res.has_method("is_skeleton_data_loaded") and not bool(skeleton_data_res.call("is_skeleton_data_loaded")):
		push_warning("m20001 Spine skeleton failed to load.")
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


func _set_animation(animation_to_play: String, loop_animation: bool) -> void:
	if _spine_sprite == null or animation_to_play.is_empty():
		return
	if _animation_name == StringName(animation_to_play) and _animation_loop == loop_animation:
		return
	if not _spine_sprite.has_method("get_animation_state"):
		return

	var animation_state: Variant = _spine_sprite.call("get_animation_state")
	if animation_state == null:
		return

	animation_state.call("set_animation", animation_to_play, loop_animation, 0)
	_animation_name = StringName(animation_to_play)
	_animation_loop = loop_animation


func _apply_facing() -> void:
	if _spine_sprite == null or not _spine_sprite.has_method("get_skeleton"):
		return

	var skeleton: Variant = _spine_sprite.call("get_skeleton")
	if skeleton != null and skeleton.has_method("set_scale_x"):
		skeleton.call("set_scale_x", _facing_scale_x)
