extends CheckButton

@onready var start_panel = get_node("%Start_Panel")

func _process(_delta):
	visible = start_panel.visible

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
