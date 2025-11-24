extends Item
class_name Utility


var effect : String

func _init(itemName: String, itemDescription: String, itemWeight : float, itemEffect: String, itemValue: int) -> void:
	super(itemName, itemDescription, itemWeight, itemValue)
	effect = itemEffect
