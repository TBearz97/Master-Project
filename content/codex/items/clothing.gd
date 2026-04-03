extends Armor
class_name Clothing

@export var clothing_type: String
@export var effect: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", weightDB: float = 0, valueDB: int = 0, slotsDB: Array[ItemSlots] = [], physicalDB: int = 0, magicalDB: int = 0, necroticDB: int = 0, clothing_typeDB: String = "", effectDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB, weightDB, valueDB, slotsDB, physicalDB, magicalDB, necroticDB)
	clothing_type = clothing_typeDB
	effect = effectDB

func _print() -> String:
	return super() + "Clothing Type: " + clothing_type + "\nEffect: " + effect
