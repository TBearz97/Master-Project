extends CheckButton

@onready var start_panel = get_node("%Start_Panel")

func _process(_delta):
	visible = start_panel.visible

func _ready():
	toggled.connect(_on_check_button_toggled)
	update_button_text(button_pressed)

func _on_check_button_toggled(button_pressed: bool) -> void:
	update_button_text(button_pressed)

func update_button_text(pressed: bool) -> void:
	if pressed:
		text = "GM"
	else:
		text = "Player"
