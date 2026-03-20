extends CreatureData
class_name HumanoidData

@export var skills: Array[Skill]
@export var equipment: Equipment
@export var race: Race
@export var homeland: Homeland
@export var background: Background

func _init() -> void:
	super()
	skills = []
	equipment = Equipment.new()
	race = Race.new()
	homeland = Homeland.new()
	background = Background.new()
