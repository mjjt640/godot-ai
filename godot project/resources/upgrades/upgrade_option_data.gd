class_name UpgradeOptionData
extends Resource

enum UpgradeType {
	MODULE,
	STAT
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var upgrade_type: UpgradeType = UpgradeType.MODULE
@export var module: ModuleData
@export var stat_modifiers: Dictionary = {}
