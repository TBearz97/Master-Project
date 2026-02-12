extends CodexItem
class_name Defence

@export var attribute1 : Attribute
@export var attribute2 : Attribute

func _init(__name : String = "", shortDescription : String = "", longDescription : String = "", att1 : Attribute = null, att2: Attribute = null) -> void:
	super(__name, shortDescription, longDescription)
	attribute1 = att1
	attribute2 = att2
	
	if _name != "":
		var error = ResourceSaver.save(self, "res://data/Defence/" + _name + ".res")
		if error != 0:
			print("Race Error: " + str(error))
