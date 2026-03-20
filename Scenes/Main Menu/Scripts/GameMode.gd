extends CheckButton

func _ready() -> void:
	if get_tree().current_scene.name != "Main_Menu":
		hide()
	toggled.connect(_on_check_button_toggled)
	update_button_text(button_pressed)

func _on_check_button_toggled(isPressed: bool) -> void:
	update_button_text(isPressed)

func update_button_text(isPressed: bool) -> void:
	if get_tree().current_scene.name == "Main_Menu":
		if isPressed:
			text = "GM"
			get_parent().get_parent().get_parent().get_node("MarginContainer/Start_Panel").hide()
			get_parent().get_parent().get_parent().get_node("MarginContainer/GM_Start_Panel").show()
		else:
			text = "Player"
			get_parent().get_parent().get_parent().get_node("MarginContainer/Start_Panel").show()
			get_parent().get_parent().get_parent().get_node("MarginContainer/GM_Start_Panel").hide()
