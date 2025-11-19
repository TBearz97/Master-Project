extends RichTextLabel

@export var btn : Button

func _ready() -> void:
	DbHelper.prepareLabel(self)
	text = DbHelper.replaceText("The Pathfinder moved silently through the edge of the Asharati Forest, guided by a mix of Perception and long-earned Survivor’s Luck. His companion, a Human Scholar of the Old Ways, paused to study the runes etched into an ancient stone, her Insight sharpened by years of Arcane Linguist training. Ahead of them, a Goliath with Titan Grip cleared the path, every motion showing the discipline of someone Born to Fight. Despite the dangers of the wild, the group pushed forward, relying on Animal Handling, quick Investigation, and the steady Resolve that had carried them across the kingdoms from the Quasarian Empire to the Obsidian Desert.")
	meta_clicked.connect(DbHelper._on_meta_clicked)
	btn.pressed.connect(_on_pressed)
	
	
func _on_pressed() :
	var _window = ConfirmationDialog.new()
	add_child(_window)
	_window.size = Vector2(300, 300)
	_window.get_label().text = "test"
	_window.get_cancel_button().visible = false
	_window.get_ok_button().visible = false
	_window.popup()
	_window.position = get_viewport().get_mouse_position()
