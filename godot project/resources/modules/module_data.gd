class_name ModuleData
extends Resource

const SLOT_FIRE_MODE: StringName = &"fire_mode"
const SLOT_PAYLOAD: StringName = &"payload"

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var slot_type: StringName = SLOT_FIRE_MODE
@export var stat_modifiers: Dictionary = {}
@export var behavior_flags: Dictionary = {}
