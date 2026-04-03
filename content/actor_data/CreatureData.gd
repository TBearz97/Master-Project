extends Resource
class_name CreatureData

var _name: String:
	get:
		return _name
	set(value):
		_name = value

@export var id: int
@export var name: String
@export var short_description: String
@export var long_description: String

@export var type: String
@export var category: String

@export var level: int
@export var max_hp: int
@export var maxHP: int
@export var currentHP: int

@export var attributes: Array[Attribute]
@export var attacks: Array[Attack]
@export var actions: Array[Action]
@export var perks: Array[Perk]
@export var conditions: Array[Condition]
@export var defences: Array[Defence]
@export var modifiers: Dictionary[int, Array[Modifier]]
@export var fatigue: int
@export var necroticDamage: int


func _init() -> void:
	id = 0
	name = ""
	short_description = ""
	long_description = ""
	type = ""
	category = ""
	level = 1
	max_hp = 1
	maxHP = 1
	currentHP = 1
	attributes = []
	attacks = []
	actions = []
	perks = []
	conditions = []
	defences = []
	modifiers = {}
	fatigue = 0
	necroticDamage = 0


func get_modifier_bucket(modifier_id: int) -> Array[Modifier]:
	if modifiers == null:
		modifiers = {}
	if not modifiers.has(modifier_id):
		modifiers[modifier_id] = []
	return modifiers[modifier_id]


func set_modifier_bucket(modifier_id: int, values: Array[Modifier]) -> void:
	if modifiers == null:
		modifiers = {}
	modifiers[modifier_id] = values


func add_modifier(modifier: Modifier) -> void:
	if modifier == null or modifier.id < 0:
		return
	var bucket := get_modifier_bucket(modifier.id)
	bucket.append(modifier)
	modifiers[modifier.id] = bucket


func clear_modifier_bucket(modifier_id: int) -> void:
	if modifiers == null:
		modifiers = {}
	modifiers.erase(modifier_id)


func get_modifier_total(modifier_id: int, base_value: float = 0.0) -> float:
	var current_value := base_value
	var bucket := get_modifier_bucket(modifier_id)
	var flat_total := 0.0
	var percent_add_total := 0.0
	var percent_mult_total := 1.0
	var has_override := false
	var override_value := 0.0

	for modifier in bucket:
		if modifier == null:
			continue
		match modifier.application_type:
			Modifier.ApplicationType.FLAT:
				flat_total += modifier.value
			Modifier.ApplicationType.PERCENT_ADD:
				percent_add_total += modifier.value
			Modifier.ApplicationType.PERCENT_MULT:
				percent_mult_total *= max(0.0, 1.0 + (modifier.value / 100.0))
			Modifier.ApplicationType.OVERRIDE:
				has_override = true
				override_value = modifier.value

	if has_override:
		return override_value

	current_value += flat_total
	current_value += current_value * (percent_add_total / 100.0)
	current_value *= percent_mult_total
	return current_value


func get_modifier_total_int(modifier_id: int, base_value: int = 0) -> int:
	return int(round(get_modifier_total(modifier_id, float(base_value))))
