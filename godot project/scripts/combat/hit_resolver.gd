class_name HitResolver
extends RefCounted


static func resolve_projectile_hit(target: Node, projectile: Node) -> void:
	if target == null or projectile == null:
		return

	if target.has_method("apply_hit_reaction"):
		target.apply_hit_reaction(projectile.direction, projectile.knockback_strength)
	var hit_damage := _roll_projectile_damage(projectile)
	if target.has_method("take_damage"):
		target.take_damage(hit_damage)

	if projectile.explosion_radius > 0.0:
		if projectile.has_method("play_explosion_feedback"):
			projectile.play_explosion_feedback()
		_apply_explosion(target, projectile, hit_damage)


static func _apply_explosion(primary_target: Node, projectile: Node, primary_damage: float) -> void:
	for enemy in projectile.get_tree().get_nodes_in_group("enemies"):
		if enemy == primary_target or not enemy.has_method("take_damage"):
			continue

		var enemy_node: Node2D = enemy as Node2D
		if enemy_node == null:
			continue

		var distance: float = projectile.global_position.distance_to(enemy_node.global_position)
		if distance <= projectile.explosion_radius:
			enemy.take_damage(primary_damage * projectile.explosion_damage_mult)


static func _roll_projectile_damage(projectile: Node) -> float:
	var hit_damage := float(projectile.damage)
	var crit_chance: float = clampf(float(projectile.crit_chance), 0.0, 1.0)
	if crit_chance > 0.0 and randf() <= crit_chance:
		hit_damage *= max(float(projectile.crit_damage_mult), 1.0)
	return hit_damage
