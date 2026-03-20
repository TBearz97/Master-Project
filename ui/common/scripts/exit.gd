extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	PlayerVariables.save()
	get_tree().quit()
