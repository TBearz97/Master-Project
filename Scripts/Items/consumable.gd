extends Utility
class_name Consumable

var healing : String
var addiction : String

func _init(itemName: String, itemDescription: String, itemWeight : float, itemHealing : String, itemEffect: String, itemAddiction : String,  itemValue: int) -> void:
	super(itemName, itemDescription, itemWeight, itemEffect, itemValue)
	healing = itemHealing
	addiction = itemAddiction
