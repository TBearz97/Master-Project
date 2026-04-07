extends CodexItem
class_name Action

const CATEGORY_BASIC := "Basic"
const CATEGORY_ATTACK := "Attack"

@export var expressions: Array[String]
@export var category: String
@export var ap_cost: int
@export var base_speed: int
@export var tested_defence: String
@export var default_target_location: Item.ItemSlots
@export var accuracy_attribute: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "") -> void:
	super(__name, shortDescription, longDescription)
	expressions = []
	category = CATEGORY_BASIC
	ap_cost = -1
	base_speed = 0
	tested_defence = "Deflection"
	default_target_location = Item.ItemSlots.Torso
	accuracy_attribute = "Perception"



func is_attack_action() -> bool:
	if category == CATEGORY_ATTACK:
		return true
	for expression in expressions:
		if expression.contains("dealDamage("):
			return true
	return false


func use(target: CreatureData, source: CreatureData, damageProfile: DamageProfile, context: Dictionary = {}) -> Variant:
	if is_attack_action():
		return RuleEngine.resolveAttack(target, source, damageProfile, self, context)

	var result: Variant = null
	for expression in expressions:
		result = RuleEngine.evaluate(expression, ["target", "source", "dmgProfile", "action", "context"], [target, source, damageProfile, self, context])
	return result
