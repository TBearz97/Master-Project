extends Node

#Character Info
var character_name : String
var gender : String
var race : String
var homeland : String
var background : String
var backstory : String

#Attributes
var might : int
var dexterity : int
var endurance : int
var perception : int
var intelligence : int
var resolve : int

#Skills
var animalHandling : int
var athletics : int
var command : int
var craft : int
var insight : int
var investigation : int
var lore : int
var medicine : int
var sleightOfHand : int
var society : int
var speech : int
var stealth : int
var survival : int

#Other
var perks : Array[String]
var inventory : Array[String]

#Level Up
var attribute_points : int
var skill_points : int
var perk_points : int

func calculate_Damage_Healing_Bonus (MGT: int) -> int:
	return (MGT - 1) * 5 

func calculate_Carry_Weight (MGT: int) -> int:
	return ((MGT - 1) * 5) + 75

func calculate_Action_Points (DEX: int) -> int:
	return DEX + 3
	
func calculate_Speed_Bonus (DEX: int) -> int:
	return (DEX - 1) * 2
	
func calculate_Health_Bonus (END: int) -> int:
	return END + 5
	
func calculate_Vitality_Bonus (END: int) -> int:
	return (3 + floor((END - 1) / 3))

func calculate_Effect_Difficulty (INT: int) -> int:
	return floor((INT - 1) / 2) - 1

func calculate_Mana_Generation (INT: int) -> int:
	return INT

func calculate_Concentration (RES: int) -> int:
	return RES
	
func calculate_Effect_Duration (RES: int) -> int:
	return (RES - 1) * 5

func calculate_Accuracy (PER: int) -> int:
	return floor((PER) / 2)

func calculate_Weapspot_Damage (PER: int) -> int:
	return PER
	
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
  		"Attributes": {
	"might": might,
	"dexterity": dexterity,
	"endurance": endurance,
	"perception": perception,
	"intelligence": intelligence,
	"resolve": resolve
  		},
  		"Skills": {
	"animalHandlig": animalHandling,
	"athletics": athletics,
	"command": command,
	"craft": craft,
	"insight": insight,
	"investigation": investigation,
	"lore": lore,
	"medicine": medicine,
	"sleightOfHand": sleightOfHand,
	"society": society,
	"speech": speech,
	"stealth": stealth,
	"survival": survival
  		},
  		"Other": {
	"perks": perks,
	"inventory": inventory
  		},
  		"LevelUp": {
	"attribute_points": attribute_points,
	"skill_points": skill_points,
	"perk_points": perk_points
  		}
		}
	var _file = FileAccess.open("user://characters" + character_name + ".json", FileAccess.WRITE)
	_file.store_line(JSON.stringify(data))

func load(_name : String) -> void:
	var file = FileAccess.open("user://characters" + _name + ".json", FileAccess.READ)
	var data = JSON.parse_string(file.get_as_text())
	# Assign values back to variables
	var ci = data["CharacterInfo"]
	character_name = ci["character_name"]
	gender = ci["gender"]
	race = ci["race"]
	homeland = ci["homeland"]
	background = ci["background"]
	backstory = ci["backstory"]

	var attr = data["Attributes"]
	might = attr["might"]
	dexterity = attr["dexterity"]
	endurance = attr["endurance"]
	perception = attr["perception"]
	intelligence = attr["intelligence"]
	resolve = attr["resolve"]

	var skills = data["Skills"]
	animalHandling = skills["animalHandling"]
	athletics = skills["athletics"]
	command = skills["command"]
	craft = skills["craft"]
	insight = skills["insight"]
	investigation = skills["investigation"]
	lore = skills["lore"]
	medicine = skills["medicine"]
	sleightOfHand = skills["sleightOfHand"]
	society = skills["society"]
	speech = skills["speech"]
	stealth = skills["stealth"]
	survival = skills["survival"]

	var other = data["Other"]
	perks = other["perks"]
	inventory = other["inventory"]

	var lvl = data["LevelUp"]
	attribute_points = lvl["attribute_points"]
	skill_points = lvl["skill_points"]
	perk_points = lvl["perk_points"]
