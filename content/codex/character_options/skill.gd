extends CodexItem
class_name Skill

@export var value: int

func _init(
	__name: String = "",
	shortDescription: String = "",
	longDescription: String = "",
	_value: int = 0
) -> void:
	super(__name, shortDescription, longDescription)
	value = _value
