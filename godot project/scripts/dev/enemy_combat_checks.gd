class_name EnemyCombatChecks
extends RefCounted


func check_special_enemy_scene(ctx, scene_path: String, expects_boss: bool) -> void:
	var enemy = ctx.instantiate_scene(scene_path)
	if enemy == null:
		return

	ctx.root.add_child(enemy)
	ctx.expect(enemy.enemy_data != null, "%s should have enemy_data" % scene_path)
	if enemy.enemy_data != null:
		if expects_boss:
			ctx.expect(enemy.enemy_data.is_boss, "%s should be marked as boss" % scene_path)
		else:
			ctx.expect(enemy.enemy_data.is_elite, "%s should be marked as elite" % scene_path)
		ctx.expect(enemy.enemy_data.max_health > 100.0, "%s should have special enemy health budget" % scene_path)
		ctx.expect(enemy.enemy_data.experience_reward > 3, "%s should reward more XP than normal enemies" % scene_path)
	ctx.remove_instance(enemy)


func check_combat_feedback_resource(ctx) -> void:
	var feedback = load("res://resources/combat/default_combat_feedback.tres")
	if feedback == null:
		ctx.failures.append("Failed to load default combat feedback")
		return

	ctx.expect(float(feedback.get("explosion_effect_duration")) > 0.0, "Combat feedback needs positive explosion_effect_duration")
	ctx.expect(float(feedback.get("explosion_effect_ring_width")) > 0.0, "Combat feedback needs positive explosion_effect_ring_width")
	ctx.expect(feedback.get("explosion_effect_ring_color") is Color, "Combat feedback needs explosion_effect_ring_color")
	ctx.expect(feedback.get("explosion_effect_fill_color") is Color, "Combat feedback needs explosion_effect_fill_color")


func check_combat_feedback_readability_hooks(ctx) -> void:
	var feedback = load("res://resources/combat/default_combat_feedback.tres")
	if feedback == null:
		return

	ctx.expect(feedback.get("damage_number_elite_color") is Color, "Combat feedback needs elite damage number color")
	ctx.expect(feedback.get("damage_number_boss_color") is Color, "Combat feedback needs boss damage number color")
	var flash_duration: Variant = feedback.get("player_hit_flash_duration")
	ctx.expect(flash_duration != null and float(flash_duration) > 0.0, "Combat feedback needs positive player hit flash duration")
	ctx.expect(feedback.get("player_hit_flash_color") is Color, "Combat feedback needs player hit flash color")
	var pressure_warning_duration: Variant = feedback.get("pressure_warning_duration")
	var pressure_warning_ring_width: Variant = feedback.get("pressure_warning_ring_width")
	var pressure_warning_marker_size: Variant = feedback.get("pressure_warning_marker_size")
	var pressure_warning_marker_width: Variant = feedback.get("pressure_warning_marker_width")
	var pressure_warning_countdown_width: Variant = feedback.get("pressure_warning_countdown_width")
	var pressure_warning_edge_marker_count: Variant = feedback.get("pressure_warning_edge_marker_count")
	var pressure_warning_edge_marker_size: Variant = feedback.get("pressure_warning_edge_marker_size")
	var pressure_impact_duration: Variant = feedback.get("pressure_impact_duration")
	var pressure_impact_ring_width: Variant = feedback.get("pressure_impact_ring_width")
	var pressure_impact_burst_count: Variant = feedback.get("pressure_impact_burst_count")
	var pressure_impact_burst_length: Variant = feedback.get("pressure_impact_burst_length")
	var pressure_impact_burst_width: Variant = feedback.get("pressure_impact_burst_width")
	ctx.expect(pressure_warning_duration != null and float(pressure_warning_duration) > 0.0, "Combat feedback needs positive pressure warning duration")
	ctx.expect(pressure_warning_ring_width != null and float(pressure_warning_ring_width) > 0.0, "Combat feedback needs pressure warning ring width")
	ctx.expect(feedback.get("pressure_warning_ring_color") is Color, "Combat feedback needs pressure warning ring color")
	ctx.expect(feedback.get("pressure_warning_fill_color") is Color, "Combat feedback needs pressure warning fill color")
	ctx.expect(pressure_warning_marker_size != null and float(pressure_warning_marker_size) > 0.0, "Combat feedback needs pressure warning marker size")
	ctx.expect(pressure_warning_marker_width != null and float(pressure_warning_marker_width) > 0.0, "Combat feedback needs pressure warning marker width")
	ctx.expect(feedback.get("pressure_warning_marker_color") is Color, "Combat feedback needs pressure warning marker color")
	ctx.expect(pressure_warning_countdown_width != null and float(pressure_warning_countdown_width) > 0.0, "Combat feedback needs pressure warning countdown width")
	ctx.expect(feedback.get("pressure_warning_countdown_color") is Color, "Combat feedback needs pressure warning countdown color")
	ctx.expect(pressure_warning_edge_marker_count != null and int(pressure_warning_edge_marker_count) > 0, "Combat feedback needs pressure warning edge markers")
	ctx.expect(pressure_warning_edge_marker_size != null and float(pressure_warning_edge_marker_size) > 0.0, "Combat feedback needs pressure warning edge marker size")
	ctx.expect(feedback.get("pressure_warning_edge_marker_color") is Color, "Combat feedback needs pressure warning edge marker color")
	ctx.expect(pressure_impact_duration != null and float(pressure_impact_duration) > 0.0, "Combat feedback needs pressure impact duration")
	ctx.expect(pressure_impact_ring_width != null and float(pressure_impact_ring_width) > 0.0, "Combat feedback needs pressure impact ring width")
	ctx.expect(feedback.get("pressure_impact_ring_color") is Color, "Combat feedback needs pressure impact ring color")
	ctx.expect(feedback.get("pressure_impact_fill_color") is Color, "Combat feedback needs pressure impact fill color")
	ctx.expect(pressure_impact_burst_count != null and int(pressure_impact_burst_count) > 0, "Combat feedback needs pressure impact burst count")
	ctx.expect(pressure_impact_burst_length != null and float(pressure_impact_burst_length) > 0.0, "Combat feedback needs pressure impact burst length")
	ctx.expect(pressure_impact_burst_width != null and float(pressure_impact_burst_width) > 0.0, "Combat feedback needs pressure impact burst width")
	ctx.expect(feedback.get("pressure_impact_burst_color") is Color, "Combat feedback needs pressure impact burst color")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	ctx.expect(enemy_source.find("damage_number_boss_color") >= 0, "EnemyController should use boss damage number feedback")
	ctx.expect(enemy_source.find("damage_number_elite_color") >= 0, "EnemyController should use elite damage number feedback")
	var pressure_executor_source := FileAccess.get_file_as_string("res://scripts/enemies/pressure_enemy_behavior_executor.gd")
	ctx.expect(pressure_executor_source.find("PressureWarningEffect") >= 0, "PressureEnemyBehaviorExecutor should spawn pressure warning effects")
	ctx.expect(pressure_executor_source.find("PressureImpactEffect") >= 0, "PressureEnemyBehaviorExecutor should spawn pressure impact effects")

	var warning_source := FileAccess.get_file_as_string("res://scripts/effects/pressure_warning_effect.gd")
	ctx.expect(warning_source.find("draw_line") >= 0, "Pressure warning effect should draw a center marker")
	ctx.expect(warning_source.find("draw_colored_polygon") >= 0, "Pressure warning effect should draw edge danger markers")
	ctx.expect(warning_source.find("pressure_warning_countdown") >= 0, "Pressure warning effect should draw countdown feedback")

	var impact_source := FileAccess.get_file_as_string("res://scripts/effects/pressure_impact_effect.gd")
	ctx.expect(impact_source.find("pressure_impact_burst") >= 0, "Pressure impact effect should draw burst feedback")

	var player_source := FileAccess.get_file_as_string("res://scripts/player/player_controller.gd")
	ctx.expect(player_source.find("player_hit_flash_color") >= 0, "PlayerController should use player hit flash feedback")
	ctx.expect(player_source.find("_play_hit_camera_shake") >= 0, "PlayerController should shake camera only from player hit feedback")
	ctx.expect(player_source.find("set_move_vector") >= 0, "PlayerController should drive the player visual")
	var player_scene_source := FileAccess.get_file_as_string("res://scenes/player/player.tscn")
	ctx.expect(player_scene_source.find("art/characters") == -1, "Player scene should not reference removed legacy character art")
	var reward_source := FileAccess.get_file_as_string("res://scripts/run/run_combat_reward_controller.gd")
	ctx.expect(reward_source.find("_play_camera_shake") == -1, "Enemy death rewards should not trigger camera shake")
	ctx.expect(reward_source.find("Camera2D") == -1, "Enemy death rewards should not depend on the player camera")


