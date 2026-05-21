class_name ModuleData
extends Resource

const SLOT_FIRE_MODE: StringName = &"fire_mode"
const SLOT_PAYLOAD: StringName = &"payload"

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export var id: StringName
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var slot_type: StringName = SLOT_FIRE_MODE
@export var rarity: Rarity = Rarity.COMMON
@export var damage_add: float = 0.0
@export var damage_mult: float = 1.0
@export var cooldown_add: float = 0.0
@export var cooldown_mult: float = 1.0
@export var speed_add: float = 0.0
@export var speed_mult: float = 1.0
@export var projectile_count: int = -1
@export var angles: Array[float] = []
@export var burst_count: int = -1
@export var burst_interval: float = -1.0
@export var pierce_count: int = -1
@export var explosion_radius: float = -1.0
@export var explosion_damage_mult: float = -1.0
@export var knockback_add: float = 0.0
@export var knockback_mult: float = 1.0
@export var stat_modifiers: Dictionary = {}
@export var behavior_flags: Dictionary = {}
