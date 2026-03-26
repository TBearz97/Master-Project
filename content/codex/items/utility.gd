extends Item
class_name Utility

@export var category: String
@export var effect: String

func _init(itemName: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemCategory: String = "", itemEffect: String = "", itemValue: int = 0) -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	category = itemCategory
	effect = itemEffect

func _print() -> String:
	return (
		super() +
		"Category: " + category + "\n" +
		"Effect: " + effect
	)
