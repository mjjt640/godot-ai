extends Node2D

const EFFECT_ROOT := "res://art/effects/s818tx31_attack_bullet"
const EFFECT_NAMES := ["fly1", "fly2", "fly3", "fly4", "fly5", "fly6"]
const COLUMNS := 3
const CELL_SIZE := Vector2(520.0, 360.0)
const ORIGIN := Vector2(260.0, 210.0)
const LABEL_OFFSET := Vector2(-220.0, -160.0)

@export_range(0.1, 2.0, 0.05) var preview_scale := 0.6
@export_range(0.5, 8.0, 0.1) var animation_interval := 1.8

var _previews: Array[Dictionary] = []


func _ready() -> void:
	_setup_camera()
	queue_redraw()

	if not _is_spine_runtime_available():
		_add_label(
			self,
			"RuntimeErrorLabel",
			"Spine runtime is not available.\nCheck spine_godot_extension.gdextension.",
			_slot_position(0) + LABEL_OFFSET,
			18,
			Color(1.0, 0.35, 0.35)
		)
		return

	for effect_index in EFFECT_NAMES.size():
		_create_preview(effect_index, String(EFFECT_NAMES[effect_index]))


func _process(delta: float) -> void:
	for preview_index in _previews.size():
		var preview := _previews[preview_index]
		var animations: Array = preview["animations"]
		if animations.is_empty():
			continue

		var elapsed := float(preview["elapsed"]) + delta
		if elapsed < animation_interval:
			preview["elapsed"] = elapsed
			_previews[preview_index] = preview
			continue

		var animation_index := (int(preview["animation_index"]) + 1) % animations.size()
		var animation_name := String(animations[animation_index])
		preview["elapsed"] = 0.0
		preview["animation_index"] = animation_index
		_play_animation(preview["spine_sprite"] as Node, animation_name)
		_update_label(preview, animation_name)
		_previews[preview_index] = preview


func _draw() -> void:
	for effect_index in EFFECT_NAMES.size():
		var slot_position := _slot_position(effect_index)
		var rect := Rect2(
			slot_position - CELL_SIZE * 0.5 + Vector2(14.0, 14.0),
			CELL_SIZE - Vector2(28.0, 28.0)
		)
		draw_rect(rect, Color(0.28, 0.30, 0.32, 0.7), false, 1.0)
		draw_line(slot_position + Vector2(-20.0, 0.0), slot_position + Vector2(20.0, 0.0), Color(0.28, 0.30, 0.32, 0.5), 1.0)
		draw_line(slot_position + Vector2(0.0, -20.0), slot_position + Vector2(0.0, 20.0), Color(0.28, 0.30, 0.32, 0.5), 1.0)


func _setup_camera() -> void:
	var camera := Camera2D.new()
	camera.name = "PreviewCamera"
	camera.position = ORIGIN + Vector2(CELL_SIZE.x, CELL_SIZE.y * 0.5)
	add_child(camera)
	camera.make_current()


func _is_spine_runtime_available() -> bool:
	return (
		ClassDB.class_exists("SpineSprite")
		and ClassDB.class_exists("SpineSkeletonFileResource")
		and ClassDB.class_exists("SpineAtlasResource")
		and ClassDB.class_exists("SpineSkeletonDataResource")
	)


func _create_preview(effect_index: int, effect_name: String) -> void:
	var slot := Node2D.new()
	slot.name = effect_name
	slot.position = _slot_position(effect_index)
	add_child(slot)

	var metadata := _read_metadata(effect_name)
	var animations: Array = metadata["animations"]
	var version := String(metadata["version"])
	var label := _add_label(
		slot,
		"%sInfoLabel" % effect_name,
		_format_label(effect_name, version, "", 0, animations.size()),
		LABEL_OFFSET,
		16,
		Color(0.92, 0.94, 0.96)
	)

	var spine_sprite := _create_spine_sprite(effect_name)
	if spine_sprite == null:
		label.text = "%s\nload failed" % effect_name
		label.add_theme_color_override("font_color", Color(1.0, 0.35, 0.35))
		return

	slot.add_child(spine_sprite)
	if animations.is_empty():
		label.text = "%s | Spine %s\nno animations in json" % [effect_name, version]
		return

	var animation_name := String(animations[0])
	_play_animation(spine_sprite, animation_name)
	_update_label(
		{
			"effect_name": effect_name,
			"version": version,
			"animation_index": 0,
			"animations": animations,
			"label": label,
		},
		animation_name
	)

	_previews.append(
		{
			"effect_name": effect_name,
			"version": version,
			"animation_index": 0,
			"animations": animations,
			"elapsed": 0.0,
			"label": label,
			"spine_sprite": spine_sprite,
		}
	)


