class_name EnemyVisualAnimator
extends Sprite2D

@export var frames: Array[Texture2D] = []
@export var frames_per_second: float = 8.0

var _frame_index: int = 0
var _elapsed: float = 0.0


func _ready() -> void:
	_apply_frame(0)
	set_process(frames.size() > 1 and frames_per_second > 0.0)


func _process(delta: float) -> void:
	if frames.size() <= 1 or frames_per_second <= 0.0:
		return

	_elapsed += delta
	var frame_time := 1.0 / frames_per_second
	while _elapsed >= frame_time:
		_elapsed -= frame_time
		_frame_index = (_frame_index + 1) % frames.size()
		_apply_frame(_frame_index)


func _apply_frame(index: int) -> void:
	if frames.is_empty():
		return

	var next_texture := frames[clampi(index, 0, frames.size() - 1)]
	if next_texture != null:
		texture = next_texture
