extends Resource
class_name PlayerData

#Character Info
@export var character_name : String
@export var gender : String
@export var race : String
@export var age : int
@export var homeland : String
@export var background : String
@export var backstory : String

#Attributes
@export var attributes : Array[Attribute]

#Skills
@export var skills : Array[Skill]

#Conditions
@export var fatigue : int
@export var necroticDamage : int
@export var conditions : Array[Condition]

#Other
@export var perks : Array[Perk]
@export var inventory : Dictionary[Item, int]
@export var money : int

#Level Up
@export var levelAvailable : bool
@export var level : int
@export var experience : int
@export var attribute_points : int
@export var skill_points : int
@export var perk_points : int

func _init() -> void:
	# Character Info
	character_name = ""
	gender = ""
	race = ""
	homeland = ""
	background = ""
	backstory = ""

	#Attributes
	attributes = []
	
	#Skills
	skills = []
	
	# Other
	perks = []
	inventory = {}
	money = 300

	# Level Up
	level = 1
	attribute_points = 5
	skill_points = 10
	perk_points = 3
