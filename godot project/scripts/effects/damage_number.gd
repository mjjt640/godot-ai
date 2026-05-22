class_name DamageNumber
extends Label

var lifetime: float = 0.55
var rise: float = 34.0


func play(amount: float, feedback: Resource) -> void:
	text = "%.0f" % amount
	if feedback != null:
		lifetime = float(feedback.get("damage_number_lifetime"))
		rise = float(feedback.get("damage_number_rise"))
		if modulate == Color.WHITE:
			modulate = feedback.get("damage_number_color")

	pivot_offset = size * 0.5
	var target_position := position + Vector2(0.0, -rise)
	var tween := create_tween()
	tween.tween_property(self, "position", target_position, lifetime).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, lifetime)
	tween.finished.connect(queue_free)
