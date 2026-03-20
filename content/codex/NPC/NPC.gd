extends CodexItem
class_name NPC

@export var data: CreatureData

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", _data: CreatureData = null) -> void:
	super(__name, shortDescription, longDescription)
	data = _data
