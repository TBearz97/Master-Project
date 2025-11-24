extends Item
class_name Armor

enum ArmorSlot {Head, Torso, Arm, Leg}

var armorSlot : Array[ArmorSlot]
var physicalDT : int
var magicalDT : int
var necroticDT : int

func _init(itemName: String, itemDescription: String, itemWeight : float, itemValue: int, itemSlot : Array[String], itemPhysical : int, itemMagical : int, itemNecrotic : int) -> void:
	super(itemName, itemDescription, itemWeight, itemValue)
	armorSlot = []
	for item in itemSlot :
		match itemSlot :
			"Head" : armorSlot.append(ArmorSlot.Head)
			"Torso" : armorSlot.append(ArmorSlot.Torso)
			"Arm" : armorSlot.append(ArmorSlot.Arm)
			"Leg" : armorSlot.append(ArmorSlot.Leg)
	physicalDT = itemPhysical
	magicalDT = itemMagical
	necroticDT = itemNecrotic
