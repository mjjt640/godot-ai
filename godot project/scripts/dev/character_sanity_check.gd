extends SceneTree

var _failures: Array[String] = []
var _removed_xp_movement_key := "xp_magnet" + "_speed"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_check_default_character_resource()
	_check_character_template_resource()
	_check_default_character_pool()
	_check_player_applies_character_resource()
	_finish()


func _check_default_character_resource() -> void:
	var character := load("res://resources/characters/character_core_runner.tres")
	if character == null:
		_failures.append("Failed to load default character resource")
		return

	_check_character_fields(character, "Default character")


func _check_character_template_resource() -> void:
	var character := load("res://resources/characters/character_template.tres")
	if character == null:
		_failures.append("Failed to load character template resource")
		return

	_check_character_fields(character, "Character template")


func _check_default_character_pool() -> void:
	var pool := load("res://resources/characters/default_character_pool.tres") as Resource
	if pool == null:
		_failures.append("Failed to load default character pool")
		return

	var characters: Array = pool.get("characters")
	_expect(not characters.is_empty(), "Default character pool needs at least one character")
	var default_character: Resource = pool.call("get_default_character") as Resource
	_expect(default_character != null, "Default character pool should resolve default character")
	if default_character != null:
		_check_character_fields(default_character, "Default pooled character")


func _check_character_fields(character: Resource, label: String) -> void:
	_expect(character.get("id") != &"", "%s needs id" % label)
	_expect(character.get("display_name") != "", "%s needs Chinese display_name" % label)
	_expect(character.get("description") != "", "%s needs Chinese description" % label)
	_expect(float(character.get("move_speed")) > 0.0, "%s needs positive move_speed" % label)
	_expect(float(character.get("max_health")) > 0.0, "%s needs positive max_health" % label)
	_expect(float(character.get("xp_magnet_radius")) > 0.0, "%s needs positive xp_magnet_radius" % label)
	_expect(character.get(_removed_xp_movement_key) == null, "%s should not expose removed XP magnet movement stat" % label)
	_expect(float(character.get("luck")) >= 0.0, "%s needs non-negative luck" % label)
	_expect(float(character.get("attack_speed")) > 0.0, "%s needs positive attack_speed" % label)
	_expect(float(character.get("attack_range")) > 0.0, "%s needs positive attack_range" % label)
	_expect(float(character.get("crit_chance")) >= 0.0, "%s needs non-negative crit_chance" % label)
	_expect(float(character.get("crit_damage_mult")) >= 1.0, "%s needs crit_damage_mult >= 1.0" % label)
	_expect(character.get("starting_fire_module") != null, "%s should reserve starting_fire_module" % label)
	_expect(character.get("starting_payload_module") != null, "%s should reserve starting_payload_module" % label)


func _check_player_applies_character_resource() -> void:
	var packed_scene := load("res://scenes/player/player.tscn") as PackedScene
	if packed_scene == null:
		_failures.append("Failed to load player scene")
		return

	var player := packed_scene.instantiate() as PlayerController
	if player == null:
		_failures.append("Player scene root is not PlayerController")
		return

	root.add_child(player)
	_expect(player.character_data != null, "Player scene should assign default character_data")
	if player.character_data != null:
		_expect(is_equal_approx(player.move_speed, float(player.character_data.get("move_speed"))), "Player should apply character move_speed")
		_expect(is_equal_approx(player.max_health, float(player.character_data.get("max_health"))), "Player should apply character max_health")
		_expect(is_equal_approx(player.get_xp_magnet_radius(), float(player.character_data.get("xp_magnet_radius"))), "Player should apply character xp_magnet_radius")
		_expect(is_equal_approx(player.get_luck(), float(player.character_data.get("luck"))), "Player should apply character luck")
	root.remove_child(player)
	player.free()


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _finish() -> void:
	if _failures.is_empty():
		print("character_sanity_check passed")
		quit(0)
		return

	for failure in _failures:
		push_error(failure)
	quit(1)
