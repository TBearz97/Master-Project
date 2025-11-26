extends Resource
class_name Skill

@export var _name : String
@export var value : int
@export var shortDesc : String
@export var longDesc : String



func _init(
		nameDB : String = "",
		valueDB : int = 0,
		shortDescDB : String = "",
		longDescDB : String = ""
	):
	self._name = nameDB
	self.value = valueDB
	self.shortDesc = shortDescDB
	self.longDesc = longDescDB
