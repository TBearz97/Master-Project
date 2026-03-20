extends CodexItem
class_name Background

@export var perk : Perk


func _init(__name : String = "", shortDescription : String = "", longDescription : String = "", _perk : Perk = Perk.new()) -> void:
	super(__name, shortDescription, longDescription)
	perk = _perk
	
	if _name != "":
		var error = ResourceSaver.save(self, "res://data/Background/" + _name + ".res")
		if error != 0:
			print("Background Error: " + str(error))
