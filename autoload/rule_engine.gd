extends Node

enum DiceType { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20 }

signal diceRolled(diceArray)

func _get_attribute(source: CreatureData, attribute_name: String) -> Attribute:
	if source == null:
		return null
	for attribute: Attribute in source.attributes:
		if attribute != null and attribute._name == attribute_name:
			return attribute
	return null

func _evaluate_attribute_bonus(attribute: Attribute, bonus_label: String) -> int:
	if attribute == null:
		return 0
	if attribute.bonus_1_prefix.contains(bonus_label) and not attribute.bonus_1_expression.is_empty():
		return int(evaluate(attribute.bonus_1_expression, ["x"], [attribute.value]))
	if attribute.bonus_2_prefix.contains(bonus_label) and not attribute.bonus_2_expression.is_empty():
		return int(evaluate(attribute.bonus_2_expression, ["x"], [attribute.value]))
	return 0

func getAccuracy(source: CreatureData, action: Action = null) -> int:
	if source == null:
		return 0

	var attribute_name := "Perception"
	if action != null and not action.accuracy_attribute.is_empty():
		attribute_name = action.accuracy_attribute

	var attribute := _get_attribute(source, attribute_name)
	var accuracy := _evaluate_attribute_bonus(attribute, "Accuracy")
	var bonuses: Dictionary = source.get_meta("temporary_accuracy_bonuses", {})
	accuracy += int(bonuses.get("amount", 0))
	return accuracy

func getCritDie(source: CreatureData, _action: Action = null) -> int:
	if source == null:
		return 0

	var attribute := _get_attribute(source, "Perception")
	var crit_die := _evaluate_attribute_bonus(attribute, "Crit Dice")
	var bonuses: Dictionary = source.get_meta("temporary_crit_die_bonuses", {})
	crit_die += int(bonuses.get("amount", 0))
	return max(crit_die, 0)

func getActionPoints(source: CreatureData) -> int:
	if source == null:
		return 0

	var attribute := _get_attribute(source, "Dexterity")
	var action_points := _evaluate_attribute_bonus(attribute, "Action Points")
	action_points -= source.fatigue
	var bonuses: Dictionary = source.get_meta("temporary_action_point_bonuses", {})
	action_points += int(bonuses.get("amount", 0))
	return max(action_points, 0)

func getMaxHealth(source: CreatureData) -> int:
	if source == null:
		return 1
	var attribute := _get_attribute(source, "Constitution")
	if attribute == null:
		return max(source.maxHP, 1)
	var health_per_level := _evaluate_attribute_bonus(attribute, "Health")
	var max_health = (health_per_level * max(source.level, 1)) - source.necroticDamage
	return max(max_health, 1)

func getMaxVitality(source: CreatureData) -> int:
	if source == null:
		return 1
	var attribute := _get_attribute(source, "Constitution")
	if attribute == null:
		return max(source.maxVitality, 1)
	var vitality_multiplier := _evaluate_attribute_bonus(attribute, "Vitality")
	var max_vitality := (vitality_multiplier * getMaxHealth(source)) + source.necroticDamage
	return max(max_vitality, 1)

func normalizeVitals(source: CreatureData, refill_if_uninitialized: bool = false) -> void:
	if source == null:
		return
	var previous_max_hp := source.maxHP
	var previous_max_vitality := source.maxVitality
	source.maxHP = getMaxHealth(source)
	source.maxVitality = getMaxVitality(source)
	if refill_if_uninitialized and (source.currentHP <= 0 or previous_max_hp <= 1):
		source.currentHP = source.maxHP
	else:
		source.currentHP = clampi(source.currentHP, 0, source.maxHP)
	if refill_if_uninitialized and (source.currentVitality <= 0 or previous_max_vitality <= 1):
		source.currentVitality = source.maxVitality
	else:
		source.currentVitality = clampi(source.currentVitality, 0, source.maxVitality)
	source.temporaryHealth = maxi(source.temporaryHealth, 0)

