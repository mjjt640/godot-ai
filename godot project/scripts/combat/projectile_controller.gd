class_name ProjectileController
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var damage: float = 10.0
var speed: float = 520.0
var lifetime: float = 1.6
var pierce_count: int = 0
var explosion_radius: float = 0.0

var _remaining_pierces: int = 0
var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func configure(profile: ShotProfile, shot_direction: Vector2) -> void:
	direction = shot_direction.normalized()
	damage = profile.damage
	speed = profile.speed
	lifetime = profile.lifetime
	pierce_count = profile.pierce_count
	explosion_radius = profile.explosion_radius
	_remaining_pierces = pierce_count
	scale = Vector2.ONE * profile.projectile_size
	rotation = direction.angle()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_body_entered(body: Node) -> void:
	if not body.is_in_group("enemies"):
		return

	HitResolver.resolve_projectile_hit(body, self)
	if _remaining_pierces > 0:
		_remaining_pierces -= 1
	else:
		queue_free()
