class_name SequenceFrameEffect
extends Node2D

@export var frames_path: String = ""
@export var fps: float = 18.0
@export var loop: bool = false
@export var max_lifetime: float = 0.0
@export var sprite_scale: float = 1.0
@export var centered: bool = true

var _frames: Array[Texture2D] = []
var _sprite: Sprite2D
var _frame_index: int = 0
var _frame_elapsed: float = 0.0
var _life_elapsed: float = 0.0


func configure(path: String, frames_per_second: float, should_loop: bool = false, lifetime: float = 0.0, scale_value: float = 1.0) -> void:
	frames_path = path
	fps = frames_per_second
	loop = should_loop
	max_lifetime = lifetime
	sprite_scale = scale_value


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.centered = centered
	_sprite.scale = Vector2.ONE * sprite_scale
	add_child(_sprite)

	_load_frames()
	if _frames.is_empty():
		push_warning("SequenceFrameEffect found no frames at %s" % frames_path)
		queue_free()
		return

	_sprite.texture = _frames[0]


func _process(delta: float) -> void:
	if _frames.is_empty():
		return

	_life_elapsed += delta
	if max_lifetime > 0.0 and _life_elapsed >= max_lifetime:
		queue_free()
		return

	var frame_time := 1.0 / maxf(fps, 1.0)
	_frame_elapsed += delta
	while _frame_elapsed >= frame_time:
		_frame_elapsed -= frame_time
		_advance_frame()
		if is_queued_for_deletion():
			return


func _load_frames() -> void:
	if frames_path.is_empty():
		return

	var directory := DirAccess.open(frames_path)
	if directory == null:
		push_warning("SequenceFrameEffect cannot open %s" % frames_path)
		return

	var frame_files: Array[String] = []
	for file_name in directory.get_files():
		if file_name.get_extension().to_lower() == "png":
			frame_files.append(file_name)
	frame_files.sort_custom(func(a: String, b: String) -> bool:
		return _frame_sort_key(a) < _frame_sort_key(b)
	)

	for file_name in frame_files:
		var texture := load(frames_path.path_join(file_name)) as Texture2D
		if texture != null:
			_frames.append(texture)


func _advance_frame() -> void:
	if _frame_index + 1 >= _frames.size():
		if loop:
			_frame_index = 0
		else:
			queue_free()
			return
	else:
		_frame_index += 1

	if _sprite != null:
		_sprite.texture = _frames[_frame_index]


func _frame_sort_key(file_name: String) -> int:
	return file_name.get_basename().to_int()