func healHealth(target: CreatureData, amount: int) -> Dictionary:
	if target == null:
		return {"success": false, "reason": "null_target"}
	if target.currentVitality <= 0:
		return {"success": false, "reason": "target_dead"}
	var healed_amount := maxi(amount, 0)
	var previous_hp := target.currentHP
	target.currentHP = clampi(target.currentHP + healed_amount, 0, target.maxHP)
	return {
		"success": true,
		"target_name": target._name,
		"healed_amount": target.currentHP - previous_hp,
		"remaining_hp": target.currentHP,
		"remaining_vitality": target.currentVitality,
		"is_unconscious": target.currentHP <= 0 and target.currentVitality > 0,
		"is_dead": target.currentVitality <= 0,
	}

func getActionAPCost(action: Action, weapon: Weapon = null) -> int:
	if action == null:
		return 0
	if action.is_attack_action():
		if weapon != null:
			return max(weapon.base_ap_cost, 0)
		return 0
	return max(action.ap_cost, 0)

func getActionSpeed(action: Action, weapon: Weapon = null) -> int:
	if action == null:
		return 0
	if action.is_attack_action() and weapon != null:
		return maxi(int(round(float(action.base_speed) * weapon.get_speed_multiplier())), 0)
	return max(action.base_speed, 0)

func getDefenceValue(target: CreatureData, defence_name: String) -> int:
	if target == null:
		return 0

	var defence_template: Defence = null
	for defence: Defence in target.defences:
		if defence != null and defence._name == defence_name:
			defence_template = defence
			break

	if defence_template == null and CampaignVariables.codex != null:
		defence_template = CampaignVariables.codex.Defences.get(defence_name, null)

	if defence_template == null:
		return 0

	var defence_value := (defence_template.duplicate(true) as Defence).getValue(target)
	var bonuses: Dictionary = target.get_meta("temporary_defence_bonuses", {})
	defence_value += int((bonuses.get(defence_name, {}) as Dictionary).get("amount", 0))
	return defence_value

func _get_equipped_item_at_location(target: CreatureData, target_location: Item.ItemSlots) -> Item:
	if not (target is HumanoidData):
		return null

	var equipment: Equipment = (target as HumanoidData).equipment
	if equipment == null:
		return null

	match target_location:
		Item.ItemSlots.Head:
			return equipment.head
		Item.ItemSlots.RightArm:
			return equipment.rightArm
		Item.ItemSlots.LeftArm:
			return equipment.leftArm
		Item.ItemSlots.Torso:
			return equipment.torso
		Item.ItemSlots.RightLeg:
			return equipment.rightLeg
		Item.ItemSlots.LeftLeg:
			return equipment.leftLeg
	return null

func getLocationDamageThreshold(target: CreatureData, target_location: Item.ItemSlots, damage_profile: DamageProfile = null) -> int:
	if target == null or damage_profile == null or damage_profile.ignore_dt:
		return 0

	var item := _get_equipped_item_at_location(target, target_location)
	if not (item is Armor):
		return 0

	var armor := item as Armor
	match damage_profile.origin:
		DamageProfile.DamageOrigin.MAGICAL:
			return armor.magicalDT
		DamageProfile.DamageOrigin.NECROTIC:
			return armor.necroticDT
		_:
			return armor.physicalDT

func _location_to_string(target_location: Item.ItemSlots) -> String:
	match target_location:
		Item.ItemSlots.Head:
			return "Head"
		Item.ItemSlots.RightArm:
			return "Right Arm"
		Item.ItemSlots.LeftArm:
			return "Left Arm"
		Item.ItemSlots.Torso:
			return "Torso"
		Item.ItemSlots.RightLeg:
			return "Right Leg"
		Item.ItemSlots.LeftLeg:
			return "Left Leg"
		_:
			return "Unknown"

