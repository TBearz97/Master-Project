extends CodexItem
class_name Rule

@export var expression : String

func _init(__name : String = "", shortDescription : String = "", longDescription : String = "", expr : String = "") -> void:
	super(__name, shortDescription, longDescription)
	expression = expr
	
	if _name != "":
		var error = ResourceSaver.save(self, "res://data/Rule/" + _name + ".res")
		if error != 0:
			print("Rule Error: " + str(error))
