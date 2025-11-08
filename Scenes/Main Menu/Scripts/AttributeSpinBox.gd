extends SpinBox

@export var ID : int
@export var label : Label
@export var bonus1 : SpinBox
@export var bonus2 : SpinBox

var dbFetch
var attribute

func _ready() -> void:
	dbFetch = DbHelper.db_fetch("SELECT name, short_description, long_description, bonus_1_prefix, bonus_2_prefix, bonus_1_expression, bonus_2_expression, bonus_1_suffix, bonus_2_suffix FROM Attributes WHERE ID = " + str(ID))
	attribute = dbFetch[0]
	
	label.text = attribute["name"]
	label.tooltip_text = attribute["short_description"]
	bonus1.prefix = attribute["bonus_1_prefix"]
	bonus1.suffix = attribute["bonus_1_suffix"]
	bonus2.prefix = attribute["bonus_2_prefix"]
	bonus2.suffix = attribute["bonus_2_suffix"]
	value_changed.connect(_on_value_changed)
	_on_value_changed(1)
	

func _on_value_changed(new_value: int) -> void:
	print(new_value, attribute["name"])
	bonus1.value = Expressions.evaluateInt(attribute["bonus_1_expression"], ["x"], [new_value])
	if attribute["name"] != "Perception" :
		bonus2.value = Expressions.evaluateInt(attribute["bonus_2_expression"], ["x"], [new_value])
	else :
		bonus2.value = 1
		var diceType = Expressions.evaluateInt(attribute["bonus_2_expression"], ["x"], [new_value])
		match diceType :
			1 :
				bonus2.suffix = "d4"
			2:
				bonus2.suffix = "d6"
			3:
				bonus2.suffix = "d8"
			4:
				bonus2.suffix = "d10"
			5:
				bonus2.suffix = "d12"
			6:
				bonus2.suffix = "d20"
	
