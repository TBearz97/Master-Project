extends VBoxContainer

@export var mm : Button
@export var ch : Button

func _ready() -> void:
	mm.pressed.connect(_return_to_mm)
	ch.pressed.connect(_to_sheet)
	
func _return_to_mm () :
	PlayerVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_Menu.tscn")
	
func _to_sheet () :
	PlayerVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn")