func _create_spine_sprite(effect_name: String) -> Node2D:
	var skeleton_path := _asset_path(effect_name, "skel")
	var atlas_path := _asset_path(effect_name, "atlas")
	if not FileAccess.file_exists(skeleton_path) or not FileAccess.file_exists(atlas_path):
		push_warning("%s Spine asset files are missing." % effect_name)
		return null

	var skeleton_file_res: Variant = ClassDB.instantiate("SpineSkeletonFileResource")
	var atlas_res: Variant = ClassDB.instantiate("SpineAtlasResource")
	var skeleton_data_res: Variant = ClassDB.instantiate("SpineSkeletonDataResource")
	if skeleton_file_res == null or atlas_res == null or skeleton_data_res == null:
		push_warning("%s Spine resources could not be created." % effect_name)
		return null

	skeleton_file_res.call("load_from_file", ProjectSettings.globalize_path(skeleton_path))
	atlas_res.call("load_from_atlas_file", ProjectSettings.globalize_path(atlas_path))
	skeleton_data_res.set("skeleton_file_res", skeleton_file_res)
	skeleton_data_res.set("atlas_res", atlas_res)
	if skeleton_data_res.has_method("is_skeleton_data_loaded") and not bool(skeleton_data_res.call("is_skeleton_data_loaded")):
		push_warning("%s Spine skeleton failed to load." % effect_name)
		return null

	var spine_sprite := ClassDB.instantiate("SpineSprite") as Node2D
	if spine_sprite == null:
		push_warning("%s SpineSprite could not be created." % effect_name)
		return null

	spine_sprite.name = "%sSpineSprite" % effect_name
	spine_sprite.set("skeleton_data_res", skeleton_data_res)
	spine_sprite.scale = Vector2(preview_scale, preview_scale)
	return spine_sprite


func _read_metadata(effect_name: String) -> Dictionary:
	var result := {
		"version": "unknown",
		"animations": [],
	}
	var json_path := _asset_path(effect_name, "json")
	if not FileAccess.file_exists(json_path):
		return result

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return result

	var skeleton: Variant = parsed.get("skeleton", {})
	if typeof(skeleton) == TYPE_DICTIONARY:
		result["version"] = String(skeleton.get("spine", "unknown"))

	var animation_data: Variant = parsed.get("animations", {})
	if typeof(animation_data) == TYPE_DICTIONARY:
		var animation_names: Array[String] = []
		for animation_name in animation_data.keys():
			animation_names.append(String(animation_name))
		animation_names.sort_custom(Callable(self, "_compare_animation_names"))
		result["animations"] = animation_names

	return result


func _compare_animation_names(left: String, right: String) -> bool:
	var left_number := _animation_number(left)
	var right_number := _animation_number(right)
	if left_number == right_number:
		return left < right
	return left_number < right_number


func _animation_number(animation_name: String) -> int:
	var separator_index := animation_name.rfind("_")
	if separator_index == -1:
		return 1000000

	var suffix := animation_name.substr(separator_index + 1)
	if suffix.is_valid_int():
		return int(suffix)
	return 1000000


func _slot_position(effect_index: int) -> Vector2:
	var column := effect_index % COLUMNS
	var row := int(effect_index / COLUMNS)
	return ORIGIN + Vector2(float(column) * CELL_SIZE.x, float(row) * CELL_SIZE.y)


func _asset_path(effect_name: String, extension: String) -> String:
	return "%s/%s/%s.%s" % [EFFECT_ROOT, effect_name, effect_name, extension]


func _play_animation(spine_sprite: Node, animation_name: String) -> void:
	if spine_sprite == null or animation_name.is_empty():
		return
	if not spine_sprite.has_method("get_animation_state"):
		return

	var animation_state: Variant = spine_sprite.call("get_animation_state")
	if animation_state == null:
		return
	animation_state.call("set_animation", animation_name, true, 0)


func _update_label(preview: Dictionary, animation_name: String) -> void:
	var label := preview["label"] as Label
	if label == null:
		return

	var animations: Array = preview["animations"]
	label.text = _format_label(
		String(preview["effect_name"]),
		String(preview["version"]),
		animation_name,
		int(preview["animation_index"]),
		animations.size()
	)


func _format_label(effect_name: String, version: String, animation_name: String, animation_index: int, animation_count: int) -> String:
	if animation_name.is_empty():
		return "%s | Spine %s\n%d animations" % [effect_name, version, animation_count]
	return "%s | Spine %s\n%s (%d/%d)" % [effect_name, version, animation_name, animation_index + 1, animation_count]


func _add_label(parent: Node, label_name: String, text: String, label_position: Vector2, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.name = label_name
	label.text = text
	label.position = label_position
	label.size = Vector2(440.0, 58.0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label
