extends CodexItem
class_name Item

enum ItemSlots { Head, RightArm, LeftArm, Torso, RightLeg, LeftLeg, QuickItem, WeaponSlot }

@export var weight: float
@export var value: int
@export var icon: Texture2D
@export var allowed_slots: Array[ItemSlots]

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemValue: int = 0) -> void:
	super(__name, shortDescription, longDescription)
	weight = itemWeight
	value = itemValue
	allowed_slots = []

	if _name != "":
		_load_icon_from_name()

func _print() -> String:
	var details := [
		"Name: %s" % _name,
		"Weight: %s" % str(weight),
		"Value: %s" % str(value),
	]
	var summary := short_description.strip_edges()
	var description := long_description.strip_edges()
	if not summary.is_empty():
		details.append("Flavor: %s" % summary)
	if not description.is_empty() and description != summary:
		details.append("Description: %s" % description)
	return "\n".join(details) + "\n"

func _load_icon_from_name() -> void:
	var file_name := _name + ".png"
	var path := "res://Art/Icons/Items/" + file_name
	if ResourceLoader.exists(path):
		icon = load(path) as Texture2D
	else:
		icon = load("res://Art/Icons/Items/default.png") as Texture2D
