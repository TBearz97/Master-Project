extends Item
class_name Armor

enum ArmorSlot {Head, Torso, Arm, Leg}

@export var armorSlot : Array[ArmorSlot]
@export var physicalDT : int
@export var magicalDT : int
@export var necroticDT : int

func _init(itemName: String= "", itemWeight : float = 0, itemValue: int = 0, itemSlot : String= "", itemPhysical : int = 0, itemMagical : int = 0, itemNecrotic : int = 0) -> void:
	super(itemName, itemWeight, itemValue)
	armorSlot = []
	var slots = itemSlot.split(", ")
	for item in slots :
		match item :
			"Head" : armorSlot.append(ArmorSlot.Head)
			"Torso" : armorSlot.append(ArmorSlot.Torso)
			"Arms" : armorSlot.append(ArmorSlot.Arm)
			"Legs" : armorSlot.append(ArmorSlot.Leg)
	physicalDT = itemPhysical
	magicalDT = itemMagical
	necroticDT = itemNecrotic


func _print() -> String:
	return (super() +
		"Armor Slots: " + printArmorSlots() + "\n" +
		"Physical DT: " + str(physicalDT) + "\n" +
		"Magical DT: " + str(magicalDT) + "\n" +
		"Necrotic DT: " + str(necroticDT) + "\n"
	)

func printArmorSlots() -> String :
	var output = ""
	for slot in armorSlot :
		match slot :
			ArmorSlot.Head : output += "Head "
			ArmorSlot.Torso : output += "Torso "
			ArmorSlot.Arm : output += "Arm " 
			ArmorSlot.Leg : output += "Leg "
	return output
