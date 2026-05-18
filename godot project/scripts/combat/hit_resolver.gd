class_name HitResolver
extends RefCounted


static func resolve_projectile_hit(target: Node, projectile: Node) -> void:
	if target == null or projectile == null:
		return

	if target.has_method("take_damage"):
		target.take_damage(projectile.damage)

	if projectile.explosion_radius > 0.0:
		_apply_explosion(target, projectile)


static func _apply_explosion(primary_target: Node, projectile: Node) -> void:
	for enemy in projectile.get_tree().get_nodes_in_group("enemies"):
		if enemy == primary_target or not enemy.has_method("take_damage"):
			continue

		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue

		var distance: float = projectile.global_position.distance_to(enemy_node.global_position)
		if distance <= projectile.explosion_radius:
			enemy.take_damage(projectile.damage * 0.55)
