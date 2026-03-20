extends Item
class_name Armor

@export var physicalDT: int
@export var magicalDT: int
@export var necroticDT: int

func _init(__name : String = "", shortDescription : String = "", longDescription : String = "", itemWeight : float = 0, itemValue : int = 0, itemSlot: Array[ItemSlots] = [], itemPhysical: int = 0, itemMagical: int = 0, itemNecrotic: int = 0) -> void:
	super(__name, shortDescription, longDescription, itemWeight, itemValue)
	allowed_slots = itemSlot
	physicalDT = itemPhysical
	magicalDT = itemMagical
	necroticDT = itemNecrotic


func _print() -> String:
	var armor_slots := ""
	for slot in allowed_slots:
		match slot:
			ItemSlots.Head:
				armor_slots += "[Head]"
			ItemSlots.LeftArm:
				armor_slots += "[Left Arm]"
			ItemSlots.RightArm:
				armor_slots += "[Right Arm]"
			ItemSlots.LeftLeg:
				armor_slots += "[Left Leg]"
			ItemSlots.RightLeg:
				armor_slots += "[Right Leg]"
			ItemSlots.Torso:
				armor_slots += "[Torso]"

	return (super() +
		"Armor Slots: " + str(armor_slots) + "\n" +
		"Physical DT: " + str(physicalDT) + "\n" +
		"Magical DT: " + str(magicalDT) + "\n" +
		"Necrotic DT: " + str(necroticDT) + "\n"
	)
