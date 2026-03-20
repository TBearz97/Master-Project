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

	if _name != "":
		var error := ResourceSaver.save(self, "res://data/Skill/" + _name + ".res")
		if error != OK:
			push_error("Skill save failed for %s: %s" % [_name, error])
