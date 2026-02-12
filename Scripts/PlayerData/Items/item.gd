extends CodexItem
class_name Item

enum ItemSlots {Head, RightArm, LeftArm, Torso, RightLeg, LeftLeg, QuickItem, WeaponSlot}

@export var weight : float
@export var value : int
@export var icon : Texture2D
@export var allowed_slots : Array[ItemSlots]

func _init(__name : String = "", shortDescription : String = "", longDescription : String = "", itemWeight : float = 0, itemValue : int = 0) -> void:
	super(__name, shortDescription, longDescription)
	weight = itemWeight
	value = itemValue
	allowed_slots = []
	
	if _name != "":
		_load_icon_from_name()
		var error = ResourceSaver.save(self, "res://data/Item/" + _name + ".res")
		if error != 0:
			print("Item Error: " + str(error))

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
		icon = load(path)
	else:
		icon = load("res://Art/Icons/Items/default.png")
