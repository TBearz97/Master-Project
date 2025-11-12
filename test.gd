extends Node

@export var bttn : Button
@export var sb : SpinBox
@export var sb2 : SpinBox

func _ready() -> void:
	bttn.pressed.connect(_on_pressed.bind(sb, sb2))

func _on_pressed (dc : SpinBox, skill : SpinBox) :
	var data = DbHelper.db_fetch("SELECT * FROM Test")
	var _expression = data[0]["expression"]
	print(Expressions.evaluate(_expression, ["DC", "SKILL"], [dc.value, skill.value]))
	
