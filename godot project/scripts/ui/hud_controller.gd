class_name HUDController
extends CanvasLayer

@onready var _xp_label: Label = %XpLabel
@onready var _level_label: Label = %LevelLabel
@onready var _fire_mode_label: Label = %FireModeLabel
@onready var _payload_label: Label = %PayloadLabel

var _build_state: BuildState
var _xp_manager: XPManager


func bind(build_state: BuildState, xp_manager: XPManager) -> void:
	_build_state = build_state
	_xp_manager = xp_manager

	if _build_state != null:
		_build_state.modules_changed.connect(_on_modules_changed)
		_on_modules_changed(_build_state.modules_by_slot)
	if _xp_manager != null:
		_xp_manager.xp_changed.connect(_on_xp_changed)
		_on_xp_changed(_xp_manager.current_xp, _xp_manager.get_required_xp(), _xp_manager.level)


func _on_modules_changed(modules_by_slot: Dictionary) -> void:
	var fire_mode: ModuleData = modules_by_slot.get(ModuleData.SLOT_FIRE_MODE)
	var payload: ModuleData = modules_by_slot.get(ModuleData.SLOT_PAYLOAD)
	_fire_mode_label.text = "发射：%s" % _format_module_name(fire_mode)
	_payload_label.text = "弹头：%s" % _format_module_name(payload)


func _on_xp_changed(current_xp: int, required_xp: int, level: int) -> void:
	_level_label.text = "等级 %d" % level
	_xp_label.text = "经验 %d / %d" % [current_xp, required_xp]


func _format_module_name(module: ModuleData) -> String:
	return module.display_name if module != null else "-"