func check_player_visual_animator_state(ctx) -> void:
	var player = ctx.instantiate_scene("res://scenes/player/player.tscn")
	if player == null:
		return

	ctx.root.add_child(player)
	var visual := player.get_node_or_null("Visual") as Node2D
	ctx.expect(visual != null, "Player scene should keep a Visual node")
	if visual == null:
		ctx.remove_instance(player)
		return

	ctx.expect(visual.has_method("set_move_vector"), "Player visual should expose movement-facing updates")

	visual.call("set_move_vector", Vector2.ZERO)
	if visual.has_method("_process"):
		visual.call("_process", 0.25)
	ctx.expect(visual.visible, "Player visual should stay visible while idle")
	visual.call("set_move_vector", Vector2(0.01, 0.0))
	if visual.has_method("_process"):
		visual.call("_process", 0.25)
	ctx.expect(visual.visible, "Player tiny input drift should keep visual valid")
	visual.call("set_move_vector", Vector2.DOWN)
	if visual.has_method("_process"):
		visual.call("_process", 0.12)
	ctx.expect(visual.visible, "Player movement should keep visual valid")
	visual.call("set_move_vector", Vector2.ZERO)
	ctx.expect(visual.visible, "Player visual should remain valid after movement stops")
	ctx.remove_instance(player)


func check_projectile_single_target_hit(ctx, damage_probe_script) -> void:
	var projectile = ctx.instantiate_scene("res://scenes/weapons/projectile.tscn")
	if projectile == null:
		return

	var first_target = damage_probe_script.new()
	var second_target = damage_probe_script.new()
	ctx.root.add_child(projectile)
	ctx.root.add_child(first_target)
	ctx.root.add_child(second_target)
	first_target.add_to_group("enemies")
	second_target.add_to_group("enemies")

	var profile := ShotProfile.new()
	profile.damage = 10.0
	profile.pierce_count = 0
	profile.explosion_radius = 0.0
	projectile.configure(profile, Vector2.RIGHT)
	projectile.call("_on_body_entered", first_target)
	projectile.call("_on_body_entered", second_target)

	ctx.expect(is_equal_approx(first_target.damage_taken, 10.0), "Non-piercing projectile should damage the first enemy once")
	ctx.expect(is_zero_approx(second_target.damage_taken), "Non-piercing projectile should ignore later enemies after first hit")
	ctx.remove_instance(second_target)
	ctx.remove_instance(first_target)
	ctx.remove_instance(projectile)


