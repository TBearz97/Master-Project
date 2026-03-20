extends HumanoidData
class_name PlayerData

@export var gender: String
@export var age: int
@export var backstory: String

# Level Up
@export var levelAvailable: bool
@export var experience: int
@export var attribute_points: int
@export var skill_points: int
@export var perk_points: int

func _init() -> void:
	super()
	gender = ""
	age = 0
	backstory = ""

	levelAvailable = false
	experience = 0
	level = 1
	attribute_points = 0
	skill_points = 0
	perk_points = 0
