extends Resource
class_name Item

enum ItemSlots {Head, RightArm, LeftArm, Torso, RightLeg, LeftLeg, QuickItem, WeaponSlot}

@export var _name : String
@export var weight : float
@export var value : int
@export var icon : Texture2D
@export var allowed_slots : Array[ItemSlots]

func _init(itemName: String = "", itemWeight : float = 0, itemValue: int = 0) -> void:
	_name = itemName
	weight = itemWeight
	value = itemValue
	_load_icon_from_name()


func _print() -> String:
	return (
		"Name: " + _name + "\n" +
		"Weight: " + str(weight) + "\n" +
		"Value: " + str(value) + "\n"
		)

func _load_icon_from_name() -> void:
	var file_name = _name.to_lower().replace(" ", "_") + ".png"
	var path = "res://Art/Icons/Items/" + file_name

	if ResourceLoader.exists(path):
		icon = load(path)
	else:
		icon = load("res://Art/Icons/Items/default.png")