func check_projectile_explosion_damage_multiplier(ctx, damage_probe_script) -> void:
	var projectile = ctx.instantiate_scene("res://scenes/weapons/projectile.tscn")
	if projectile == null:
		return

	var primary_target = damage_probe_script.new()
	var nearby_target = damage_probe_script.new()
	ctx.root.add_child(projectile)
	ctx.root.add_child(primary_target)
	ctx.root.add_child(nearby_target)
	primary_target.add_to_group("enemies")
	nearby_target.add_to_group("enemies")
	projectile.global_position = Vector2.ZERO
	primary_target.global_position = Vector2.ZERO
	nearby_target.global_position = Vector2(20.0, 0.0)

	var profile := ShotProfile.new()
	profile.damage = 10.0
	profile.explosion_radius = 40.0
	projectile.configure(profile, Vector2.RIGHT)
	projectile.set("explosion_damage_mult", 0.25)
	HitResolver.resolve_projectile_hit(primary_target, projectile)

	ctx.expect(is_equal_approx(primary_target.damage_taken, 10.0), "Explosion projectile should deal full damage to primary target")
	ctx.expect(is_equal_approx(nearby_target.damage_taken, 2.5), "Explosion splash damage should use projectile explosion_damage_mult")
	ctx.remove_instance(nearby_target)
	ctx.remove_instance(primary_target)
	ctx.remove_instance(projectile)


func check_projectile_world_collision_rules(ctx, collision_layers) -> void:
	var projectile = ctx.instantiate_scene("res://scenes/weapons/projectile.tscn")
	if projectile == null:
		return

	ctx.root.add_child(projectile)
	var profile := ShotProfile.new()
	profile.can_pierce_world = false
	projectile.configure(profile, Vector2.RIGHT)
	ctx.expect((projectile.collision_mask & collision_layers.WORLD) != 0, "Projectile should scan WORLD collisions by default")
	ctx.expect(not projectile.can_pierce_world, "Projectile should default to stopping on world collisions")
	var world_obstacle: StaticBody2D = ctx.create_test_world_obstacle(Vector2.ZERO, Vector2(32.0, 32.0), collision_layers.WORLD)
	ctx.root.add_child(world_obstacle)
	projectile.call("_on_body_entered", world_obstacle)
	ctx.expect(projectile.is_queued_for_deletion(), "Non-world-piercing projectile should queue_free after hitting WORLD")
	ctx.remove_instance(world_obstacle)
	ctx.remove_instance(projectile)

	var piercing_projectile = ctx.instantiate_scene("res://scenes/weapons/projectile.tscn")
	if piercing_projectile == null:
		return
	ctx.root.add_child(piercing_projectile)
	var piercing_profile := ShotProfile.new()
	piercing_profile.can_pierce_world = true
	piercing_projectile.configure(piercing_profile, Vector2.RIGHT)
	ctx.expect(piercing_projectile.can_pierce_world, "Projectile should read can_pierce_world from ShotProfile")
	ctx.expect((piercing_projectile.collision_mask & collision_layers.WORLD) == 0, "World-piercing projectile should not scan WORLD collisions")
	ctx.remove_instance(piercing_projectile)


func check_enemy_soft_separation(ctx) -> void:
	var player = ctx.instantiate_scene("res://scenes/player/player.tscn")
	var first_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_basic.tscn")
	var second_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_basic.tscn")
	if player == null or first_enemy == null or second_enemy == null:
		return

	ctx.root.add_child(player)
	ctx.root.add_child(first_enemy)
	ctx.root.add_child(second_enemy)
	player.global_position = Vector2(420.0, 0.0)
	first_enemy.global_position = Vector2(0.0, 0.0)
	second_enemy.global_position = Vector2(10.0, 0.0)

	var initial_distance: float = first_enemy.global_position.distance_to(second_enemy.global_position)
	for _step in range(6):
		first_enemy._physics_process(0.1)
		second_enemy._physics_process(0.1)
	var final_distance: float = first_enemy.global_position.distance_to(second_enemy.global_position)

	ctx.expect(final_distance > initial_distance + 6.0, "Enemies should softly separate instead of overlapping in a stack")
	ctx.remove_instance(second_enemy)
	ctx.remove_instance(first_enemy)
	ctx.remove_instance(player)


func check_enemy_obstacle_navigation(ctx, collision_layers) -> void:
	var player = ctx.instantiate_scene("res://scenes/player/player.tscn")
	var enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_basic.tscn")
	if player == null or enemy == null:
		return

	var obstacle: StaticBody2D = ctx.create_test_world_obstacle(Vector2.ZERO, Vector2(96.0, 140.0), collision_layers.WORLD)
	ctx.root.add_child(player)
	ctx.root.add_child(enemy)
	ctx.root.add_child(obstacle)
	player.global_position = Vector2(180.0, 0.0)
	enemy.global_position = Vector2(-160.0, 0.0)
	enemy.call("_reset_navigation_stuck")
	var initial_distance: float = enemy.global_position.distance_to(player.global_position)
	var initial_y: float = enemy.global_position.y
	for _step in range(24):
		enemy._physics_process(0.1)
	var final_distance: float = enemy.global_position.distance_to(player.global_position)

	ctx.expect(absf(enemy.global_position.y - initial_y) > 16.0, "Enemy should steer sideways when a world obstacle blocks the direct chase line")
	ctx.expect(final_distance < initial_distance, "Enemy obstacle navigation should still make progress toward the player")
	ctx.remove_instance(obstacle)
	ctx.remove_instance(enemy)
	ctx.remove_instance(player)


func check_enemy_obstacle_escape_navigation_hooks(ctx) -> void:
	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	ctx.expect(enemy_source.find("_recover_from_slide_collisions") >= 0, "EnemyController should recover when slide collisions show it is stuck on a world obstacle")
	ctx.expect(enemy_source.find("_get_detour_angle_multiplier") >= 0, "EnemyController should expand detour angle when regular obstacle steering is stuck")
	ctx.expect(enemy_source.find("_choose_clearer_direction") >= 0, "EnemyController should choose from more than two obstacle detour directions")


