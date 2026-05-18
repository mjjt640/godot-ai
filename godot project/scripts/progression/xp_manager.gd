class_name XPManager
extends Node

signal xp_changed(current_xp: int, required_xp: int, level: int)
signal level_up_requested

@export var base_required_xp: int = 5
@export var required_xp_growth: int = 3

var level: int = 1
var current_xp: int = 0
var pending_level_up: bool = false


func _ready() -> void:
	xp_changed.emit(current_xp, get_required_xp(), level)


func gain_experience(amount: int) -> void:
	if amount <= 0:
		return

	current_xp += amount
	xp_changed.emit(current_xp, get_required_xp(), level)

	if current_xp >= get_required_xp() and not pending_level_up:
		pending_level_up = true
		level_up_requested.emit()


func confirm_level_up() -> void:
	if not pending_level_up:
		return

	current_xp -= get_required_xp()
	level += 1
	pending_level_up = false
	xp_changed.emit(current_xp, get_required_xp(), level)

	if current_xp >= get_required_xp():
		pending_level_up = true
		level_up_requested.emit()


func get_required_xp() -> int:
	return base_required_xp + (level - 1) * required_xp_growth
