class_name RunCombatRewardController
extends RefCounted

var _xp_manager: XPManager
var _xp_pickup_scene: PackedScene
var _pickup_container: Node2D
var _run_tuning: RunTuningData
var _combat_feedback: Resource
var _tree: SceneTree


func configure(
	xp_manager: XPManager,
	xp_pickup_scene: PackedScene,
	pickup_container: Node2D,
	run_tuning: RunTuningData,
	combat_feedback: Resource,
	tree: SceneTree
) -> void:
	_xp_manager = xp_manager
	_xp_pickup_scene = xp_pickup_scene
	_pickup_container = pickup_container
	_run_tuning = run_tuning
	_combat_feedback = combat_feedback
	_tree = tree


func handle_enemy_died(experience_reward: int, death_position: Vector2) -> void:
	_spawn_xp_pickup(experience_reward, death_position)


func _spawn_xp_pickup(amount: int, drop_position: Vector2) -> void:
	if _xp_pickup_scene == null or _xp_manager == null:
		return

	var pickup := _xp_pickup_scene.instantiate() as XPPickupController
	if pickup == null:
		return

	pickup.global_position = drop_position
	pickup.amount = amount
	pickup.configure_from_tuning(_run_tuning)

	var container: Node = _pickup_container if _pickup_container != null else _tree.current_scene
	container.add_child(pickup)
	pickup.scatter(_combat_feedback)
	pickup.collected.connect(_on_xp_pickup_collected)


func _on_xp_pickup_collected(amount: int) -> void:
	if _xp_manager != null:
		_xp_manager.gain_experience(amount)
