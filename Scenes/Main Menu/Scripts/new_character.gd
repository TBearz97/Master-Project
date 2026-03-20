extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	PlayerVariables.data = PlayerData.new()
	PlayerVariables.setAttributePoints(5)
	PlayerVariables.setSkillPoints(10)
	PlayerVariables.setPerkPoints(3)
	PlayerVariables.setMoney(300)
	get_tree().change_scene_to_file("res://Scenes/Character Creator/character_creator.tscn")
