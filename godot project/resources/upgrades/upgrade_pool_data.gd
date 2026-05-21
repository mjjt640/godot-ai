class_name UpgradePoolData
extends Resource

@export var options: Array[UpgradeOptionData] = []
@export var option_count: int = 3
@export var prevent_same_slot_replacement: bool = true
@export var max_module_count: int = 0
@export var common_rarity_weight: float = 1.0
@export var rare_rarity_weight: float = 0.45
@export var epic_rarity_weight: float = 0.18
@export var legendary_rarity_weight: float = 0.06
@export var luck_rare_weight_bonus: float = 0.3
@export var luck_epic_weight_bonus: float = 0.65
@export var luck_legendary_weight_bonus: float = 1.0


func get_rarity_weight(rarity: int) -> float:
	match rarity:
		UpgradeOptionData.Rarity.COMMON:
			return common_rarity_weight
		UpgradeOptionData.Rarity.RARE:
			return rare_rarity_weight
		UpgradeOptionData.Rarity.EPIC:
			return epic_rarity_weight
		UpgradeOptionData.Rarity.LEGENDARY:
			return legendary_rarity_weight
	return common_rarity_weight


func get_luck_weight_multiplier(rarity: int, luck: float) -> float:
	return 1.0 + max(luck, 0.0) * get_luck_rarity_bonus(rarity)


func get_luck_rarity_bonus(rarity: int) -> float:
	match rarity:
		UpgradeOptionData.Rarity.RARE:
			return luck_rare_weight_bonus
		UpgradeOptionData.Rarity.EPIC:
			return luck_epic_weight_bonus
		UpgradeOptionData.Rarity.LEGENDARY:
			return luck_legendary_weight_bonus
	return 0.0
