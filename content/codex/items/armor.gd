extends Item
class_name Armor

@export var physicalDT: int
@export var magicalDT: int
@export var necroticDT: int

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", weightDB: float = 0, valueDB: int = 0, slotsDB: Array[ItemSlots] = [], physicalDB: int = 0, magicalDB: int = 0, necroticDB: int = 0) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB, weightDB, valueDB)
	allowed_slots = slotsDB
	physicalDT = physicalDB
	magicalDT = magicalDB
	necroticDT = necroticDB

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

	return (
		super() +
		"Armor Slots: " + str(armor_slots) + "\n" +
		"Physical DT: " + str(physicalDT) + "\n" +
		"Magical DT: " + str(magicalDT) + "\n" +
		"Necrotic DT: " + str(necroticDT) + "\n"
	)
