class_name PlayerController
extends CharacterBody2D

signal died

@export var move_speed: float = 260.0
@export var max_health: float = 100.0

var health: float


func _ready() -> void:
	add_to_group("player")
	health = max_health


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()


func take_damage(amount: float) -> void:
	health = max(health - amount, 0.0)
	if health <= 0.0:
		died.emit()
