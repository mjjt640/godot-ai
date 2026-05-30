@tool
extends VBoxContainer

const MCP_SERVER_PATH := "C:/Users/admin/Desktop/codex/godot/asset_research/godot-mcp-enhanced/build/index.js"
const GODOT_EXE_PATH := "C:/Users/admin/Desktop/Godot_v4.6.1-stable_win64.exe"

var _server: Node
var _status_label: Label
var _endpoint_label: Label
var _client_label: Label
var _secret_label: Label
var _project_label: Label
var _command_edit: TextEdit
var _cancel_button: Button
var _refresh_button: Button
var _start_external_button: Button
var _stop_external_button: Button
var _copy_command_button: Button
var _copy_key_path_button: Button
var _last_state: Dictionary = {}
var _external_pid: int = 0

func _ready() -> void:
	name = "MCPStatusPanel"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 8)
	_build_ui()
	update_status("MCP: Disconnected")

func set_server(server: Node) -> void:
	_server = server
	if _server and _server.has_method("get_server_state"):
		update_server_state(_server.get_server_state())

func update_status(text: String) -> void:
	if _status_label:
		_status_label.text = text

func update_server_state(state: Dictionary) -> void:
	_last_state = state.duplicate()
	var running := bool(state.get("running", false))
	var port := int(state.get("port", 0))
	var host := str(state.get("host", "127.0.0.1"))
	var project_dir := str(state.get("project_dir", ""))
	var secret_file := str(state.get("secret_file", ""))
	var client_count := int(state.get("client_count", 0))
	var authenticated_count := int(state.get("authenticated_count", 0))
	var max_peers := int(state.get("max_peers", 0))

	if _status_label:
		_status_label.text = "MCP: Listening" if running else "MCP: Stopped"
		_status_label.add_theme_color_override("font_color", Color("#41d68b") if running else Color("#ff6b6b"))
	if _endpoint_label:
		_endpoint_label.text = "Endpoint: ws://%s:%d" % [host, port] if running else "Endpoint: not listening"
	if _client_label:
		_client_label.text = "Clients: %d/%d, authenticated: %d" % [client_count, max_peers, authenticated_count]
	if _secret_label:
		_secret_label.text = "Auth key: %s" % (secret_file if secret_file != "" else "not generated")
	if _project_label:
		_project_label.text = "Project: %s" % (project_dir if project_dir != "" else ProjectSettings.globalize_path("res://").rstrip("/"))
	_update_command_text()

func set_operation_active(active: bool) -> void:
	if _cancel_button:
		_cancel_button.disabled = not active

func refresh_state() -> void:
	_on_refresh_pressed()

func _build_ui() -> void:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 8)
	add_child(header)

	_status_label = Label.new()
	_status_label.text = "MCP: Disconnected"
	_status_label.add_theme_font_size_override("font_size", 15)
	header.add_child(_status_label)

	_endpoint_label = Label.new()
	_endpoint_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_endpoint_label)

	_refresh_button = Button.new()
	_refresh_button.text = "刷新状态"
	_refresh_button.pressed.connect(_on_refresh_pressed)
	header.add_child(_refresh_button)

	_start_external_button = Button.new()
	_start_external_button.text = "一键启动"
	_start_external_button.tooltip_text = "按当前端口启动外部 MCP server"
	_start_external_button.pressed.connect(_on_start_external_pressed)
	header.add_child(_start_external_button)

	_stop_external_button = Button.new()
	_stop_external_button.text = "停止外部"
	_stop_external_button.disabled = true
	_stop_external_button.pressed.connect(_on_stop_external_pressed)
	header.add_child(_stop_external_button)

	_cancel_button = Button.new()
	_cancel_button.text = "取消当前操作"
	_cancel_button.disabled = true
	_cancel_button.pressed.connect(_on_cancel_pressed)
	header.add_child(_cancel_button)

	var info_grid := GridContainer.new()
	info_grid.columns = 1
	info_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(info_grid)

	_client_label = Label.new()
	info_grid.add_child(_client_label)

	_secret_label = Label.new()
	_secret_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_grid.add_child(_secret_label)

	_project_label = Label.new()
	_project_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	info_grid.add_child(_project_label)

	var command_header := HBoxContainer.new()
	command_header.add_theme_constant_override("separation", 8)
	add_child(command_header)

	var command_title := Label.new()
	command_title.text = "外部 MCP 启动命令"
	command_title.add_theme_font_size_override("font_size", 13)
	command_header.add_child(command_title)

	_copy_command_button = Button.new()
	_copy_command_button.text = "复制命令"
	_copy_command_button.pressed.connect(_on_copy_command_pressed)
	command_header.add_child(_copy_command_button)

	_copy_key_path_button = Button.new()
	_copy_key_path_button.text = "复制 key 路径"
	_copy_key_path_button.pressed.connect(_on_copy_key_path_pressed)
	command_header.add_child(_copy_key_path_button)

	_command_edit = TextEdit.new()
	_command_edit.editable = false
	_command_edit.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_command_edit.custom_minimum_size = Vector2(0, 110)
	_command_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_command_edit.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(_command_edit)

