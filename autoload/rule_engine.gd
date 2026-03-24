extends Node

enum DiceType { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20 }

signal diceRolled(diceArray)

func evaluate(command: String, variable_names: Array = [], variable_values: Array = []) -> Variant:
	var expression := Expression.new()
	var error := expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())
		return null

	var result: Variant = expression.execute(variable_values, self)

	if not expression.has_execute_failed():
		return result

	return null

func rollDice(num: int, sides: int) -> int:
	var diceArray: Array[int] = []
	var rng := RandomNumberGenerator.new()
	var total := 0
	for i in num:
		var res := rng.randi_range(1, sides)
		total += res
		diceArray.append(res)
	diceRolled.emit(diceArray)
	return total


func dealDamage(target: CreatureData, source: CreatureData = null, damage_profile: DamageProfile = null) -> Dictionary:
	if target == null:
		push_error("dealDamage called with null target.")
		return {"success": false, "reason": "null_target"}

	var profile := damage_profile
	if profile == null:
		profile = _default_damage_profile_from_source(source)

	if profile == null:
		push_error("dealDamage could not determine a damage profile.")
		return {"success": false, "reason": "missing_damage_profile"}

	var damage_roll := 0
	if profile.damage_die > 0:
		damage_roll = rollDice(1, profile.damage_die)

	var crit_roll := 0
	var did_crit := false
	if profile.damage_die > 0 and damage_roll >= profile.damage_die and profile.crit_die > 0:
		did_crit = true
		crit_roll = rollDice(1, profile.crit_die)

	var total_damage: int = max(profile.base_damage + damage_roll + crit_roll, 0)
	target.currentHP = max(target.currentHP - total_damage, 0)

	var result := {
		"success": true,
		"target_name": target._name,
		"source_name": source._name if source != null else "",
		"damage_roll": damage_roll,
		"crit_roll": crit_roll,
		"total_damage": total_damage,
		"did_crit": did_crit,
		"remaining_hp": target.currentHP,
	}

	print("%s took %s damage" % [target._name, total_damage])
	return result
	
func applyCondition(target: CreatureData, condition_name: String) -> void:
	var condition: Condition = CampaignVariables.codex.Conditions.get(condition_name)
	print(target._name + " received " + condition._name)

func _default_damage_profile_from_source(source: CreatureData) -> DamageProfile:
	if source is HumanoidData:
		var humanoid_source := source as HumanoidData
		var equipment: Equipment = humanoid_source.equipment
		if equipment == null:
			return null

		if equipment.weapon1Right != null and equipment.weapon1Right.damage_profile != null:
			return equipment.weapon1Right.damage_profile
		if equipment.weapon1Left != null and equipment.weapon1Left.damage_profile != null:
			return equipment.weapon1Left.damage_profile

	return null
