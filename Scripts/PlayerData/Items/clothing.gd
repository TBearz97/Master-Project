extends Armor
class_name Clothing

@export var effect: String

func _init(itemName: String = "", itemWeight: float = 0, itemValue: int = 0, itemSlot: String = "", itemPhysical: int = 0, itemMagical: int = 0, itemNecrotic: int = 0, itemEffect: String = "") -> void:
	super(itemName, itemWeight, itemValue, itemSlot, itemPhysical, itemMagical, itemNecrotic)
	effect = itemEffect


func _print() -> String:
	return (super() + "Effect: " + effect)
