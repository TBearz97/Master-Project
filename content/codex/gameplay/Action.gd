extends CodexItem
class_name Action

const CATEGORY_BASIC := "Basic"
const CATEGORY_ATTACK := "Attack"
const TARGET_SINGLE := "single_target"
const TARGET_MULTI := "multi_target"
const TARGET_AOE := "aoe"

@export var expressions: Array[String]
@export var category: String
@export var ap_cost: int
@export var base_speed: int

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "") -> void:
	super(__name, shortDescription, longDescription)
	expressions = []
	category = CATEGORY_BASIC
	ap_cost = -1
	base_speed = 0



func is_attack_action() -> bool:
	return false


func use(target: CreatureData, source: CreatureData, damageProfile: DamageProfile, context: Dictionary = {}) -> Variant:
	if is_attack_action():
		return RuleEngine.resolveAttack(target, source, damageProfile, self, context)
	match _name:
		"Wait":
			return RuleEngine.markDelayedAction(source, 10)
		"Focus":
			return {
				"success": true,
				"source_name": source._name if source != null else "",
				"generated_mana": RuleEngine.getManaGeneration(source),
				"current_mana": RuleEngine.generateMana(source),
			}
		"Bolster":
			if RuleEngine.hasUsedRoundLimitedAction(source, _name):
				return {"success": false, "reason": "round_limit_reached", "action_name": _name, "source_name": source._name if source != null else ""}
			var bolster_result := RuleEngine.addAllDefenceBonuses(source, 3)
			if bolster_result is Dictionary:
				bolster_result["source_name"] = source._name if source != null else ""
				if bool(bolster_result.get("success", false)):
					RuleEngine.markRoundLimitedActionUsed(source, _name)
			return bolster_result
		"Guard":
			if RuleEngine.hasUsedRoundLimitedAction(source, _name):
				return {"success": false, "reason": "round_limit_reached", "action_name": _name, "source_name": source._name if source != null else ""}
			var guard_result := RuleEngine.addAllDefenceBonuses(target, 3)
			if guard_result is Dictionary:
				guard_result["source_name"] = source._name if source != null else ""
				if bool(guard_result.get("success", false)):
					RuleEngine.markRoundLimitedActionUsed(source, _name)
			return guard_result
		"Brace":
			if RuleEngine.hasUsedRoundLimitedAction(source, _name):
				return {"success": false, "reason": "round_limit_reached", "action_name": _name, "source_name": source._name if source != null else ""}
			var brace_result := RuleEngine.addBraceBonuses(source, 3)
			if brace_result is Dictionary:
				brace_result["source_name"] = source._name if source != null else ""
				if bool(brace_result.get("success", false)):
					RuleEngine.markRoundLimitedActionUsed(source, _name)
			return brace_result
		"First Aid":
			return RuleEngine.performFirstAid(target, source, 5.0)
		"Perform Skill Test":
			return RuleEngine.performSkillTest(source, target, context)
		"Use Quick Item":
			return RuleEngine.useQuickItem(source, context)
		"Swap Loadout":
			return RuleEngine.swapActiveLoadout(source)

	var result: Variant = null
	for expression in expressions:
		result = RuleEngine.evaluate(expression, ["target", "source", "dmgProfile", "action", "context"], [target, source, damageProfile, self, context])
	return result
