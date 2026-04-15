extends Action
class_name Attack

@export var attack_power: int
@export var mana_cost: int
@export var condition: String
@export var target: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "") -> void:
	super(__name, shortDescription, longDescription)
	category = CATEGORY_ATTACK
	attack_power = 100
	mana_cost = 0
	condition = ""
	target = TARGET_SINGLE


func is_attack_action() -> bool:
	return true


func use(target_actor: CreatureData, source_actor: CreatureData, damage_profile: DamageProfile, context: Dictionary = {}) -> Variant:
	return RuleEngine.resolveAttack(target_actor, source_actor, damage_profile, self, context)
