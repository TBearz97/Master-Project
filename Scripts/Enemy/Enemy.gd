extends CodexItem
class_name Enemy

@export var attributes : Array[Attribute]
@export var skills : Array[Skill]

#Other
@export var perks : Array[Perk]
@export var inventory : Dictionary[String, Array]
@export var money : int
@export var equipment : Equipment
@export var level : int

var race : Race
var homeland : Homeland
var background : Background
var fatigue : int
var necroticDamage : int
var conditions : Array[Condition]

func _init(
	__name: String,
	shortDescription: String,
	longDescription: String,
	_attributes: Array[Attribute],
	_skills: Array[Skill],
	_perks: Array[Perk],
	_inventory: Dictionary[String, Array],
	_money: int,
	_equipment: Equipment,
	_level: int
) -> void:
	super(__name, shortDescription, longDescription)

	race = CampaignVariables.codex.Races.values().pick_random()
	homeland = CampaignVariables.codex.Homelands.values().pick_random()
	background = CampaignVariables.codex.Backgrounds.values().pick_random()

	attributes = _attributes
	skills = _skills

	perks = _perks
	inventory = _inventory
	money = _money
	equipment = _equipment

	level = _level
