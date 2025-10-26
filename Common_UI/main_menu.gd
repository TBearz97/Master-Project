extends Button

@export var confirm_dialog: ConfirmationDialog    # drag in ConfirmMainMenu

func _ready() -> void:
	pressed.connect(_on_pressed)
	if confirm_dialog:
		# Nice labels
		confirm_dialog.get_ok_button().text = "Leave"
		confirm_dialog.get_cancel_button().text = "Stay"
		# If you didn't set them in the Inspector:
		if confirm_dialog.title.is_empty():
			confirm_dialog.title = "Return to Main Menu?"
		if confirm_dialog.dialog_text.is_empty():
			confirm_dialog.dialog_text = "Are you sure you want to go to main menu? "
			if get_tree().current_scene.name == "Character_Creator" :
				confirm_dialog.dialog_text += "\n Changes will not be saved."
				
		confirm_dialog.confirmed.connect(_on_confirmed)

func _on_pressed() -> void:
	if confirm_dialog:
		confirm_dialog.popup_centered()  # show the modal popup
	else:
		# fallback (no dialog configured)
		_go_to_menu()

func _on_confirmed() -> void:
	if get_tree().current_scene.name != "Character_Creator" :
		PlayerVariables.save()
	_go_to_menu()

func _go_to_menu() -> void:
	get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_Menu.tscn")
	