func check_enemy_skill_executor_split(ctx) -> void:
	var base_executor_path := "res://scripts/enemies/enemy_skill_executor.gd"
	var arrow_executor_path := "res://scripts/enemies/boss_arrow_skill_executor.gd"
	var dash_executor_path := "res://scripts/enemies/dash_skill_executor.gd"
	ctx.expect(FileAccess.file_exists(base_executor_path), "EnemySkillExecutor base script should own the common skill executor contract")
	ctx.expect(FileAccess.file_exists(arrow_executor_path), "BossArrowSkillExecutor should own arrow-specific boss skill behavior")
	ctx.expect(FileAccess.file_exists(dash_executor_path), "DashSkillExecutor should own dash-specific enemy skill behavior")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	ctx.expect(enemy_source.find("_skill_executors") >= 0, "EnemyController should route enemy skills through an executor list")
	ctx.expect(enemy_source.find("DashEnemySkillDataScript") == -1, "EnemyController should not preload dash-specific skill data")
	ctx.expect(enemy_source.find("BossDashWarningEffect") == -1, "EnemyController should not spawn dash warning effects directly")
	ctx.expect(enemy_source.find("_begin_active_dash") == -1, "EnemyController should not contain dash phase implementation details")
	ctx.expect(enemy_source.find("_try_dash_hit_target") == -1, "EnemyController should not contain dash hit implementation details")

	if FileAccess.file_exists(base_executor_path):
		var base_executor_source := FileAccess.get_file_as_string(base_executor_path)
		ctx.expect(base_executor_source.find("func can_start(") >= 0, "EnemySkillExecutor should expose can_start")
		ctx.expect(base_executor_source.find("func start(") >= 0, "EnemySkillExecutor should expose start")
		ctx.expect(base_executor_source.find("func update(") >= 0, "EnemySkillExecutor should expose update")
		ctx.expect(base_executor_source.find("func finish(") >= 0, "EnemySkillExecutor should expose finish")

	if FileAccess.file_exists(arrow_executor_path):
		var arrow_executor_source := FileAccess.get_file_as_string(arrow_executor_path)
		ctx.expect(arrow_executor_source.find("extends \"res://scripts/enemies/enemy_skill_executor.gd\"") >= 0, "BossArrowSkillExecutor should inherit the common executor contract")
		ctx.expect(arrow_executor_source.find("ArrowEnemySkillData") >= 0, "BossArrowSkillExecutor should own arrow skill data matching")
		ctx.expect(arrow_executor_source.find("BossArrowShotEffect") >= 0, "BossArrowSkillExecutor should spawn arrow shot effects")
		ctx.expect(arrow_executor_source.find("BossArrowRainEffect") >= 0, "BossArrowSkillExecutor should spawn arrow rain effects")
		ctx.expect(arrow_executor_source.find("take_damage") == -1, "BossArrowSkillExecutor should leave hit damage to arrow effect nodes")

	if FileAccess.file_exists(dash_executor_path):
		var dash_executor_source := FileAccess.get_file_as_string(dash_executor_path)
		ctx.expect(dash_executor_source.find("extends \"res://scripts/enemies/enemy_skill_executor.gd\"") >= 0, "DashSkillExecutor should inherit the common executor contract")
		ctx.expect(dash_executor_source.find("DashEnemySkillData") >= 0, "DashSkillExecutor should own dash skill data matching")
		ctx.expect(dash_executor_source.find("BossDashWarningEffect") >= 0, "DashSkillExecutor should own dash warning effects")
		ctx.expect(dash_executor_source.find("take_damage") >= 0, "DashSkillExecutor should own dash hit damage")


