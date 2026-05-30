@tool
extends EditorPlugin

var websocket_server: Node
var status_panel: Control
var toolbar_button: Button
var bottom_panel_button: Button

func _enter_tree() -> void:
	websocket_server = preload("websocket_server.gd").new()
	websocket_server.name = "MCPServer"
	websocket_server.setup(self)
	add_child(websocket_server)

	var panel_scene = preload("ui/status_panel.tscn")
	status_panel = panel_scene.instantiate()
	bottom_panel_button = add_control_to_bottom_panel(status_panel, "MCP")
	websocket_server.set_panel(status_panel)

	toolbar_button = Button.new()
	toolbar_button.text = "MCP"
	toolbar_button.tooltip_text = "打开 MCP 面板"
	toolbar_button.pressed.connect(_on_toolbar_button_pressed)
	add_control_to_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)

func _exit_tree() -> void:
	if toolbar_button:
		remove_control_from_container(EditorPlugin.CONTAINER_TOOLBAR, toolbar_button)
		toolbar_button.queue_free()
		toolbar_button = null
	if websocket_server:
		websocket_server.set_process(false)
		var handler = websocket_server.get_node_or_null("command_handler")
		if handler and handler.has_method("cleanup"):
			handler.cleanup()
		websocket_server.queue_free()
		websocket_server = null
	if status_panel:
		remove_control_from_bottom_panel(status_panel)
		status_panel.queue_free()
		status_panel = null
	bottom_panel_button = null

func get_plugin() -> EditorPlugin:
	return self

func _on_toolbar_button_pressed() -> void:
	if not status_panel:
		return
	make_bottom_panel_item_visible(status_panel)
	if status_panel.has_method("refresh_state"):
		status_panel.refresh_state()
