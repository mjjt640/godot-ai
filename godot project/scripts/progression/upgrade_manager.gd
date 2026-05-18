class_name UpgradeManager
extends Node

@export var build_state_path: NodePath = ^"../BuildState"
@export var option_count: int = 3
@export var available_upgrades: Array[UpgradeOptionData] = []

@onready var _build_state: BuildState = get_node_or_null(build_state_path)


func _ready() -> void:
	if available_upgrades.is_empty():
		_load_default_upgrades()


func request_options() -> Array[UpgradeOptionData]:
	var options := available_upgrades.duplicate()
	options.shuffle()
	return options.slice(0, min(option_count, options.size()))


func apply_upgrade(option: UpgradeOptionData) -> void:
	if option == null:
		return

	match option.upgrade_type:
		UpgradeOptionData.UpgradeType.MODULE:
			if _build_state != null:
				_build_state.install_module(option.module)
		UpgradeOptionData.UpgradeType.STAT:
			pass


func _load_default_upgrades() -> void:
	for file_name in DirAccess.get_files_at("res://resources/upgrades"):
		if file_name.get_extension() != "tres":
			continue

		var option := load("res://resources/upgrades/%s" % file_name) as UpgradeOptionData
		if option != null:
			available_upgrades.append(option)