func check_enemy_behavior_executor_split(ctx) -> void:
	var base_executor_path := "res://scripts/enemies/enemy_behavior_executor.gd"
	var pressure_executor_path := "res://scripts/enemies/pressure_enemy_behavior_executor.gd"
	var touch_executor_path := "res://scripts/enemies/touch_damage_behavior_executor.gd"
	ctx.expect(FileAccess.file_exists(base_executor_path), "EnemyBehaviorExecutor base script should own the common behavior executor contract")
	ctx.expect(FileAccess.file_exists(pressure_executor_path), "PressureEnemyBehaviorExecutor should own PRESSURE enemy behavior")
	ctx.expect(FileAccess.file_exists(touch_executor_path), "TouchDamageBehaviorExecutor should own enemy contact damage")

	var enemy_source := FileAccess.get_file_as_string("res://scripts/enemies/enemy_controller.gd")
	ctx.expect(enemy_source.find("_behavior_executors") >= 0, "EnemyController should route enemy behaviors through an executor list")
	ctx.expect(enemy_source.find("TouchDamageBehaviorExecutor") >= 0, "EnemyController should register touch damage behavior through an executor")
	ctx.expect(enemy_source.find("PressureWarningEffect") == -1, "EnemyController should not spawn pressure warning effects directly")
	ctx.expect(enemy_source.find("PressureImpactEffect") == -1, "EnemyController should not spawn pressure impact effects directly")
	ctx.expect(enemy_source.find("_pressure_warning_remaining") == -1, "EnemyController should not own pressure warning state")
	ctx.expect(enemy_source.find("_try_pressure_damage") == -1, "EnemyController should not contain pressure behavior implementation details")
	ctx.expect(enemy_source.find("_resolve_pressure_warning") == -1, "EnemyController should not contain pressure warning resolution details")
	ctx.expect(enemy_source.find("_touch_cooldown_remaining") == -1, "EnemyController should not own touch damage cooldown state")
	ctx.expect(enemy_source.find("_try_touch_damage") == -1, "EnemyController should not contain touch damage implementation details")
	ctx.expect(enemy_source.find("get_touch_damage") == -1, "EnemyController should not read touch damage values directly")
	ctx.expect(enemy_source.find("get_player_knockback") == -1, "EnemyController should not read touch player knockback directly")

	if FileAccess.file_exists(base_executor_path):
		var base_executor_source := FileAccess.get_file_as_string(base_executor_path)
		ctx.expect(base_executor_source.find("func matches(") >= 0, "EnemyBehaviorExecutor should expose matches")
		ctx.expect(base_executor_source.find("func tick(") >= 0, "EnemyBehaviorExecutor should expose tick")
		ctx.expect(base_executor_source.find("func update(") >= 0, "EnemyBehaviorExecutor should expose update")
		ctx.expect(base_executor_source.find("func update_contact(") >= 0, "EnemyBehaviorExecutor should expose update_contact")
		ctx.expect(base_executor_source.find("func reset(") >= 0, "EnemyBehaviorExecutor should expose reset")

	if FileAccess.file_exists(pressure_executor_path):
		var pressure_executor_source := FileAccess.get_file_as_string(pressure_executor_path)
		ctx.expect(pressure_executor_source.find("extends \"res://scripts/enemies/enemy_behavior_executor.gd\"") >= 0, "PressureEnemyBehaviorExecutor should inherit the common behavior contract")
		ctx.expect(pressure_executor_source.find("PressureWarningEffect") >= 0, "PressureEnemyBehaviorExecutor should own pressure warning effects")
		ctx.expect(pressure_executor_source.find("PressureImpactEffect") >= 0, "PressureEnemyBehaviorExecutor should own pressure impact effects")
		ctx.expect(pressure_executor_source.find("take_damage") >= 0, "PressureEnemyBehaviorExecutor should own pressure delayed damage")

	if FileAccess.file_exists(touch_executor_path):
		var touch_executor_source := FileAccess.get_file_as_string(touch_executor_path)
		ctx.expect(touch_executor_source.find("extends \"res://scripts/enemies/enemy_behavior_executor.gd\"") >= 0, "TouchDamageBehaviorExecutor should inherit the common behavior contract")
		ctx.expect(touch_executor_source.find("_cooldown_remaining") >= 0, "TouchDamageBehaviorExecutor should own touch cooldown state")
		ctx.expect(touch_executor_source.find("get_touch_damage") >= 0, "TouchDamageBehaviorExecutor should own touch damage values")
		ctx.expect(touch_executor_source.find("get_touch_knockback") >= 0, "TouchDamageBehaviorExecutor should own enemy touch hit reaction")
		ctx.expect(touch_executor_source.find("get_player_knockback") >= 0, "TouchDamageBehaviorExecutor should own player touch knockback")
		ctx.expect(touch_executor_source.find("get_touch_interval") >= 0, "TouchDamageBehaviorExecutor should own touch cooldown duration")


