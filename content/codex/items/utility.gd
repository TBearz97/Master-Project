extends Item
class_name Utility

@export var category: String
@export var effect: String

func _init(idDB: int = -1, itemName: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemCategory: String = "", itemEffect: String = "", itemValue: int = 0) -> void:
	super(idDB, itemName, shortDescription, longDescription, itemWeight, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	category = itemCategory
	effect = itemEffect

func _print() -> String:
	return (
		super() +
		"Category: " + category + "\n" +
		"Effect: " + effect
	)
