class_name BuildState
extends Node

signal modules_changed(modules_by_slot: Dictionary)
signal shot_profile_changed(shot_profile: ShotProfile)

@export var base_weapon_data: BaseWeaponData = preload("res://resources/weapons/core_bolt.tres")
@export var default_fire_mode: ModuleData = preload("res://resources/modules/fire_single_shot.tres")
@export var default_payload: ModuleData = preload("res://resources/modules/payload_normal.tres")

var modules_by_slot: Dictionary = {}
var stat_modifiers: Dictionary = {}
var character_modifiers: Dictionary = {}
var current_shot_profile: ShotProfile
var acquired_module_ids: Array[StringName] = []


func _ready() -> void:
	if modules_by_slot.is_empty():
		install_module(default_fire_mode, false, false)
		install_module(default_payload, false, false)
	_rebuild_shot_profile()


func install_module(module: ModuleData, emit_change: bool = true, track_acquisition: bool = true) -> void:
	if module == null:
		return

	modules_by_slot[module.slot_type] = module
	if track_acquisition and not acquired_module_ids.has(module.id):
		acquired_module_ids.append(module.id)
	_rebuild_shot_profile()

	if emit_change:
		modules_changed.emit(modules_by_slot.duplicate())


func get_module(slot_type: StringName) -> ModuleData:
	return modules_by_slot.get(slot_type)


func get_current_module_ids() -> Array[StringName]:
	var module_ids: Array[StringName] = []
	for module in modules_by_slot.values():
		if module != null:
			module_ids.append(module.id)
	return module_ids


func has_current_module_id(module_id: StringName) -> bool:
	return get_current_module_ids().has(module_id)


func has_any_current_module_id(module_ids: Array[StringName]) -> bool:
	for module_id in module_ids:
		if has_current_module_id(module_id):
			return true
	return false


func get_acquired_module_count() -> int:
	return acquired_module_ids.size()


func has_acquired_module_id(module_id: StringName) -> bool:
	return acquired_module_ids.has(module_id)


func can_acquire_module(max_module_count: int) -> bool:
	return get_acquired_module_count() < max_module_count


func get_current_shot_profile() -> ShotProfile:
	if current_shot_profile == null:
		_rebuild_shot_profile()
	return current_shot_profile.duplicate_profile()


func apply_stat_modifiers(modifiers: Dictionary) -> void:
	_merge_stat_modifiers(modifiers)
	_rebuild_shot_profile()


func configure_from_character(character_data: Resource) -> void:
	character_modifiers.clear()
	if character_data == null:
		_rebuild_shot_profile()
		return

	character_modifiers[&"attack_speed"] = _get_character_float(character_data, &"attack_speed", 1.0)
	character_modifiers[&"attack_range"] = _get_character_float(character_data, &"attack_range", 780.0)
	character_modifiers[&"crit_chance"] = _get_character_float(character_data, &"crit_chance", 0.0)
	character_modifiers[&"crit_damage_mult"] = _get_character_float(character_data, &"crit_damage_mult", 1.5)

	var starting_fire := character_data.get("starting_fire_module") as ModuleData
	if starting_fire != null:
		modules_by_slot[starting_fire.slot_type] = starting_fire
	var starting_payload := character_data.get("starting_payload_module") as ModuleData
	if starting_payload != null:
		modules_by_slot[starting_payload.slot_type] = starting_payload

	_rebuild_shot_profile()


func _merge_stat_modifiers(modifiers: Dictionary) -> void:
	for key in modifiers.keys():
		var modifier_key := StringName(String(key))
		var value := float(modifiers[key])
		if String(modifier_key).ends_with("_mult"):
			stat_modifiers[modifier_key] = float(stat_modifiers.get(modifier_key, 1.0)) * value
		else:
			stat_modifiers[modifier_key] = float(stat_modifiers.get(modifier_key, 0.0)) + value


func _rebuild_shot_profile() -> void:
	current_shot_profile = ModuleApplier.create_shot_profile(base_weapon_data, modules_by_slot, stat_modifiers, character_modifiers)
	shot_profile_changed.emit(current_shot_profile.duplicate_profile())


func _get_character_float(character_data: Resource, stat_name: StringName, default_value: float) -> float:
	var value: Variant = character_data.get(stat_name)
	if value == null:
		return default_value
	return float(value)
