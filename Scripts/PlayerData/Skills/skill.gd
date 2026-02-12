extends CodexItem
class_name Skill

@export var value : int



func _init(
		__name : String = "",
		shortDescription : String = "",
		longDescription : String = "",
		_value : int = 0
	):
	super(__name, shortDescription, longDescription)
	self.value = _value
	
	if _name != "":
		var error = ResourceSaver.save(self, "res://data/Skill/" + _name + ".res")
		if error != 0:
			print("Race Error: " + str(error))
