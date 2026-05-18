class_name BuildState
extends Node

signal modules_changed(modules_by_slot: Dictionary)
signal shot_profile_changed(shot_profile: ShotProfile)

@export var base_weapon_data: BaseWeaponData = preload("res://resources/weapons/core_bolt.tres")
@export var default_fire_mode: ModuleData = preload("res://resources/modules/fire_single_shot.tres")
@export var default_payload: ModuleData = preload("res://resources/modules/payload_normal.tres")

var modules_by_slot: Dictionary = {}
var current_shot_profile: ShotProfile


func _ready() -> void:
	if modules_by_slot.is_empty():
		install_module(default_fire_mode, false)
		install_module(default_payload, false)
	_rebuild_shot_profile()


func install_module(module: ModuleData, emit_change: bool = true) -> void:
	if module == null:
		return

	modules_by_slot[module.slot_type] = module
	_rebuild_shot_profile()

	if emit_change:
		modules_changed.emit(modules_by_slot.duplicate())


func get_module(slot_type: StringName) -> ModuleData:
	return modules_by_slot.get(slot_type)


func get_current_shot_profile() -> ShotProfile:
	if current_shot_profile == null:
		_rebuild_shot_profile()
	return current_shot_profile.duplicate_profile()


func _rebuild_shot_profile() -> void:
	current_shot_profile = ModuleApplier.create_shot_profile(base_weapon_data, modules_by_slot)
	shot_profile_changed.emit(current_shot_profile.duplicate_profile())
