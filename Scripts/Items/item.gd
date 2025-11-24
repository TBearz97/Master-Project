extends Resource
class_name Item

var name
var description
var weight
var value

func _init(itemName: String, itemDescription: String, itemWeight : float, itemValue: int) -> void:
	name = itemName
	description = itemDescription
	weight = itemWeight
	value = itemValue

func use(target) -> void:
	print(name, " has no special effect.")
