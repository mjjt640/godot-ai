extends Node

var _plugin: EditorPlugin

func setup(plugin: EditorPlugin) -> void:
	_plugin = plugin

func create_action(request_id: int, do_methods: Array, undo_methods: Array, do_references: Array = []) -> void:
	var undo_redo = _plugin.get_undo_redo()
	undo_redo.create_action("MCP: op_%d" % request_id)
	for m in do_methods:
		_add_method_call(undo_redo, "do", m)
	for ref in do_references:
		if undo_redo.has_method("add_do_reference"):
			undo_redo.add_do_reference(ref)
	for m in undo_methods:
		_add_method_call(undo_redo, "undo", m)
	undo_redo.commit_action()


func _add_method_call(undo_redo: Object, mode: String, m: Dictionary) -> void:
	var args: Array = m.get("args", [])
	var target: Object = m.target
	var method: String = m.method
	match args.size():
		0:
			if mode == "do":
				undo_redo.add_do_method(target, method)
			else:
				undo_redo.add_undo_method(target, method)
		1:
			if mode == "do":
				undo_redo.add_do_method(target, method, args[0])
			else:
				undo_redo.add_undo_method(target, method, args[0])
		2:
			if mode == "do":
				undo_redo.add_do_method(target, method, args[0], args[1])
			else:
				undo_redo.add_undo_method(target, method, args[0], args[1])
		3:
			if mode == "do":
				undo_redo.add_do_method(target, method, args[0], args[1], args[2])
			else:
				undo_redo.add_undo_method(target, method, args[0], args[1], args[2])
		4:
			if mode == "do":
				undo_redo.add_do_method(target, method, args[0], args[1], args[2], args[3])
			else:
				undo_redo.add_undo_method(target, method, args[0], args[1], args[2], args[3])
		_:
			push_error("MCP undo action supports up to 4 method arguments")
