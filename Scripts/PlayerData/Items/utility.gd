extends Item
class_name Utility


@export var effect : String

func _init(itemName: String = "", itemWeight : float = 0, itemEffect: String = "", itemValue: int = 0) -> void:
	super(itemName, itemWeight, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	effect = itemEffect


func _print() -> String:
	return (super() +
		"Effect: " + effect
	)
