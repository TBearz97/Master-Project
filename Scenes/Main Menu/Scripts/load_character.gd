extends Button

@export var character_select : GridContainer
@onready var start_panel : Panel = %Start_Panel
@onready var character_panel : Panel = %CharacterSelect

func _ready() -> void:
	pressed.connect(_find_characters)

func _find_characters():
	start_panel.visible = false
	character_panel.visible = true
	
	CampaignVariables._clear_grid(character_select)
	
	var names = dir_contents()
	for _name in names :
		var bttn = Button.new()
		character_select.add_child(bttn)
		bttn.text = _name
		bttn.custom_minimum_size = Vector2(300, 100)
		bttn.pressed.connect(func():
			PlayerVariables.load(_name)  # r contains name/short/long
			get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn")
		)
		var del = Button.new()
		character_select.add_child(del)
		del.text = "Delete"
		del.custom_minimum_size = Vector2(100, 100)
		del.pressed.connect(func():
			var dir = DirAccess.open("user://")
			var file_path = "user://characters/" + _name + ".res"
			if dir:
				if dir.file_exists(file_path):
					var error = dir.remove(file_path)
					if error == OK:
						print("File deleted successfully: " + file_path)
					else:
						print("Error deleting file: " + file_path + " (Error code: " + str(error) + ")")
				else:
					print("File does not exist: " + file_path)
			else:
				print("Could not open directory access.")
			_find_characters()
		)

func dir_contents() -> Array[String]:
	var files : Array[String]
	var dir = DirAccess.open("user://characters")
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.contains(".res") and file_name != ".res":
				files.append(file_name.left(file_name.length() - 4))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return files
