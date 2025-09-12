extends SpinBox

@export var spb1 : SpinBox
@export var spb2 : SpinBox

var bns1 : int = 1
var bns2 : int = 1

func _ready() -> void:
	spb1.value_changed.connect(_spb1Change)
	spb2.value_changed.connect(_spb2Change)
	updateValue(1,1)
	
func _spb1Change(new_value: int) -> void:
	bns1 = new_value
	updateValue(bns1, bns2)
	
func _spb2Change(new_value: int) -> void:
	bns2 = new_value
	updateValue(bns1, bns2)
	
func updateValue(value1: int, value2: int):
	value = value1 + value2
