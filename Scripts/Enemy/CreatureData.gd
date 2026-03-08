extends Resource
class_name CreatureData

@export var _name : String
@export var attributes : Array[Attribute]

#Conditions
@export var maxHP : int
@export var currentHP : int
@export var fatigue : int
@export var necroticDamage : int
@export var conditions : Array[Condition]

#Other
@export var perks : Array[Perk]
@export var inventory : Dictionary[String, Array]
@export var money : int

@export var level : int

func _init() -> void:
	_name = ""
	attributes = []
	perks = []
	inventory = {}
	money = 0

	# Level Up
	level = 1
