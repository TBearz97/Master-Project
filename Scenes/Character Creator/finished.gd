extends VBoxContainer

@export var mm : Button
@export var ch : Button

func _save_creator_sections() -> void:
	var tab_container := get_parent().get_parent() as TabContainer
	if tab_container == null:
		return
	for tab_name in ["Characteristics", "Attributes", "Skills", "Perks", "Items"]:
		var section_container := tab_container.get_node_or_null(tab_name)
		if section_container == null or section_container.get_child_count() == 0:
			continue
		var section := section_container.get_child(0)
		if section != null and section.has_method("_save"):
			section._save()

func _ready() -> void:
	mm.pressed.connect(_return_to_mm)
	ch.pressed.connect(_to_sheet)
	
func _return_to_mm () :
	_save_creator_sections()
	PlayerVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_Menu.tscn")
	
func _to_sheet () :
	_save_creator_sections()
	PlayerVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn")
