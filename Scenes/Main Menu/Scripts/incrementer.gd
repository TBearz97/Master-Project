extends Button

@export var increment : bool
@export var sb : SpinBox

func _ready() -> void:
	pressed.connect(_on_pressed)
	
func _on_pressed():
	if increment:
		sb.value = sb.value + 1
	else :
		sb.value = sb.value - 1