func resolveAttack(target: CreatureData, source: CreatureData = null, damage_profile: DamageProfile = null, action: Action = null, context: Dictionary = {}) -> Dictionary:
	if target == null:
		push_error("resolveAttack called with null target.")
		return {"success": false, "reason": "null_target"}

	var profile := damage_profile
	if profile == null:
		profile = _default_damage_profile_from_source(source)

	if profile == null:
		push_error("resolveAttack could not determine a damage profile.")
		return {"success": false, "reason": "missing_damage_profile"}

	var defence_name := "Deflection"
	if action != null and not action.tested_defence.is_empty():
		defence_name = action.tested_defence
	defence_name = str(context.get("defence_name", defence_name))

	var target_location: Item.ItemSlots = Item.ItemSlots.Torso
	if action != null:
		target_location = action.default_target_location
	if context.has("target_location"):
		target_location = int(context.get("target_location", target_location)) as Item.ItemSlots

	var accuracy := getAccuracy(source, action) + int(context.get("accuracy_bonus", 0))
	var hit_roll := rollDice(1, DiceType.D20)
	var to_hit_total := hit_roll + accuracy
	var defence_value := getDefenceValue(target, defence_name)
	var did_hit := to_hit_total >= defence_value
	var crit_die := getCritDie(source, action)

	var damage_roll := 0
	var crit_roll := 0
	var did_crit := false
	var raw_damage := 0
	var location_dt := 0
	var final_damage := 0
	var absorbed_by_temporary_health := 0
	var health_damage := 0
	var vitality_damage := 0

	if did_hit:
		if profile.damage_die > 0:
			damage_roll = rollDice(1, profile.damage_die)
		if profile.damage_die > 0 and damage_roll >= profile.damage_die and crit_die > 0:
			did_crit = true
			crit_roll = rollDice(1, crit_die)
		raw_damage = max(profile.base_damage + damage_roll + crit_roll + int(context.get("damage_bonus", 0)), 0)
		location_dt = getLocationDamageThreshold(target, target_location, profile)
		final_damage = max(raw_damage - location_dt, 0)
		absorbed_by_temporary_health = mini(target.temporaryHealth, final_damage)
		target.temporaryHealth = maxi(target.temporaryHealth - absorbed_by_temporary_health, 0)
		health_damage = maxi(final_damage - absorbed_by_temporary_health, 0)
		vitality_damage = health_damage
		target.currentHP = maxi(target.currentHP - health_damage, 0)
		target.currentVitality = maxi(target.currentVitality - vitality_damage, 0)

	var result := {
		"success": true,
		"target_name": target._name,
		"source_name": source._name if source != null else "",
		"action_name": action._name if action != null else "",
		"defence_name": defence_name,
		"defence_value": defence_value,
		"target_location": int(target_location),
		"target_location_name": _location_to_string(target_location),
		"accuracy": accuracy,
		"crit_die": crit_die,
		"hit_roll": hit_roll,
		"to_hit_total": to_hit_total,
		"hit": did_hit,
		"damage_roll": damage_roll,
		"crit_roll": crit_roll,
		"did_crit": did_crit,
		"raw_damage": raw_damage,
		"location_dt": location_dt,
		"absorbed_by_temporary_health": absorbed_by_temporary_health,
		"health_damage": health_damage,
		"vitality_damage": vitality_damage,
		"total_damage": final_damage,
		"remaining_hp": target.currentHP,
		"remaining_vitality": target.currentVitality,
		"remaining_temporary_health": target.temporaryHealth,
		"is_unconscious": target.currentHP <= 0 and target.currentVitality > 0,
		"is_dead": target.currentVitality <= 0,
	}

	if did_hit:
		print("%s hit %s in the %s for %s damage (%s DT)" % [result["source_name"], target._name, result["target_location_name"], final_damage, location_dt])
	else:
		print("%s missed %s (%s vs %s %s)" % [result["source_name"], target._name, to_hit_total, defence_name, defence_value])

	return result

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
	return resolveAttack(target, source, damage_profile)
	
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
