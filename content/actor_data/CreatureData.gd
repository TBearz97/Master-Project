extends Resource
class_name CreatureData

@export var _name: String
@export var attributes: Array[Attribute]
@export var defences: Array[Defence]

# Conditions
@export var maxHP: int
@export var currentHP: int
@export var maxVitality: int
@export var currentVitality: int
@export var temporaryHealth: int
@export var fatigue: int
@export var necroticDamage: int
@export var conditions: Array[Condition]

# Other
@export var actions: Array[Action]
@export var perks: Array[Perk]
@export var inventory: Dictionary[String, Array]
@export var money: int
@export var level: int

func _init() -> void:
	_name = ""
	attributes = []
	defences = []
	maxHP = 0
	currentHP = 0
	maxVitality = 0
	currentVitality = 0
	temporaryHealth = 0
	fatigue = 0
	necroticDamage = 0
	conditions = []
	
	actions = []
	perks = []
	inventory = {}
	money = 0
	level = 1
