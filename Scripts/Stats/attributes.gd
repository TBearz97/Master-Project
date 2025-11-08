extends VBoxContainer

var attributes = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	attributes = JsonData.get_attributes()
	update()

func update() -> void:
	
	%MightValue.text = str(attributes["MGT"])
	%AgilityValue.text = str(attributes["AGI"])
	%EnduranceValue.text = str(attributes["END"])
	%CharismaValue.text = str(attributes["CHA"])
	%IntelligenceValue.text = str(attributes["INT"])
	%ResolveValue.text = str(attributes["RES"])
