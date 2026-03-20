extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	PlayerVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn")
