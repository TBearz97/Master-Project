extends Resource
class_name CreatureData

@export var _name: String
@export var attributes: Array[Attribute]
@export var defences: Array[Defence]

# Conditions
@export var maxHP: float
@export var currentHP: float
@export var maxVitality: float
@export var currentVitality: float
@export var temporaryHealth: float
@export var maxConcentration: int
@export var currentConcentration: int
@export var currentMana: int
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
	maxConcentration = 0
	currentConcentration = 0
	currentMana = 0
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

func getMaxHealth() -> float:
	var attribute: Attribute = _get_attribute("Constitution")
	if attribute == null:
		return maxf(maxHP, 1.0)
	var health_per_level: float = float(_evaluate_attribute_bonus(attribute, "Health"))
	var max_health: float = (health_per_level * float(max(level, 1))) - float(necroticDamage)
	return maxf(max_health, 1.0)

func getMaxVitality() -> float:
	var attribute: Attribute = _get_attribute("Constitution")
	if attribute == null:
		return maxf(maxVitality, 1.0)
	var vitality_multiplier: float = float(_evaluate_attribute_bonus(attribute, "Vitality"))
	var max_vitality: float = vitality_multiplier * getMaxHealth()
	return maxf(max_vitality, 1.0)

func getMaxConcentration() -> int:
	var attribute: Attribute = _get_attribute("Resolve")
	if attribute == null:
		return maxi(maxConcentration, 0)
	return maxi(_evaluate_attribute_bonus(attribute, "Concentration"), 0)

func getCondition(condition_name: String) -> Condition:
	for condition: Condition in conditions:
		if condition != null and condition._name == condition_name:
			return condition
	return null

func hasCondition(condition_name: String) -> bool:
	return getCondition(condition_name) != null

func addCondition(condition: Condition) -> bool:
	if condition == null or condition._name.is_empty() or hasCondition(condition._name):
		return false
	conditions.append(condition)
	return true

func removeCondition(condition_name: String) -> bool:
	for index in range(conditions.size()):
		var condition := conditions[index]
		if condition != null and condition._name == condition_name:
			conditions.remove_at(index)
			return true
	return false

func normalizeVitals(refill_if_uninitialized: bool = false) -> void:
	var previous_max_hp := maxHP
	var previous_max_vitality := maxVitality
	var previous_max_concentration := maxConcentration
	maxHP = getMaxHealth()
	maxVitality = getMaxVitality()
	maxConcentration = getMaxConcentration()
	var refill_health := refill_if_uninitialized and previous_max_hp <= 1.0 and currentHP <= 0.0
	var refill_vitality := refill_if_uninitialized and previous_max_vitality <= 1.0 and currentVitality <= 0.0
	var refill_concentration := refill_if_uninitialized and previous_max_concentration <= 0 and currentConcentration <= 0
	if refill_health:
		currentHP = maxHP
	else:
		currentHP = clampf(currentHP, 0.0, maxHP)
	if refill_vitality:
		currentVitality = maxVitality
	else:
		currentVitality = clampf(currentVitality, 0.0, maxVitality)
	if refill_concentration:
		currentConcentration = maxConcentration
	else:
		currentConcentration = clampi(currentConcentration, 0, maxConcentration)
	currentMana = maxi(currentMana, 0)
	temporaryHealth = maxf(temporaryHealth, 0.0)

func healHealth(amount: float) -> Dictionary:
	if currentVitality <= 0.0:
		return {"success": false, "reason": "target_dead"}
	var healed_amount: float = maxf(amount, 0.0)
	var previous_hp: float = currentHP
	currentHP = clampf(currentHP + healed_amount, 0.0, maxHP)
	return {
		"success": true,
		"target_name": _name,
		"healed_amount": currentHP - previous_hp,
		"remaining_hp": currentHP,
		"remaining_vitality": currentVitality,
		"remaining_concentration": currentConcentration,
		"is_unconscious": RuleEngine.isUnconscious(self),
		"is_dead": RuleEngine.isDead(self),
	}
