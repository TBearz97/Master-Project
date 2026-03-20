extends VBoxContainer

func _ready() -> void:
	%LoadCampaign.pressed.connect(_find_characters)
	%NewCampaign.pressed.connect(_on_pressed)

func _on_pressed() -> void:
	CampaignVariables.resetCampaign()
	get_tree().change_scene_to_file("res://Scenes/Campaign Creator/campaign_creator.tscn")

func _find_characters() -> void:
	%GM_Start_Panel.visible = false
	%CharacterSelect.visible = true
	var grid: GridContainer = %CharacterSelect.get_node("ScrollContainer/GridContainer")
	CampaignVariables._clear_grid(grid)

	var names: Array[String] = _dir_contents()
	for _name in names:
		var bttn := Button.new()
		grid.add_child(bttn)
		bttn.text = _name
		bttn.custom_minimum_size = Vector2(300, 100)
		bttn.pressed.connect(func() -> void:
			CampaignVariables.load(_name)
			get_tree().change_scene_to_file("res://Scenes/Campaign Sheet/CampaignSheet.tscn")
		)
		var del := Button.new()
		grid.add_child(del)
		del.text = "Delete"
		del.custom_minimum_size = Vector2(100, 100)
		del.pressed.connect(func() -> void:
			var dir := DirAccess.open("user://")
			var file_path := "user://campaign/" + _name + ".res"
			if dir:
				if dir.file_exists(file_path):
					var error := dir.remove(file_path)
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

func _dir_contents() -> Array[String]:
	var files: Array[String] = []
	var dir := DirAccess.open("user://campaign")
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if !dir.current_is_dir() and file_name.contains(".res") and file_name != ".res":
				files.append(file_name.left(file_name.length() - 4))
			file_name = dir.get_next()
	else:
		print("An error occurred when trying to access the path.")
	return files
