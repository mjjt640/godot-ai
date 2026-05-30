extends Node

var _undo_manager: Node
var _plugin: EditorPlugin

func setup(undo_manager: Node, plugin: EditorPlugin) -> void:
	_undo_manager = undo_manager
	_plugin = plugin

func handle_add_node(params: Dictionary, request_id: int) -> Dictionary:
	var root = _get_edited_scene_root()
	if not root:
		return {"error": {"code": -32003, "message": "No scene loaded"}}

	var node_type: String = params.get("node_type", "Node")
	var node_name: String = params.get("node_name", "NewNode")
	var parent_path: String = params.get("parent_node_path", "")

	var parent_node: Node = root
	if not parent_path.is_empty():
		parent_node = _find_node_by_path(root, parent_path)
		if not parent_node:
			return {"error": {"code": -32002, "message": "Parent not found: %s" % parent_path}}

	var cls = ClassDB.instantiate(node_type)
	if not cls:
		return {"error": {"code": -32000, "message": "Cannot instantiate: %s" % node_type}}
	cls.name = node_name

	_undo_manager.create_action(request_id,
		[{"target": parent_node, "method": "add_child", "args": [cls]},
		 {"target": cls, "method": "set_owner", "args": [root]}],
		[{"target": parent_node, "method": "remove_child", "args": [cls]}],
		[cls]
	)
	return {"result": {"node_path": str(cls.get_path()), "status": "created"}}

func _get_edited_scene_root() -> Node:
	if _plugin == null:
		return null
	var ei = _plugin.get_editor_interface()
	if ei == null:
		return null
	return ei.get_edited_scene_root()

func _find_node_by_path(root: Node, path: String) -> Node:
	if path.is_empty() or path == "root":
		return root
	var clean: String = path
	if clean.begins_with("root/"):
		clean = clean.substr(5)
	while clean.begins_with("/"):
		clean = clean.substr(1)
	if clean.is_empty():
		return root
	return root.get_node_or_null(clean)
