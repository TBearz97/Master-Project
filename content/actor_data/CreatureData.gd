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

func _get_attribute(attribute_name: String) -> Attribute:
	for attribute: Attribute in attributes:
		if attribute != null and attribute._name == attribute_name:
			return attribute
	return null

func _evaluate_attribute_bonus(attribute: Attribute, bonus_label: String) -> int:
	if attribute == null:
		return 0
	if attribute.bonus_1_prefix.contains(bonus_label) and not attribute.bonus_1_expression.is_empty():
		return int(RuleEngine.evaluate(attribute.bonus_1_expression, ["x"], [attribute.value]))
	if attribute.bonus_2_prefix.contains(bonus_label) and not attribute.bonus_2_expression.is_empty():
		return int(RuleEngine.evaluate(attribute.bonus_2_expression, ["x"], [attribute.value]))
	return 0

func getActionPoints() -> int:
	var attribute: Attribute = _get_attribute("Dexterity")
	var action_points: int = _evaluate_attribute_bonus(attribute, "Action Points")
	action_points -= fatigue
	var bonuses: Dictionary = get_meta("temporary_action_point_bonuses", {})
	action_points += int(bonuses.get("amount", 0))
	return max(action_points, 0)

func getMaxHealth() -> int:
	var attribute: Attribute = _get_attribute("Constitution")
	if attribute == null:
		return max(maxHP, 1)
	var health_per_level: int = _evaluate_attribute_bonus(attribute, "Health")
	var max_health: int = (health_per_level * max(level, 1)) - necroticDamage
	return max(max_health, 1)

func getMaxVitality() -> int:
	var attribute: Attribute = _get_attribute("Constitution")
	if attribute == null:
		return max(maxVitality, 1)
	var vitality_multiplier: int = _evaluate_attribute_bonus(attribute, "Vitality")
	var max_vitality: int = vitality_multiplier * getMaxHealth()
	return max(max_vitality, 1)

func normalizeVitals(refill_if_uninitialized: bool = false) -> void:
	var previous_max_hp := maxHP
	var previous_max_vitality := maxVitality
	maxHP = getMaxHealth()
	maxVitality = getMaxVitality()
	if refill_if_uninitialized and (currentHP <= 0 or previous_max_hp <= 1):
		currentHP = maxHP
	else:
		currentHP = clampi(currentHP, 0, maxHP)
	if refill_if_uninitialized and (currentVitality <= 0 or previous_max_vitality <= 1):
		currentVitality = maxVitality
	else:
		currentVitality = clampi(currentVitality, 0, maxVitality)
	temporaryHealth = maxi(temporaryHealth, 0)

func healHealth(amount: int) -> Dictionary:
	if currentVitality <= 0:
		return {"success": false, "reason": "target_dead"}
	var healed_amount := maxi(amount, 0)
	var previous_hp := currentHP
	currentHP = clampi(currentHP + healed_amount, 0, maxHP)
	return {
		"success": true,
		"target_name": _name,
		"healed_amount": currentHP - previous_hp,
		"remaining_hp": currentHP,
		"remaining_vitality": currentVitality,
		"is_unconscious": currentHP <= 0 and currentVitality > 0,
		"is_dead": currentVitality <= 0,
	}
