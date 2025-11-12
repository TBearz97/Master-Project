extends Button

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	PlayerVariables.new_Character()
	get_tree().change_scene_to_file("res://Scenes/Character Creator/character_creator.tscn")
