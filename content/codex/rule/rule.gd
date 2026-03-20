extends CodexItem
class_name Rule

@export var expression: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", expr: String = "") -> void:
	super(__name, shortDescription, longDescription)
	expression = expr

	if _name != "":
		var error := ResourceSaver.save(self, "res://data/Rule/" + _name + ".res")
		if error != OK:
			push_error("Rule save failed for %s: %s" % [_name, error])
