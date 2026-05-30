class_name CharacterData
extends Resource

@export var id: StringName = &"core_runner"
@export var display_name: String = "长枪行者"
@export_multiline var description: String = "以长枪为基础武器母题的均衡角色，适合熟悉自动锁敌、连刺和经验拾取节奏。"

@export var move_speed: float = 260.0
@export var max_health: float = 100.0
@export var xp_magnet_radius: float = 150.0
@export var luck: float = 0.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 780.0
@export var crit_chance: float = 0.05
@export var crit_damage_mult: float = 1.5
@export var starting_fire_module: ModuleData
@export var starting_payload_module: ModuleData
