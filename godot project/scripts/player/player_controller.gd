class_name PlayerController
extends CharacterBody2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")

signal died
signal health_changed(current_health: float, max_health: float)

@export var character_data: Resource
@export var move_speed: float = 260.0
@export var max_health: float = 100.0
@export var xp_magnet_radius: float = 150.0
@export var luck: float = 0.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 780.0
@export var crit_chance: float = 0.05
@export var crit_damage_mult: float = 1.5
@export var knockback_decay: float = 1800.0
@export var max_knockback_speed: float = 420.0

var health: float
var _knockback_velocity: Vector2 = Vector2.ZERO
var _move_speed_add: float = 0.0
var _move_speed_mult: float = 1.0
var _xp_magnet_radius_add: float = 0.0
var _xp_magnet_radius_mult: float = 1.0
var _luck_add: float = 0.0
var _luck_mult: float = 1.0


func _ready() -> void:
	_apply_character_data()
	collision_layer = CollisionLayers.PLAYER
	collision_mask = CollisionLayers.WORLD
	add_to_group("player")
	health = max_health
	health_changed.emit(health, max_health)


func _apply_character_data() -> void:
	if character_data == null:
		return

	move_speed = _get_character_float(&"move_speed", move_speed)
	max_health = _get_character_float(&"max_health", max_health)
	xp_magnet_radius = _get_character_float(&"xp_magnet_radius", xp_magnet_radius)
	luck = _get_character_float(&"luck", luck)
	attack_speed = _get_character_float(&"attack_speed", attack_speed)
	attack_range = _get_character_float(&"attack_range", attack_range)
	crit_chance = _get_character_float(&"crit_chance", crit_chance)
	crit_damage_mult = _get_character_float(&"crit_damage_mult", crit_damage_mult)


func _get_character_float(stat_name: StringName, default_value: float) -> float:
	var value: Variant = character_data.get(stat_name)
	if value == null:
		return default_value
	return float(value)


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * get_move_speed() + _knockback_velocity
	move_and_slide()
	_knockback_velocity = _knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * _delta)


func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	health_changed.emit(health, max_health)
	if health <= 0.0:
		died.emit()


func heal(amount: float) -> void:
	if amount <= 0.0:
		return

	health = min(health + amount, max_health)
	health_changed.emit(health, max_health)


func apply_general_modifiers(modifiers: Dictionary) -> void:
	if modifiers.has(&"move_speed_add"):
		_move_speed_add += float(modifiers[&"move_speed_add"])
	if modifiers.has(&"move_speed_mult"):
		_move_speed_mult *= float(modifiers[&"move_speed_mult"])
	if modifiers.has(&"xp_magnet_radius_add"):
		_xp_magnet_radius_add += float(modifiers[&"xp_magnet_radius_add"])
	if modifiers.has(&"xp_magnet_radius_mult"):
		_xp_magnet_radius_mult *= float(modifiers[&"xp_magnet_radius_mult"])
	if modifiers.has(&"heal_add"):
		heal(float(modifiers[&"heal_add"]))


func apply_luck_modifiers(modifiers: Dictionary) -> void:
	if modifiers.has(&"luck_add"):
		_luck_add += float(modifiers[&"luck_add"])
	if modifiers.has(&"luck_mult"):
		_luck_mult *= float(modifiers[&"luck_mult"])


func get_move_speed() -> float:
	return max((move_speed + _move_speed_add) * _move_speed_mult, 0.0)


func get_xp_magnet_radius() -> float:
	return max((xp_magnet_radius + _xp_magnet_radius_add) * _xp_magnet_radius_mult, 0.0)


func get_luck() -> float:
	return max((luck + _luck_add) * _luck_mult, 0.0)


func apply_knockback(direction: Vector2, force: float) -> void:
	if direction == Vector2.ZERO:
		return

	_knockback_velocity += direction.normalized() * force
	_knockback_velocity = _knockback_velocity.limit_length(max_knockback_speed)
