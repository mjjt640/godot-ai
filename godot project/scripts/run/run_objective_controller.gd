class_name RunObjectiveController
extends RefCounted

var _triggered_event_ids: Dictionary = {}
var _boss_enemy_ids: Dictionary = {}


func reset() -> void:
	_triggered_event_ids.clear()
	_boss_enemy_ids.clear()


func collect_ready_events(run_objective: Resource, run_time: float) -> Array[Resource]:
	var ready_events: Array[Resource] = []
	if run_objective == null:
		return ready_events

	var events: Array = run_objective.get("events")
	for event in events:
		if event == null:
			continue
		var event_id: Variant = event.get("id")
		if _triggered_event_ids.has(event_id):
			continue
		if run_time < float(event.get("trigger_time")):
			continue
		_triggered_event_ids[event_id] = true
		ready_events.append(event)
	return ready_events


func register_spawned_objective_enemy(enemy: EnemyController) -> bool:
	if enemy == null or enemy.enemy_data == null:
		return false
	if not enemy.enemy_data.get_is_boss():
		return false
	_boss_enemy_ids[enemy.get_instance_id()] = true
	return true


func is_victory_enemy(enemy: EnemyController) -> bool:
	if enemy == null:
		return false
	return _boss_enemy_ids.has(enemy.get_instance_id())
