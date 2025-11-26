extends Resource
class_name Perk

@export var _name : String
@export var shortDesc : String
@export var longDesc : String
@export var category : String

func _init(perkName : String = "", perkShortDesc : String = "", perkLongDesc : String = "", perkCategory : String = "") -> void:
	_name = perkName
	shortDesc = perkShortDesc
	longDesc = perkLongDesc
	category = perkCategory