func check_boss_wide_body_navigation_and_state(ctx, arrow_enemy_skill_data_script, collision_layers) -> void:
	var player = ctx.instantiate_scene("res://scenes/player/player.tscn")
	var boss = ctx.instantiate_scene("res://scenes/enemies/enemy_boss_overseer.tscn")
	if player == null or boss == null:
		return

	var arrow_shot_skill = load("res://resources/enemies/skills/boss_arrow_shot.tres")
	var arrow_rain_skill = load("res://resources/enemies/skills/boss_arrow_rain.tres")
	var boss_skill_pool = load("res://resources/enemies/skill_pools/boss_overseer_skill_pool.tres")
	ctx.expect(arrow_shot_skill != null, "Boss arrow shot skill template should load")
	ctx.expect(arrow_rain_skill != null, "Boss arrow rain skill template should load")
	ctx.expect(boss_skill_pool != null, "Boss Overseer skill pool should load")
	if arrow_shot_skill != null:
		ctx.expect(arrow_shot_skill.get("id") == &"boss_arrow_shot", "Boss arrow shot skill should have a stable id")
		ctx.expect(arrow_shot_skill.get("display_name") != "", "Boss arrow shot skill needs a Chinese display name")
		ctx.expect(arrow_shot_skill.get_script() == arrow_enemy_skill_data_script, "Boss arrow shot should use an arrow-specific skill subclass")
		ctx.expect(int(arrow_shot_skill.get("attack_mode")) == 0, "Boss arrow shot should use SHOT mode")
		ctx.expect(float(arrow_shot_skill.get("cooldown")) > 0.0, "Boss arrow shot needs positive cooldown")
		ctx.expect(float(arrow_shot_skill.get("weight")) > 0.0, "Boss arrow shot needs positive common weight")
		ctx.expect(float(arrow_shot_skill.get("windup_duration")) > 0.0, "Boss arrow shot needs positive windup duration")
		ctx.expect(float(arrow_shot_skill.get("release_duration")) > 0.0, "Boss arrow shot needs positive release duration")
		ctx.expect(float(arrow_shot_skill.get("recover_duration")) > 0.0, "Boss arrow shot needs positive recover duration")
		ctx.expect(float(arrow_shot_skill.get("damage")) > 0.0, "Boss arrow shot needs positive damage")
		ctx.expect(float(arrow_shot_skill.get("knockback")) > 0.0, "Boss arrow shot needs positive knockback")
		ctx.expect(float(arrow_shot_skill.get("warning_length")) > 0.0, "Boss arrow shot needs positive warning length")
		ctx.expect(float(arrow_shot_skill.get("warning_width")) > 0.0, "Boss arrow shot needs positive warning width")
		ctx.expect(float(arrow_shot_skill.get("projectile_speed")) > 0.0, "Boss arrow shot needs positive projectile speed")
		ctx.expect(float(arrow_shot_skill.get("projectile_hit_radius")) > 0.0, "Boss arrow shot needs positive hit radius")
	if arrow_rain_skill != null:
		ctx.expect(arrow_rain_skill.get("id") == &"boss_arrow_rain", "Boss arrow rain skill should have a stable id")
		ctx.expect(arrow_rain_skill.get("display_name") != "", "Boss arrow rain skill needs a Chinese display name")
		ctx.expect(arrow_rain_skill.get_script() == arrow_enemy_skill_data_script, "Boss arrow rain should use an arrow-specific skill subclass")
		ctx.expect(int(arrow_rain_skill.get("attack_mode")) == 1, "Boss arrow rain should use RAIN mode")
		ctx.expect(float(arrow_rain_skill.get("cooldown")) > 0.0, "Boss arrow rain needs positive cooldown")
		ctx.expect(float(arrow_rain_skill.get("windup_duration")) > 0.0, "Boss arrow rain needs positive windup duration")
		ctx.expect(float(arrow_rain_skill.get("release_duration")) > 0.0, "Boss arrow rain needs positive release duration")
		ctx.expect(float(arrow_rain_skill.get("recover_duration")) > 0.0, "Boss arrow rain needs positive recover duration")
		ctx.expect(float(arrow_rain_skill.get("rain_radius")) > 0.0, "Boss arrow rain needs positive radius")
	var base_skill_source := FileAccess.get_file_as_string("res://resources/enemies/enemy_skill_data.gd")
	ctx.expect(base_skill_source.find("dash_speed") == -1, "EnemySkillData base class should not define dash-specific values")
	ctx.expect(base_skill_source.find("warning_length") == -1, "EnemySkillData base class should not define warning-shape values")
	ctx.expect(base_skill_source.find("rain_radius") == -1, "EnemySkillData base class should not define arrow-rain values")
	var arrow_skill_source := FileAccess.get_file_as_string("res://resources/enemies/skills/arrow_enemy_skill_data.gd")
	ctx.expect(arrow_skill_source.find("extends \"res://resources/enemies/enemy_skill_data.gd\"") >= 0, "Arrow skill data should inherit common enemy skill data")
	if boss_skill_pool != null:
		var skills: Array = boss_skill_pool.get("skills")
		ctx.expect(not skills.is_empty(), "Boss skill pool should reserve at least one skill slot")
		ctx.expect(skills.has(arrow_shot_skill), "Boss skill pool should include the arrow shot template")
		ctx.expect(skills.has(arrow_rain_skill), "Boss skill pool should include the arrow rain template")
	if boss.enemy_data != null:
		var resolved_pool = boss.enemy_data.get_skill_pool()
		ctx.expect(resolved_pool == boss_skill_pool, "Boss enemy data should resolve its independent skill pool from its template")
		ctx.expect(boss.enemy_data.display_name == "骸弓督军", "Boss display name should match m20001 bow identity")

	ctx.expect(FileAccess.file_exists("res://art/enemies/m20001/m20001.skel"), "Boss m20001 Spine skeleton should be copied into project art")
	ctx.expect(FileAccess.file_exists("res://art/enemies/m20001/m20001.atlas"), "Boss m20001 Spine atlas should be copied into project art")
	ctx.expect(FileAccess.file_exists("res://art/effects/boss_m20001/charged_arrow/0.png"), "Boss charged arrow sequence frame should be imported")
	ctx.expect(FileAccess.file_exists("res://art/effects/boss_m20001/arrow_fire/0.png"), "Boss arrow impact sequence frame should be imported")
	ctx.expect(FileAccess.file_exists("res://art/effects/boss_m20001/firerain/0.png"), "Boss arrow rain sequence frame should be imported")
	ctx.expect(FileAccess.file_exists("res://art/effects/boss_m20001/firerain_target/0.png"), "Boss arrow rain target sequence frame should be imported")

	var visual: Node = boss.get_node_or_null("Visual")
	ctx.expect(visual != null and visual.has_method("play_attack"), "Boss scene should use a Spine visual with attack animation hooks")

	var shoulder_obstacle: StaticBody2D = ctx.create_test_world_obstacle(Vector2(86.0, 40.0), Vector2(30.0, 20.0), collision_layers.WORLD)
	var effect_container := Node2D.new()
	ctx.root.add_child(player)
	ctx.root.add_child(boss)
	ctx.root.add_child(shoulder_obstacle)
	ctx.root.add_child(effect_container)
	ctx.tree.current_scene = effect_container
	ctx.expect(boss.get_node_or_null("Visual/SpineSprite") != null, "Boss m20001 SpineSprite should load from copied skeleton")
	player.global_position = Vector2(220.0, 0.0)
	boss.global_position = Vector2.ZERO
	boss.call("_reset_navigation_stuck")
	var center_clearance: float = boss.call("_get_center_world_clearance", Vector2.RIGHT, 140.0)
	var wide_clearance: float = boss.call("_get_world_clearance", Vector2.RIGHT, 140.0)
	ctx.expect(is_equal_approx(center_clearance, 140.0), "Boss center ray should stay clear in the shoulder obstacle probe")
	ctx.expect(wide_clearance < center_clearance, "Boss wide body probe should detect shoulder obstacles")

	ctx.expect(boss.has_method("begin_boss_windup"), "Boss should expose a windup state entry for future skills")
	ctx.expect(boss.has_method("begin_boss_dash"), "Boss should expose a dash state entry for future skills")
	ctx.expect(boss.has_method("begin_boss_recover"), "Boss should expose a recover state entry for future skills")
	ctx.expect(boss.has_method("face_skill_direction"), "Boss should expose skill-facing updates for bow attacks")
	ctx.expect(boss.has_method("get_combat_state"), "Boss should expose combat state for skill tests")
	boss.begin_boss_windup(0.2)
	ctx.expect(int(boss.get_combat_state()) == 1, "Boss windup entry should leave chase state")
	boss.begin_boss_dash(Vector2.RIGHT, 120.0, 0.2)
	ctx.expect(int(boss.get_combat_state()) == 2, "Boss dash entry should switch to dash state")
	boss.begin_boss_recover(0.2)
	ctx.expect(int(boss.get_combat_state()) == 3, "Boss recover entry should switch to recover state")
	boss.return_to_chase()
	ctx.expect(int(boss.get_combat_state()) == 0, "Boss should return to chase after skill states")
	if arrow_shot_skill != null:
		boss.call("_start_enemy_skill", arrow_shot_skill, Vector2.RIGHT)
		ctx.expect(int(boss.get_combat_state()) == 1, "Boss arrow shot should start from windup")
		ctx.expect(effect_container.get_child_count() > 0, "Boss arrow shot should spawn a line warning effect")
		var shot_health: float = player.health
		boss._physics_process(float(arrow_shot_skill.get("windup_duration")) + 0.05)
		ctx.expect(int(boss.get_combat_state()) == 2, "Boss arrow shot should enter release after windup")
		_process_effect_children(effect_container, 0.4)
		ctx.expect(player.health < shot_health, "Boss arrow shot should damage the player if the warning is ignored")
		var skill_cooldowns: Dictionary = boss.get("_skill_cooldowns")
		ctx.expect(float(skill_cooldowns.get(arrow_shot_skill.get("id"), 0.0)) > 0.0, "Boss arrow shot should set cooldown from template")
		boss.return_to_chase()
	if arrow_rain_skill != null:
		boss.call("_start_enemy_skill", arrow_rain_skill, Vector2.RIGHT)
		ctx.expect(int(boss.get_combat_state()) == 1, "Boss arrow rain should start from windup")
		ctx.expect(effect_container.get_child_count() > 0, "Boss arrow rain should spawn a target warning effect")
		var rain_health: float = player.health
		boss._physics_process(float(arrow_rain_skill.get("windup_duration")) + 0.05)
		ctx.expect(int(boss.get_combat_state()) == 2, "Boss arrow rain should enter release after windup")
		_process_effect_children(effect_container, float(arrow_rain_skill.get("windup_duration")) + 0.05)
		ctx.expect(player.health < rain_health, "Boss arrow rain should damage the player if they stay in the marked area")
		boss.return_to_chase()

	ctx.tree.current_scene = null
	ctx.remove_instance(effect_container)
	ctx.remove_instance(shoulder_obstacle)
	ctx.remove_instance(boss)
	ctx.remove_instance(player)


