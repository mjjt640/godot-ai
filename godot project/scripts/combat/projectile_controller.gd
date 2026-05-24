class_name ProjectileController
extends Area2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const ExplosionHitEffect = preload("res://scripts/effects/explosion_hit_effect.gd")

@export var combat_feedback: Resource = preload("res://resources/combat/default_combat_feedback.tres")

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var speed: float = 520.0
var lifetime: float = 1.6
var pierce_count: int = 0
var explosion_radius: float = 0.0
var explosion_damage_mult: float = 0.55
var knockback_strength: float = 120.0
var crit_chance: float = 0.0
var crit_damage_mult: float = 1.5
var can_pierce_world: bool = false

var _remaining_pierces: int = 0
var _age: float = 0.0
var _is_spent: bool = false


func _ready() -> void:
	collision_layer = CollisionLayers.PROJECTILE
	_refresh_collision_mask()
	body_entered.connect(_on_body_entered)


func configure(profile: ShotProfile, shot_direction: Vector2) -> void:
	direction = shot_direction.normalized()
	damage = profile.damage
	speed = profile.speed
	lifetime = profile.lifetime
	pierce_count = profile.pierce_count
	explosion_radius = profile.explosion_radius
	explosion_damage_mult = profile.explosion_damage_mult
	knockback_strength = profile.knockback_strength
	crit_chance = profile.crit_chance
	crit_damage_mult = profile.crit_damage_mult
	can_pierce_world = profile.can_pierce_world
	_remaining_pierces = pierce_count
	_is_spent = false
	scale = Vector2.ONE * profile.projectile_size
	rotation = direction.angle()
	_refresh_collision_mask()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if _is_spent:
		return
	if body is CollisionObject2D and (body as CollisionObject2D).collision_layer & CollisionLayers.WORLD != 0:
		_hit_world()
		return
	if not body.is_in_group("enemies"):
		return

	HitResolver.resolve_projectile_hit(body, self)
	if _remaining_pierces > 0:
		_remaining_pierces -= 1
	else:
		_is_spent = true
		set_deferred("monitoring", false)
		set_deferred("monitorable", false)
		queue_free()


func _hit_world() -> void:
	if can_pierce_world:
		return
	_is_spent = true
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	queue_free()


func _refresh_collision_mask() -> void:
	collision_mask = CollisionLayers.ENEMY
	if not can_pierce_world:
		collision_mask |= CollisionLayers.WORLD


func play_explosion_feedback() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return

	var effect := ExplosionHitEffect.new()
	effect.global_position = global_position
	parent.add_child(effect)
	effect.play(explosion_radius, combat_feedback)
