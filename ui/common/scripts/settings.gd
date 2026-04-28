extends MenuButton

@export var edit_character_scene: PackedScene

func _ready() -> void:
	if edit_character_scene != null:
		get_popup().add_item("Edit Character")
		get_popup().id_pressed.connect(func(_id: int) -> void:
			get_tree().change_scene_to_packed(edit_character_scene))
