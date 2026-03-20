extends CodexItem
class_name Defence

@export var attribute1: Attribute
@export var attribute2: Attribute

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", att1: Attribute = Attribute.new(), att2: Attribute = Attribute.new()) -> void:
	super(__name, shortDescription, longDescription)
	attribute1 = att1
	attribute2 = att2

	if _name != "":
		var error := ResourceSaver.save(self, "res://data/Defence/" + _name + ".res")
		if error != OK:
			push_error("Defence save failed for %s: %s" % [_name, error])
