extends CodexItem
class_name Perk

@export var category: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", perkCategory: String = "") -> void:
	super(__name, shortDescription, longDescription)
	category = perkCategory