func _process_effect_children(container: Node, delta: float) -> void:
	for child in container.get_children():
		if child.has_method("_physics_process"):
			child.call("_physics_process", delta)
		if child.has_method("_process"):
			child.call("_process", delta)


func check_enemy_behavior_variants(ctx, enemy_behavior_pressure: int, enemy_behavior_shield: int) -> void:
	var ranged_data = load("res://resources/enemies/enemy_ranged.tres")
	var shield_data = load("res://resources/enemies/enemy_shield.tres")
	ctx.expect(ranged_data != null, "Ranged pressure enemy data should load")
	ctx.expect(shield_data != null, "Shield enemy data should load")
	if ranged_data != null:
		ctx.expect(ranged_data.has_method("get_behavior_type"), "EnemyData should expose resolved behavior type")
		ctx.expect(ranged_data.has_method("get_pressure_interval"), "EnemyData should expose resolved pressure interval")
		ctx.expect(ranged_data.has_method("get_pressure_range"), "EnemyData should expose resolved pressure range")
		ctx.expect(ranged_data.has_method("get_pressure_radius"), "EnemyData should expose resolved pressure warning radius")
		ctx.expect(ranged_data.has_method("get_pressure_warning_duration"), "EnemyData should expose resolved pressure warning duration")
		if ranged_data.has_method("get_behavior_type"):
			ctx.expect(ranged_data.get_behavior_type() == enemy_behavior_pressure, "Ranged pressure enemy should use PRESSURE behavior")
		if ranged_data.has_method("get_pressure_interval"):
			ctx.expect(ranged_data.get_pressure_interval() > 0.0, "Pressure enemy should resolve pressure interval")
		if ranged_data.has_method("get_pressure_range"):
			ctx.expect(ranged_data.get_pressure_range() > ranged_data.get_stop_distance(), "Pressure enemy range should exceed stop distance")
		if ranged_data.has_method("get_pressure_radius"):
			ctx.expect(ranged_data.get_pressure_radius() > 0.0, "Pressure enemy should resolve warning radius")
		if ranged_data.has_method("get_pressure_warning_duration"):
			ctx.expect(ranged_data.get_pressure_warning_duration() > 0.0, "Pressure enemy should resolve warning duration")
	if shield_data != null:
		ctx.expect(shield_data.has_method("get_behavior_type"), "EnemyData should expose resolved behavior type")
		ctx.expect(shield_data.has_method("get_knockback_taken_mult"), "EnemyData should expose resolved knockback taken multiplier")
		if shield_data.has_method("get_behavior_type"):
			ctx.expect(shield_data.get_behavior_type() == enemy_behavior_shield, "Shield enemy should use SHIELD behavior")
		if shield_data.has_method("get_knockback_taken_mult"):
			ctx.expect(shield_data.get_knockback_taken_mult() < 1.0, "Shield enemy should reduce incoming knockback")

	var player = ctx.instantiate_scene("res://scenes/player/player.tscn")
	var pressure_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_ranged.tscn")
	var shield_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_shield.tscn")
	if player != null and pressure_enemy != null:
		var effect_container := Node2D.new()
		ctx.root.add_child(effect_container)
		ctx.tree.current_scene = effect_container
		ctx.root.add_child(player)
		ctx.root.add_child(pressure_enemy)
		player.global_position = Vector2.ZERO
		pressure_enemy.global_position = Vector2(120.0, 0.0)
		if player.health <= 0.0:
			player.health = player.max_health
		var initial_health: float = player.health
		pressure_enemy._physics_process(0.1)
		ctx.expect(player.health == initial_health, "PRESSURE enemy should warn before dealing damage")
		ctx.expect(effect_container.get_child_count() > 0, "PRESSURE enemy should spawn a warning circle effect")
		var warning_effect_count := effect_container.get_child_count()
		if ranged_data.has_method("get_pressure_warning_duration"):
			pressure_enemy._physics_process(ranged_data.get_pressure_warning_duration() + 0.05)
			ctx.expect(player.health < initial_health, "PRESSURE enemy should damage player after warning if still in the marked area")
			ctx.expect(effect_container.get_child_count() > warning_effect_count, "PRESSURE enemy should spawn an impact effect on hit")
		ctx.remove_instance(pressure_enemy)
		ctx.remove_instance(player)
		ctx.tree.current_scene = null
		ctx.remove_instance(effect_container)
	var dodge_player = ctx.instantiate_scene("res://scenes/player/player.tscn")
	var dodge_enemy = ctx.instantiate_scene("res://scenes/enemies/enemy_ranged.tscn")
	if dodge_player != null and dodge_enemy != null:
		var dodge_effect_container := Node2D.new()
		ctx.root.add_child(dodge_effect_container)
		ctx.tree.current_scene = dodge_effect_container
		ctx.root.add_child(dodge_player)
		ctx.root.add_child(dodge_enemy)
		dodge_player.global_position = Vector2.ZERO
		dodge_enemy.global_position = Vector2(120.0, 0.0)
		if dodge_player.health <= 0.0:
			dodge_player.health = dodge_player.max_health
		var dodge_initial_health: float = dodge_player.health
		dodge_enemy._physics_process(0.1)
		dodge_player.global_position = Vector2(0.0, 120.0)
		if ranged_data != null and ranged_data.has_method("get_pressure_warning_duration"):
			dodge_enemy._physics_process(ranged_data.get_pressure_warning_duration() + 0.05)
			ctx.expect(is_equal_approx(dodge_player.health, dodge_initial_health), "PRESSURE enemy warning should be avoidable by leaving the marked area")
		ctx.remove_instance(dodge_enemy)
		ctx.remove_instance(dodge_player)
		ctx.tree.current_scene = null
		ctx.remove_instance(dodge_effect_container)
	if shield_enemy != null:
		ctx.root.add_child(shield_enemy)
		shield_enemy.apply_hit_reaction(Vector2.RIGHT, 100.0)
		ctx.expect(shield_enemy.velocity.length() < 100.0, "SHIELD enemy should reduce incoming hit reaction")
		ctx.remove_instance(shield_enemy)


