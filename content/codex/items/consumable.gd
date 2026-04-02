extends Utility
class_name Consumable

@export var healing: int
@export var addiction: int
@export var alcoholic: bool
@export var duration: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", weightDB: float = 0, categoryDB: String = "", effectDB: String = "", valueDB: int = 0, healingDB: int = 0, addictionDB: int = 0, alcoholicDB: bool = false, durationDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB, weightDB, categoryDB, effectDB, valueDB)
	allowed_slots = [ItemSlots.QuickItem]
	healing = healingDB
	addiction = addictionDB
	alcoholic = alcoholicDB
	duration = durationDB

func _print() -> String:
	return (
		super() +
		"Healing: " + str(healing) + "\n" +
		"Addiction: " + str(addiction) + "\n" +
		"Alcoholic: " + str(alcoholic) + "\n" +
		"Duration: " + duration + "\n"
	)
