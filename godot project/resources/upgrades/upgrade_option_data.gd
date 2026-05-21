class_name UpgradeOptionData
extends Resource

enum UpgradeType {
	MODULE,
	STAT,
	GENERAL
}

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var upgrade_type: UpgradeType = UpgradeType.MODULE
@export var rarity: Rarity = Rarity.COMMON
@export var module: ModuleData
@export var weight: float = 1.0
@export var stat_modifiers: Dictionary = {}
@export var general_modifiers: Dictionary = {}
@export var required_module_ids: Array[StringName] = []
