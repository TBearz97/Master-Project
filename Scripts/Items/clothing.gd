extends Armor
class_name Clothing

var effect : String

func _init(itemName: String, itemDescription: String, itemWeight : float, itemValue: int, itemSlot : Array[String], itemPhysical : int, itemMagical : int, itemNecrotic : int, itemEffect : String) -> void:
	super(itemName, itemDescription, itemWeight, itemValue, itemSlot, itemPhysical, itemMagical, itemNecrotic)
	effect = itemEffect
