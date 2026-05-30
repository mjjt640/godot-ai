class_name PlayerVisualAnimator
extends Sprite2D

@export var idle_frame: Texture2D
@export var walk_down_frames: Array[Texture2D] = []
@export var walk_up_frames: Array[Texture2D] = []
@export var walk_side_frames: Array[Texture2D] = []
@export var frames_per_second: float = 10.0
@export_range(0.0, 0.5, 0.01) var movement_deadzone: float = 0.05

var _animation_name: StringName = &""
var _frame_index: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	centered = true
	region_enabled = false
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_set_animation(&"idle")


func _process(delta: float) -> void:
	if _animation_name == &"idle" or frames_per_second <= 0.0:
		return

	_elapsed += delta
	var frame_time := 1.0 / frames_per_second
	while _elapsed >= frame_time:
		_elapsed -= frame_time
		var frames := _get_frames(_animation_name)
		if frames.is_empty():
			return
		_frame_index = (_frame_index + 1) % frames.size()
		_apply_frame()


func set_move_vector(move_vector: Vector2) -> void:
	if move_vector.length_squared() <= movement_deadzone * movement_deadzone:
		_set_animation(&"idle")
		return

	if absf(move_vector.x) > absf(move_vector.y):
		flip_h = move_vector.x < 0.0
		_set_animation(&"walk_side")
	elif move_vector.y < 0.0:
		flip_h = false
		_set_animation(&"walk_up")
	else:
		flip_h = false
		_set_animation(&"walk_down")


func _set_animation(next_animation: StringName) -> void:
	if _animation_name == next_animation:
		return

	_animation_name = next_animation
	_frame_index = 0
	_elapsed = 0.0
	_apply_frame()


func _apply_frame() -> void:
	if _animation_name == &"idle":
		texture = idle_frame
		return

	var frames := _get_frames(_animation_name)
	if frames.is_empty():
		texture = idle_frame
		return

	texture = frames[clampi(_frame_index, 0, frames.size() - 1)]


func _get_frames(animation_name: StringName) -> Array[Texture2D]:
	match animation_name:
		&"walk_down":
			return walk_down_frames
		&"walk_up":
			return walk_up_frames
		&"walk_side":
			return walk_side_frames
		_:
			return []
