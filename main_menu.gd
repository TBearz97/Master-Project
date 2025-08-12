extends Button


@onready var start_panel = get_node("%Start_Panel")
@onready var character_creator = get_node("%Character_Creator")

func _process(_delta):
	visible = !start_panel.visible
	

func _ready():
	pressed.connect(_on_pressed)

func _on_pressed():
	start_panel.visible = true
	character_creator.visible = false
