extends RichTextLabel

@export var btn : Button

func _ready() -> void:
	bbcode_enabled = true
	text = "Click this: Sword"

	meta_clicked.connect(_on_meta_clicked)
	btn.pressed.connect(_on_pressed)

func _on_meta_clicked(meta):
	print("Clicked:", meta)
	
func _on_pressed() :
	var test = "Sword"
	if text.contains(test) :
		print("yes")
		print(text)
		text = text.replace(test, "[url=" + test +"]"+test+"[/url]")
		print(text)