func check_enemy_templates_and_pool_variety(ctx) -> void:
	var normal_template = load("res://resources/enemies/templates/enemy_template_normal.tres")
	var boss_template = load("res://resources/enemies/templates/enemy_template_boss.tres")
	ctx.expect(normal_template != null, "Enemy normal template should exist")
	ctx.expect(boss_template != null, "Enemy boss template should exist")
	if boss_template != null:
		ctx.expect(boss_template.get("is_boss"), "Boss template should be marked as boss")

	var enemy_paths := [
		"res://resources/enemies/enemy_basic.tres",
		"res://resources/enemies/enemy_fast.tres",
		"res://resources/enemies/enemy_tank.tres",
		"res://resources/enemies/enemy_swarm.tres",
		"res://resources/enemies/enemy_ranged.tres",
		"res://resources/enemies/enemy_shield.tres",
		"res://resources/enemies/enemy_elite_brute.tres",
		"res://resources/enemies/enemy_boss_overseer.tres",
	]
	var ids: Array[StringName] = []
	for path in enemy_paths:
		var enemy = load(path)
		ctx.expect(enemy != null, "%s should load as EnemyData" % path)
		if enemy == null:
			continue
		ctx.expect(enemy.get("template") != null, "%s should use an enemy template" % path)
		ctx.expect(enemy.has_method("get_max_health"), "%s should expose resolved max health" % path)
		ctx.expect(enemy.has_method("get_move_speed"), "%s should expose resolved move speed" % path)
		ctx.expect(enemy.has_method("get_path_probe_distance"), "%s should expose resolved path probe distance" % path)
		ctx.expect(enemy.has_method("get_path_avoidance_strength"), "%s should expose resolved path avoidance strength" % path)
		ctx.expect(enemy.has_method("get_path_body_probe_scale"), "%s should expose resolved path body probe scale" % path)
		ctx.expect(enemy.has_method("get_path_stuck_time"), "%s should expose resolved path stuck time" % path)
		if enemy.has_method("get_max_health"):
			ctx.expect(enemy.get_max_health() > 0.0, "%s should resolve positive max health" % path)
		if enemy.has_method("get_move_speed"):
			ctx.expect(enemy.get_move_speed() > 0.0, "%s should resolve positive move speed" % path)
		if enemy.has_method("get_path_probe_distance"):
			ctx.expect(enemy.get_path_probe_distance() > 0.0, "%s should resolve positive path probe distance" % path)
		if enemy.has_method("get_path_avoidance_strength"):
			ctx.expect(enemy.get_path_avoidance_strength() > 0.0, "%s should resolve positive path avoidance strength" % path)
		if enemy.has_method("get_path_body_probe_scale"):
			ctx.expect(enemy.get_path_body_probe_scale() > 0.0, "%s should resolve positive path body probe scale" % path)
		if enemy.has_method("get_path_stuck_time"):
			ctx.expect(enemy.get_path_stuck_time() > 0.0, "%s should resolve positive path stuck time" % path)
		ctx.expect(not ids.has(enemy.id), "Enemy id should be unique: %s" % enemy.id)
		ids.append(enemy.id)
	ctx.expect(ids.size() >= 8, "Enemy resources should include several first-pass monster types")