func _update_command_text() -> void:
	if not _command_edit:
		return
	var port := int(_last_state.get("port", 9090))
	if port <= 0:
		port = 9090
	var project_dir := str(_last_state.get("project_dir", ProjectSettings.globalize_path("res://").rstrip("/")))
	_command_edit.text = "\n".join([
		"cd \"%s\"" % project_dir,
		"$env:GODOT_MCP_MODE=\"editor\"",
		"$env:GODOT_EDITOR_PORT=\"%d\"" % port,
		"$env:GODOT_MCP_NO_FALLBACK=\"true\"",
		"$env:GODOT_PATH=\"%s\"" % GODOT_EXE_PATH,
		"node \"%s\"" % MCP_SERVER_PATH
	])

func _on_refresh_pressed() -> void:
	if _server and _server.has_method("get_server_state"):
		update_server_state(_server.get_server_state())
	_update_external_buttons()

func _on_copy_command_pressed() -> void:
	if _command_edit:
		DisplayServer.clipboard_set(_command_edit.text)

func _on_copy_key_path_pressed() -> void:
	var secret_file := str(_last_state.get("secret_file", ""))
	if secret_file != "":
		DisplayServer.clipboard_set(secret_file)

func _on_start_external_pressed() -> void:
	if _external_pid > 0:
		return
	_update_command_text()
	var project_dir := str(_last_state.get("project_dir", ProjectSettings.globalize_path("res://").rstrip("/")))
	var port := int(_last_state.get("port", 9090))
	if port <= 0:
		port = 9090
	var script := "; ".join([
		"Set-Location -LiteralPath '%s'" % _escape_powershell_single(project_dir),
		"$env:GODOT_MCP_MODE='editor'",
		"$env:GODOT_EDITOR_PORT='%d'" % port,
		"$env:GODOT_MCP_NO_FALLBACK='true'",
		"$env:GODOT_PATH='%s'" % _escape_powershell_single(GODOT_EXE_PATH),
		"node '%s'" % _escape_powershell_single(MCP_SERVER_PATH)
	])
	_external_pid = OS.create_process("powershell.exe", [
		"-NoExit",
		"-ExecutionPolicy",
		"Bypass",
		"-Command",
		script
	], false)
	_update_external_buttons()

func _on_stop_external_pressed() -> void:
	if _external_pid > 0:
		OS.kill(_external_pid)
	_external_pid = 0
	_update_external_buttons()

func _on_cancel_pressed() -> void:
	if _server and _server.has_method("cancel_current_operation"):
		_server.cancel_current_operation()

func _update_external_buttons() -> void:
	var running := _external_pid > 0
	if _start_external_button:
		_start_external_button.disabled = running
	if _stop_external_button:
		_stop_external_button.disabled = not running

func _escape_powershell_single(value: String) -> String:
	return value.replace("'", "''")
