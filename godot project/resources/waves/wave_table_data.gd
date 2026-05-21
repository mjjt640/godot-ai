extends Resource

@export var entries: Array[Resource] = []


func get_entry(elapsed_time: float) -> Resource:
	var selected: Resource = null
	for entry in entries:
		if entry == null:
			continue
		if elapsed_time >= float(entry.get("start_time")):
			selected = entry
	return selected
