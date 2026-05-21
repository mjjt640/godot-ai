class_name XPPickupController
extends Area2D

const CollisionLayers = preload("res://scripts/config/collision_layers.gd")
const GameText = preload("res://scripts/ui/game_text.gd")
const DEFAULT_MAGNET_PULL_RATE: float = 460.0

signal collected(amount: int)

@export var amount: int = 1
@export var bob_amplitude: float = 5.0
@export var bob_speed: float = 7.0

var _age: float = 0.0
var _scatter_remaining: float = 0.0
var _spawn_position: Vector2
@onready var _amount_label: Label = get_node_or_null("AmountLabel") as Label


func _ready() -> void:
	collision_layer = CollisionLayers.PICKUP
	collision_mask = CollisionLayers.PLAYER
	_spawn_position = global_position
	_refresh_label()
	body_entered.connect(_on_body_entered)
	add_to_group("xp_pickups")


func configure_from_tuning(_tuning: RunTuningData) -> void:
	_refresh_label()


func _physics_process(delta: float) -> void:
	_age += delta
	if _scatter_remaining > 0.0:
		_scatter_remaining = max(_scatter_remaining - delta, 0.0)
		return

	var player := get_tree().get_first_node_in_group("player") as PlayerController
	if player != null:
		var to_player := player.global_position - global_position
		if to_player.length() <= player.get_xp_magnet_radius():
			global_position += to_player.normalized() * DEFAULT_MAGNET_PULL_RATE * delta
			_spawn_position = global_position
			return

	global_position.y = _spawn_position.y + sin(_age * bob_speed) * bob_amplitude


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_collect()


func _collect() -> void:
	collected.emit(amount)
	queue_free()


func scatter(feedback: Resource) -> void:
	if feedback == null:
		return

	var scatter_duration := float(feedback.get("xp_drop_scatter_duration"))
	var scatter_radius := float(feedback.get("xp_drop_scatter_radius"))
	_scatter_remaining = scatter_duration
	var target_position := global_position + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(scatter_radius * 0.35, scatter_radius)
	_spawn_position = target_position
	var tween := create_tween()
	tween.tween_property(self, "global_position", target_position, scatter_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _refresh_label() -> void:
	if _amount_label != null:
		_amount_label.text = GameText.pickup_amount(amount)
