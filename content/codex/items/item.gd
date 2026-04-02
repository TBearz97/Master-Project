extends CodexItem
class_name Item

enum ItemSlots { Head, RightArm, LeftArm, Torso, RightLeg, LeftLeg, QuickItem, WeaponSlot }

@export var weight: float
@export var value: int
@export var icon: Texture2D
@export var allowed_slots: Array[ItemSlots]

func _init(idDB:int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", weightDB: float = 0, valueDB: int = 0, slotsDB: Array[ItemSlots] = []) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	weight = weightDB
	value = valueDB
	allowed_slots = slotsDB

	if _name != "":
		_load_icon_from_name()

func _print() -> String:
	return (
		"Name: " + _name + "\n" +
		"Weight: " + str(weight) + "\n" +
		"Value: " + str(value) + "\n"
	)

func _load_icon_from_name() -> void:
	var file_name := _name + ".png"
	var path := "res://Art/Icons/Items/" + file_name
	if ResourceLoader.exists(path):
		icon = load(path) as Texture2D
	else:
		icon = load("res://Art/Icons/Items/default.png") as Texture2D
