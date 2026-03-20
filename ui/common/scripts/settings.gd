extends MenuButton

func _ready() -> void:
	if get_tree().current_scene.name == "CharacterSheet":
		get_popup().add_item("Edit Character")
		get_popup().id_pressed.connect(func(_id: int) -> void:
			PlayerVariables.print_character_info()
			get_tree().change_scene_to_file("res://Scenes/Character Creator/character_creator.tscn"))
