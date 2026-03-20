extends CodexItem
class_name  NPC

@export var data : CreatureData

func _init(__name: String, shortDescription: String, longDescription: String, _data) -> void:
	_name = __name
	short_description = shortDescription
	long_description = longDescription
	data = _data
