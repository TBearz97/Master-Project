extends Node

#Character Info
var character_name : String
var gender : String
var race : String
var homeland : String
var background : String
var backstory : String

#Attributes
var attributes : Dictionary = {}

#Skills
var skills : Dictionary = {}

#Other
var perks : Array
var inventory : Dictionary
var money : int

#Level Up
var level : int
var attribute_points : int
var skill_points : int
var perk_points : int

func new_Character() -> void:
	# Character Info
	character_name = ""
	gender = ""
	race = ""
	homeland = ""
	background = ""
	backstory = ""

	#Attributes
	attributes = {}
	
	#Skills
	skills = {}
	
	# Other
	perks = []
	inventory = {}
	money = 300

	# Level Up
	level = 1
	attribute_points = 5
	skill_points = 10
	perk_points = 3
	
func calucalte_Defence (att1 : int, att2 : int):
	return att1 + att2

func level_Up() -> void :
	attribute_points += 1
	skill_points += 2
	perk_points += 1

func save() -> void:
	var data = {
	"CharacterInfo": {
		"character_name": character_name,
		"gender": gender,
		"race": race,
		"homeland": homeland,
		"background": background,
		"backstory": backstory
	},
	"Attributes": attributes,
	"Skills": skills,
	"Other": {
		"perks": perks,
		"inventory": inventory,
		"money": money
	},
	"LevelUp": {
		"level" : level,
		"attribute_points": attribute_points,
		"skill_points": skill_points,
		"perk_points": perk_points
	}
	}
	var _file = FileAccess.open("user://characters/" + character_name + ".json", FileAccess.WRITE)
	_file.store_line(JSON.stringify(data))

func load(_name : String) -> void:
	var file = FileAccess.open("user://characters/" + _name + ".json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	# Assign values back to variables
	var ci = data["CharacterInfo"]
	character_name = ci["character_name"]
	gender = ci["gender"]
	race = ci["race"]
	homeland = ci["homeland"]
	background = ci["background"]
	backstory = ci["backstory"]
	
	attributes = data["Attributes"]
	
	skills = data["Skills"]

	var other = data["Other"]
	perks = other["perks"]
	inventory = other["inventory"]
	money = other["money"]

	var lvl = data["LevelUp"]
	level = lvl["level"]
	attribute_points = lvl["attribute_points"]
	skill_points = lvl["skill_points"]
	perk_points = lvl["perk_points"]

func print_character_info() -> void:
	print("Character Info")
	print("Name: ", character_name)
	print("Gender: ", gender)
	print("Race: ", race)
	print("Homeland: ", homeland)
	print("Background: ", background)
	print("Backstory: ", backstory)
	print("")

	print("Attributes")
	for key in attributes.keys():
		print("  ", key, ": ", attributes[key])
	print("")

	print("Skills")
	for key in skills.keys():
		print("  ", key, ": ", skills[key])
	print("")

	print("Perks")
	for p in perks:
		print("  ", p)
	print("")

	print("Inventory")
	print("  ", inventory)
	print("")

	print("Money: ", money)
	print("")

	print("Level Up")
	print("  Level: ", level)
	print("  Attribute Points: ", attribute_points)
	print("  Skill Points: ", skill_points)
	print("  Perk Points: ", perk_points)
