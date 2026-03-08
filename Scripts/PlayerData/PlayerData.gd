extends HumanData
class_name PlayerData


@export var gender : String
@export var race : Race
@export var age : int
@export var homeland : Homeland
@export var background : Background
@export var backstory : String


#Level Up
@export var levelAvailable : bool
@export var experience : int
@export var attribute_points : int
@export var skill_points : int
@export var perk_points : int

func _init() -> void:
	super()
	gender = ""
	race = Race.new()
	homeland = Homeland.new()
	background = Background.new()
	backstory = ""

	#Attributes
	attributes = []
	
	#Skills
	skills = []
	
	# Other
	perks = []
	inventory = {}
	money = 0
	equipment = Equipment.new()

	# Level Up
	level = 1
	attribute_points = 0
	skill_points = 0
	perk_points = 0
