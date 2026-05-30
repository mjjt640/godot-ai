extends SceneTree

const SKELETON_PATH := "res://art/characters/p0001/p0001.skel"
const ATLAS_PATH := "res://art/characters/p0001/p0001.atlas"

var _failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_expect(ClassDB.class_exists("SpineSprite"), "SpineSprite class should be registered")
	_expect(ClassDB.class_exists("SpineSkeletonFileResource"), "SpineSkeletonFileResource class should be registered")
	_expect(ClassDB.class_exists("SpineAtlasResource"), "SpineAtlasResource class should be registered")
	_expect(ClassDB.class_exists("SpineSkeletonDataResource"), "SpineSkeletonDataResource class should be registered")
	_expect(FileAccess.file_exists(SKELETON_PATH), "p0001.skel should exist at test path")
	_expect(FileAccess.file_exists(ATLAS_PATH), "p0001.atlas should exist at test path")

	if not _failures.is_empty():
		_finish()
		return

	var skeleton_file_res: Variant = ClassDB.instantiate("SpineSkeletonFileResource")
	var atlas_res: Variant = ClassDB.instantiate("SpineAtlasResource")
	var skeleton_data_res: Variant = ClassDB.instantiate("SpineSkeletonDataResource")
	var spine_sprite := ClassDB.instantiate("SpineSprite") as Node
	_expect(skeleton_file_res != null, "SpineSkeletonFileResource should instantiate")
	_expect(atlas_res != null, "SpineAtlasResource should instantiate")
	_expect(skeleton_data_res != null, "SpineSkeletonDataResource should instantiate")
	_expect(spine_sprite != null, "SpineSprite should instantiate")

	if not _failures.is_empty():
		_finish()
		return

	_expect(skeleton_file_res.has_method("load_from_file"), "SpineSkeletonFileResource should support load_from_file")
	_expect(atlas_res.has_method("load_from_atlas_file"), "SpineAtlasResource should support load_from_atlas_file")
	if not _failures.is_empty():
		_finish()
		return

	skeleton_file_res.call("load_from_file", SKELETON_PATH)
	atlas_res.call("load_from_atlas_file", ATLAS_PATH)
	skeleton_data_res.set("skeleton_file_res", skeleton_file_res)
	skeleton_data_res.set("atlas_res", atlas_res)
	_expect(bool(skeleton_data_res.call("is_skeleton_data_loaded")), "p0001 Spine 4.1 skeleton should load with the installed runtime")
	if not _failures.is_empty():
		_finish()
		return

	spine_sprite.set("skeleton_data_res", skeleton_data_res)
	root.add_child(spine_sprite)
	await process_frame
	await process_frame

	_expect(spine_sprite.has_method("get_animation_state"), "SpineSprite should expose get_animation_state")
	root.remove_child(spine_sprite)
	spine_sprite.free()
	_finish()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("spine_runtime_check passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)
