class_name RunObjectiveEventData
extends Resource

enum EventType {
	ELITE,
	BOSS
}

@export var id: StringName
@export var trigger_time: float = 60.0
@export var event_type: EventType = EventType.ELITE
@export var enemy_scene: PackedScene
@export var spawn_count: int = 1
