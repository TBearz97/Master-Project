extends Utility
class_name Consumable

@export var healing: int
@export var addiction: int

@export var consumable_type: String
@export var duration: String
@export var alcoholic: bool

func _init(itemName: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemHealing: int = 0, itemCategory: String = "", itemEffect: String = "", itemAddiction: int = 0, itemValue: int = 0, itemType: String = "", itemDuration: String = "", itemAlcoholic: bool = false) -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemCategory, itemEffect, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	healing = itemHealing
	addiction = itemAddiction
	consumable_type = itemType
	duration = itemDuration
	alcoholic = itemAlcoholic

func _print() -> String:
	return (
		super() +
		"Type: " + consumable_type + "\n" +
		"Duration: " + duration + "\n" +
		"Alcoholic: " + str(alcoholic) + "\n" +
		"Healing: " + str(healing) + "\n" +
		"Addiction: " + str(addiction) + "\n"
	)
