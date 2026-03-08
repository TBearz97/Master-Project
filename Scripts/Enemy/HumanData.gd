extends CreatureData
class_name HumanData

@export var skills : Array[Skill]

@export var equipment : Equipment

func _init() -> void:
	super()
	skills = []
	equipment = Equipment.new()
