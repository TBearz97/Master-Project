extends Resource
class_name Item

@export var _name : String
@export var weight : float
@export var value : int

func _init(itemName: String = "", itemWeight : float = 0, itemValue: int = 0) -> void:
	_name = itemName
	weight = itemWeight
	value = itemValue


func _print() -> String:
	return (
		"Name: " + _name + "\n" +
		"Weight: " + str(weight) + "\n" +
		"Value: " + str(value) + "\n"
		)
