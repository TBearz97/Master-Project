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

func addDefenceBonus(target: CreatureData, defence_name: String, amount: int, duration: String = "round") -> Dictionary:
	if target == null:
		push_error("addDefenceBonus called with null target.")
		return {"success": false, "reason": "null_target"}

	var bonuses: Dictionary = target.get_meta("temporary_defence_bonuses", {})
	var defence_state: Dictionary = bonuses.get(defence_name, {"amount": 0, "duration": duration})
	defence_state["amount"] = int(defence_state.get("amount", 0)) + amount
	defence_state["duration"] = duration
	bonuses[defence_name] = defence_state
	target.set_meta("temporary_defence_bonuses", bonuses)

	return {
		"success": true,
		"target_name": target._name,
		"defence_name": defence_name,
		"amount": amount,
		"duration": duration,
		"total_bonus": defence_state["amount"],
	}

func swapActiveLoadout(source: CreatureData) -> Dictionary:
	if source == null:
		push_error("swapActiveLoadout called with null source.")
		return {"success": false, "reason": "null_source"}

	var current_loadout := int(source.get_meta("active_loadout", 1))
	var next_loadout := 2 if current_loadout == 1 else 1
	source.set_meta("active_loadout", next_loadout)

	return {
		"success": true,
		"source_name": source._name,
		"active_loadout": next_loadout,
	}

func markDelayedAction(source: CreatureData, amount: int = 1) -> Dictionary:
	if source == null:
		push_error("markDelayedAction called with null source.")
		return {"success": false, "reason": "null_source"}

	var delayed_amount := int(source.get_meta("delayed_action_amount", 0)) + amount
	source.set_meta("delayed_action_amount", delayed_amount)

	return {
		"success": true,
		"source_name": source._name,
		"delayed_action_amount": delayed_amount,
	}

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
