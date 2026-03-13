extends Resource
class_name Codex

@export var Races : Dictionary[String, Race] = {}
@export var Backgrounds: Dictionary[String, Background] = {}
@export var Homelands: Dictionary[String, Homeland] = {}

@export var Attributes: Dictionary[String, Attribute] = {}
@export var Skills: Dictionary[String, Skill] = {}
@export var Defences: Dictionary[String, Defence] = {}

@export var Perks: Dictionary[String, Perk] = {}
@export var Conditions : Dictionary[String, Condition] = {}

@export var Rules: Dictionary[String, Rule] = {}

@export var Items: Dictionary[String, Item] = {}

@export var NPCs: Dictionary[String, CreatureData] = {}

var Keywords : Dictionary[String, CodexItem]
var orderedKeywords : Array

func _init(
	default_races: Dictionary[String, Race] = {},
	default_backgrounds: Dictionary[String, Background] = {},
	default_homelands: Dictionary[String, Homeland] = {},
	default_attributes: Dictionary[String, Attribute] = {},
	default_skills: Dictionary[String, Skill] = {},
	default_defences: Dictionary[String, Defence] = {},
	default_perks: Dictionary[String, Perk] = {},
	default_conditions: Dictionary[String, Condition] = {},
	default_rules: Dictionary[String, Rule] = {},
	default_items: Dictionary[String, Item] = {},
	default_npcs: Dictionary[String, CreatureData] = {}
) -> void:
	Races = default_races
	Backgrounds = default_backgrounds
	Homelands = default_homelands

	Attributes = default_attributes
	Skills = default_skills
	Defences = default_defences

	Perks = default_perks
	Conditions = default_conditions

	Rules = default_rules
	Items = default_items
	NPCs = default_npcs

func addToDictionary(dict : Dictionary, new : CodexItem) -> void:
	dict[new._name] = new

func createKeywords() -> void:
	for d in [Races, Backgrounds, Homelands, Attributes, Skills, Defences, Perks, Conditions, Rules, Items, NPCs]:
		Keywords.merge(d)
	orderedKeywords = Keywords.keys()
	orderedKeywords.sort_custom(func(a, b): return a.length() > b.length())
