class_name CharacterPoolData
extends Resource

@export var characters: Array[Resource] = []
@export var default_character_id: StringName = &"core_runner"


func get_default_character() -> Resource:
	for character in characters:
		if character != null and character.get("id") == default_character_id:
			return character
	return null
