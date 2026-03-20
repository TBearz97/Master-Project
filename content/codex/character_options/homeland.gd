extends CodexItem
class_name Homeland

@export var perk: Perk

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", _perk: Perk = Perk.new()) -> void:
	super(__name, shortDescription, longDescription)
	perk = _perk

	if _name != "":
		var error := ResourceSaver.save(self, "res://data/Homeland/" + _name + ".res")
		if error != OK:
			push_error("Homeland save failed for %s: %s" % [_name, error])
