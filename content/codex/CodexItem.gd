extends Resource
class_name CodexItem

@export var _name: String
@export var short_description: String
@export var long_description: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "") -> void:
	_name = __name
	short_description = shortDescription
	long_description = longDescription
