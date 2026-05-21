class_name UpgradeManager
extends Node

@export var build_state_path: NodePath = ^"../BuildState"
@export var player_path: NodePath = ^"../Player"
@export var xp_manager_path: NodePath = ^"../XPManager"
@export var upgrade_pool: UpgradePoolData = preload("res://resources/upgrades/default_upgrade_pool.tres")
@export var module_skill_pool: UpgradePoolData = preload("res://resources/upgrades/default_module_skill_pool.tres")
@export var general_skill_pool: UpgradePoolData = preload("res://resources/upgrades/default_general_skill_pool.tres")

@onready var _build_state: BuildState = get_node_or_null(build_state_path)
@onready var _player: PlayerController = get_node_or_null(player_path)
@onready var _xp_manager: XPManager = get_node_or_null(xp_manager_path)
var _option_pool_by_id: Dictionary = {}


func request_options() -> Array[UpgradeOptionData]:
	_option_pool_by_id.clear()
	var candidates := _get_available_options()
	var selected: Array[UpgradeOptionData] = []
	var option_count: int = min(_get_option_count(), candidates.size())
	for _index in range(option_count):
		var option := _pick_weighted_option(candidates)
		if option == null:
			break
		selected.append(option)
		candidates.erase(option)
	return selected


func apply_upgrade(option: UpgradeOptionData) -> void:
	if option == null:
		return

	match option.upgrade_type:
		UpgradeOptionData.UpgradeType.MODULE:
			if _build_state != null:
				_build_state.install_module(option.module)
		UpgradeOptionData.UpgradeType.STAT:
			if _build_state != null:
				_build_state.apply_stat_modifiers(option.stat_modifiers)
			if _player != null:
				_player.apply_luck_modifiers(option.stat_modifiers)
		UpgradeOptionData.UpgradeType.GENERAL:
			if _player != null:
				_player.apply_general_modifiers(option.general_modifiers)
			if _xp_manager != null:
				_xp_manager.apply_general_modifiers(option.general_modifiers)


func get_module_limit() -> int:
	var module_rules_pool := _get_module_rules_pool()
	if module_rules_pool == null:
		return 0
	return max(module_rules_pool.max_module_count, 0)


func _get_available_options() -> Array[UpgradeOptionData]:
	var available_options: Array[UpgradeOptionData] = []
	for pool in _get_option_pools():
		for option in pool.options:
			if _can_offer(option):
				available_options.append(option)
				_option_pool_by_id[option.id] = pool
	return available_options


func _get_option_pools() -> Array[UpgradePoolData]:
	var pools: Array[UpgradePoolData] = []
	if upgrade_pool != null:
		pools.append(upgrade_pool)
	if module_skill_pool != null:
		pools.append(module_skill_pool)
	if general_skill_pool != null:
		pools.append(general_skill_pool)
	return pools


func _can_offer(option: UpgradeOptionData) -> bool:
	if option == null:
		return false

	match option.upgrade_type:
		UpgradeOptionData.UpgradeType.MODULE:
			return _can_offer_module(option)
		UpgradeOptionData.UpgradeType.STAT:
			return _can_offer_stat(option)
		UpgradeOptionData.UpgradeType.GENERAL:
			return _can_offer_general(option)
	return false


func _can_offer_module(option: UpgradeOptionData) -> bool:
	if option.module == null:
		return false
	var module_rules_pool := _get_module_rules_pool()
	if module_rules_pool == null:
		return false
	if _build_state == null:
		return true
	if _build_state.has_acquired_module_id(option.module.id):
		return false
	if not _build_state.can_acquire_module(module_rules_pool.max_module_count):
		return false
	if not module_rules_pool.prevent_same_slot_replacement:
		return true

	var current_module := _build_state.get_module(option.module.slot_type)
	return current_module == null or current_module.id != option.module.id


func _can_offer_stat(option: UpgradeOptionData) -> bool:
	if option.stat_modifiers.is_empty():
		return false
	if option.required_module_ids.is_empty():
		return true
	if _build_state == null:
		return false
	return _build_state.has_any_current_module_id(option.required_module_ids)


func _can_offer_general(option: UpgradeOptionData) -> bool:
	return not option.general_modifiers.is_empty()


func _pick_weighted_option(options: Array[UpgradeOptionData]) -> UpgradeOptionData:
	var total_weight := 0.0
	for option in options:
		total_weight += _effective_weight(option)

	if total_weight <= 0.0:
		return null

	var roll := randf() * total_weight
	for option in options:
		roll -= _effective_weight(option)
		if roll <= 0.0:
			return option
	return options.back()


func _effective_weight(option: UpgradeOptionData) -> float:
	if option == null:
		return 0.0
	var pool := _option_pool_by_id.get(option.id, upgrade_pool) as UpgradePoolData
	if pool == null:
		return 0.0
	return max(option.weight, 0.0) * max(pool.get_rarity_weight(option.rarity), 0.0) * pool.get_luck_weight_multiplier(option.rarity, _get_luck())


func _get_option_count() -> int:
	for pool in _get_option_pools():
		return pool.option_count
	return 0


func _get_module_rules_pool() -> UpgradePoolData:
	return upgrade_pool


func _get_luck() -> float:
	if _player == null:
		return 0.0
	return _player.get_luck()
