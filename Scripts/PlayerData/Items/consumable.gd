extends Utility
class_name Consumable

@export var healing: int
@export var addiction: int

func _init(itemName: String = "", shortDescription : String = "", longDescription : String = "", itemWeight: float = 0, itemHealing: int = 0, itemEffect: String = "", itemAddiction: int = 0, itemValue: int = 0) -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemEffect, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	healing = itemHealing
	addiction = itemAddiction

func _print() -> String:
	return (super() +
		"Healing: " + str(healing) + "\n" +
		"Addiction: " + str(addiction) + "\n"
	)
