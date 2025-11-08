extends VBoxContainer

var defenses = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	defenses = JsonData.get_defenses() # Replace with function body.
	update()

func update() -> void:
	%DeflectionValue.text = str(defenses["deflection"])
	%ReflexValue.text = str(defenses["reflex"])
	%ConstitutionValue.text = str(defenses["constitution"])
	%MindValue.text = str(defenses["mind"])
