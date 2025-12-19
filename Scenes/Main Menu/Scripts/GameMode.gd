extends CheckButton

func _ready():
	toggled.connect(_on_check_button_toggled)
	update_button_text(button_pressed)

func _on_check_button_toggled(isPressed: bool) -> void:
	update_button_text(isPressed)

func update_button_text(isPressed: bool) -> void:
	if isPressed:
		text = "GM"
	else:
		text = "Player"
