extends Node

enum DiceType { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20 }

const UNIVERSAL_RANGED_MAX_DISTANCE := 12
const RANGED_ADJACENT_ACCURACY_PENALTY := -4
const RANGED_OPTIMAL_ACCURACY_BONUS := 2
const RANGED_BEYOND_MAX_ACCURACY_PENALTY := -4
const TARGET_LOCATION_MODE_RANDOM := "random"
const TARGET_LOCATION_MODE_CALLED := "called"
const EQUIP_LOAD_LIGHT_RATIO := 0.10
const EQUIP_LOAD_MEDIUM_RATIO := 0.20
const EQUIP_LOAD_HEAVY_RATIO := 0.30

func getCarryWeight(source: CreatureData) -> float:
	if source == null:
		return 0.0
	var attribute: Attribute = source._get_attribute("Might")
	return maxf(float(source._evaluate_attribute_bonus(attribute, "Carry Weight")), 0.0)

func getEquippedItems(source: CreatureData) -> Array[Item]:
	var equipped_items: Array[Item] = []
	if source == null or not (source is HumanoidData):
		return equipped_items

	var equipment: Equipment = (source as HumanoidData).equipment
	if equipment == null:
		return equipped_items

	var counted_multislot_clothing: Dictionary[int, bool] = {}
	for armor_piece: Item in [equipment.head, equipment.torso, equipment.leftArm, equipment.rightArm, equipment.leftLeg, equipment.rightLeg]:
		if armor_piece == null or armor_piece._name.is_empty():
			continue
		if armor_piece is Clothing and armor_piece.allowed_slots.size() > 1:
			var clothing_id: int = armor_piece.get_instance_id()
			if counted_multislot_clothing.has(clothing_id):
				continue
			counted_multislot_clothing[clothing_id] = true
		equipped_items.append(armor_piece)

	var primary_left: Weapon = equipment.weapon1Left
	var primary_right: Weapon = equipment.weapon1Right
	if primary_left != null and primary_left._name != "":
		equipped_items.append(primary_left)
	if primary_right != null and primary_right._name != "" and primary_right != primary_left:
		equipped_items.append(primary_right)

	var secondary_left: Weapon = equipment.weapon2Left
	var secondary_right: Weapon = equipment.weapon2Right
	if secondary_left != null and secondary_left._name != "":
		equipped_items.append(secondary_left)
	if secondary_right != null and secondary_right._name != "" and secondary_right != secondary_left:
		equipped_items.append(secondary_right)

	for quick_item: Item in [equipment.quickItem1, equipment.quickItem2, equipment.quickItem3, equipment.quickItem4]:
		if quick_item == null or quick_item._name.is_empty():
			continue
		equipped_items.append(quick_item)
	return equipped_items

func getEquipLoad(source: CreatureData) -> float:
	var equip_load := 0.0
	for equipped_item: Item in getEquippedItems(source):
		equip_load += equipped_item.weight
	return equip_load

func getMaxEquipLoad(source: CreatureData) -> float:
	return getCarryWeight(source) * EQUIP_LOAD_HEAVY_RATIO

func getEquipLoadTier(source: CreatureData) -> String:
	if source == null:
		return "Overloaded"

	var carry_weight := getCarryWeight(source)
	var equip_load := getEquipLoad(source)
	if carry_weight <= 0.0:
		return "Overloaded" if equip_load > 0.0 else "Heavy"

	var light_threshold := carry_weight * EQUIP_LOAD_LIGHT_RATIO
	var medium_threshold := carry_weight * EQUIP_LOAD_MEDIUM_RATIO
	var heavy_threshold := carry_weight * EQUIP_LOAD_HEAVY_RATIO

	if equip_load > heavy_threshold:
		return "Overloaded"
	if equip_load <= light_threshold:
		return "Light"
	if equip_load <= medium_threshold:
		return "Medium"
	return "Heavy"

func getEquipLoadDeflectionBonus(source: CreatureData) -> int:
	match getEquipLoadTier(source):
		"Light":
			return 3
		"Medium":
			return 2
		"Heavy":
			return 1
		_:
			return 0

func canEquipWithinLoadLimit(source: CreatureData) -> bool:
	return getEquipLoad(source) <= getMaxEquipLoad(source)

func getSkillValue(source: CreatureData, skill_name: String) -> int:
	if source == null or not (source is HumanoidData):
		return 0

	for skill: Skill in (source as HumanoidData).skills:
		if skill != null and skill._name == skill_name:
			return skill.value
	return 0

func getAccuracy(source: CreatureData, _action: Action = null) -> int:
	if source == null:
		return 0

	var attribute_name := "Perception"

	var attribute := source._get_attribute(attribute_name)
	var accuracy := source._evaluate_attribute_bonus(attribute, "Accuracy")
	var bonuses: Dictionary = source.get_meta("temporary_accuracy_bonuses", {})
	accuracy += int(bonuses.get("amount", 0))
	return accuracy

func getPotency(source: CreatureData) -> int:
	if source == null:
		return 0
	var attribute := source._get_attribute("Intelligence")
	var potency := source._evaluate_attribute_bonus(attribute, "Potency")
	var bonuses: Dictionary = source.get_meta("temporary_potency_bonuses", {})
	potency += int(bonuses.get("amount", 0))
	return potency

func getCritDie(source: CreatureData, _action: Action = null) -> int:
	if source == null:
		return 0

	var attribute := source._get_attribute("Perception")
	var crit_die := source._evaluate_attribute_bonus(attribute, "Crit Dice")
	var bonuses: Dictionary = source.get_meta("temporary_crit_die_bonuses", {})
	crit_die += int(bonuses.get("amount", 0))
	return max(crit_die, 0)

func getActionPoints(source: CreatureData) -> int:
	if source == null:
		return 0
	return source.getActionPoints()

func getMaxHealth(source: CreatureData) -> float:
	if source == null:
		return 1.0
	return source.getMaxHealth()

func getMaxVitality(source: CreatureData) -> float:
	if source == null:
		return 1.0
	return source.getMaxVitality()

func getMaxConcentration(source: CreatureData) -> int:
	if source == null:
		return 0
	return source.getMaxConcentration()

func getCurrentConcentration(source: CreatureData) -> int:
	if source == null:
		return 0
	return source.currentConcentration

func getManaGeneration(source: CreatureData) -> int:
	if source == null:
		return 0
	var attribute: Attribute = source._get_attribute("Resolve")
	if attribute == null:
		return 0
	return maxi(source._evaluate_attribute_bonus(attribute, "Mana Generation"), 0)

func getCurrentMana(source: CreatureData) -> int:
	if source == null:
		return 0
	return maxi(source.currentMana, 0)

func generateMana(source: CreatureData) -> int:
	if source == null:
		return 0
	source.currentMana = maxi(source.currentMana + getManaGeneration(source), 0)
	return source.currentMana

func clearMana(source: CreatureData) -> int:
	if source == null:
		return 0
	source.currentMana = 0
	return source.currentMana

func restoreConcentration(source: CreatureData) -> int:
	if source == null:
		return 0
	source.maxConcentration = source.getMaxConcentration()
	source.currentConcentration = source.maxConcentration
	return source.currentConcentration

func isUnconscious(target: CreatureData) -> bool:
	return target != null and target.currentHP <= 0.0 and target.currentVitality > 0.0

func isDead(target: CreatureData) -> bool:
	return target != null and target.currentVitality <= 0.0

func canAct(target: CreatureData) -> bool:
	return target != null and not isUnconscious(target) and not isDead(target)

func addCondition(target: CreatureData, condition_name: String) -> bool:
	if target == null or condition_name.is_empty() or target.hasCondition(condition_name):
		return false
	var condition: Condition = null
	if CampaignVariables.codex != null:
		condition = CampaignVariables.codex.Conditions.get(condition_name, null)
	if condition != null:
		return target.addCondition(condition.duplicate(true) as Condition)
	return target.addCondition(Condition.new(condition_name))

func removeCondition(target: CreatureData, condition_name: String) -> bool:
	if target == null:
		return false
	return target.removeCondition(condition_name)

func getConditionDefenceName(condition_name: String) -> String:
	match condition_name:
		"Bleed":
			return "Endurance"
		"Prone":
			return "Reflex"
		"Stunned":
			return "Mind"
		_:
			return "Endurance"

func resolveConditionApplication(source: CreatureData, target: CreatureData, condition_name: String) -> Dictionary:
	if source == null:
		return {"success": false, "reason": "null_source"}
	if target == null:
		return {"success": false, "reason": "null_target"}
	var normalized_condition := condition_name.strip_edges()
	if normalized_condition.is_empty():
		return {"success": false, "reason": "missing_condition"}
	var defence_name := getConditionDefenceName(normalized_condition)
	var potency := getPotency(source)
	var roll := rollDice(1, DiceType.D20)
	var total := roll + potency
	var defence_value := getDefenceValue(target, defence_name)
	var applied := total >= defence_value and addCondition(target, normalized_condition)
	return {
		"success": true,
		"condition_name": normalized_condition,
		"condition_defence": defence_name,
		"condition_defence_value": defence_value,
		"potency": potency,
		"condition_roll": roll,
		"condition_total": total,
		"condition_applied": applied,
		"condition_already_present": target.hasCondition(normalized_condition) and not applied,
	}

func damageConcentration(target: CreatureData, amount: int = 1) -> Dictionary:
	if target == null:
		return {"success": false, "reason": "null_target"}
	var applied_amount := maxi(amount, 0)
	var previous_concentration := target.currentConcentration
	target.currentConcentration = maxi(target.currentConcentration - applied_amount, 0)
	var concentration_broken := previous_concentration > 0 and target.currentConcentration <= 0
	var previous_mana := getCurrentMana(target)
	if concentration_broken:
		clearMana(target)
	return {
		"success": true,
		"previous_concentration": previous_concentration,
		"remaining_concentration": target.currentConcentration,
		"concentration_broken": concentration_broken,
		"previous_mana": previous_mana,
		"remaining_mana": getCurrentMana(target),
	}

func normalizeVitals(source: CreatureData, refill_if_uninitialized: bool = false) -> void:
	if source == null:
		return
	source.normalizeVitals(refill_if_uninitialized)

func healHealth(target: CreatureData, amount: float, source: CreatureData = null) -> Dictionary:
	if target == null:
		return {"success": false, "reason": "null_target"}
	var healing_amount: float = maxf(amount, 0.0) * getDamageHealingMultiplier(source)
	var result := target.healHealth(healing_amount)
	if result is Dictionary:
		result["remaining_concentration"] = target.currentConcentration
		result["is_unconscious"] = isUnconscious(target)
		result["is_dead"] = isDead(target)
	return result

func performFirstAid(target: CreatureData, source: CreatureData = null, amount: float = 5.0) -> Dictionary:
	if target == null:
		return {"success": false, "reason": "null_target"}
	if isDead(target):
		return {
			"success": false,
			"reason": "target_dead",
			"source_name": source._name if source != null else "",
			"target_name": target._name,
			"action_name": "First Aid",
		}
	var result := healHealth(target, amount, source)
	if result is Dictionary:
		result["source_name"] = source._name if source != null else ""
		result["action_name"] = "First Aid"
	return result

func restoreFromItem(resource: String, amount: float, target: CreatureData, source: CreatureData = null) -> Dictionary:
	if target == null:
		return {"success": false, "reason": "null_target"}
	var normalized_resource := resource.strip_edges().to_lower()
	var restore_amount := maxf(amount, 0.0)
	match normalized_resource:
		"hp", "health":
			var health_result := healHealth(target, restore_amount, source)
			if health_result is Dictionary:
				health_result["resource"] = "hp"
			return health_result
		"mana":
			var previous_mana := getCurrentMana(target)
			target.currentMana = maxi(target.currentMana + int(round(restore_amount)), 0)
			return {
				"success": true,
				"resource": "mana",
				"target_name": target._name,
				"source_name": source._name if source != null else "",
				"restored_amount": target.currentMana - previous_mana,
				"remaining_mana": target.currentMana,
			}
		_:
			return {
				"success": false,
				"reason": "unsupported_resource",
				"resource": normalized_resource,
				"target_name": target._name,
			}

func RestoreFromItem(resource: String, amount: float, target: CreatureData, source: CreatureData = null) -> Dictionary:
	return restoreFromItem(resource, amount, target, source)

func _get_quick_item_from_equipment(equipment: Equipment, slot_index: int) -> Item:
	if equipment == null:
		return null
	match slot_index:
		0:
			return equipment.quickItem1
		1:
			return equipment.quickItem2
		2:
			return equipment.quickItem3
		3:
			return equipment.quickItem4
		_:
			return null

func _set_quick_item_in_equipment(equipment: Equipment, slot_index: int, item: Item) -> void:
	if equipment == null:
		return
	match slot_index:
		0:
			equipment.quickItem1 = item
		1:
			equipment.quickItem2 = item
		2:
			equipment.quickItem3 = item
		3:
			equipment.quickItem4 = item

func useQuickItem(source: CreatureData, context: Dictionary = {}) -> Dictionary:
	if source == null:
		return {"success": false, "reason": "null_source", "action_name": "Use Quick Item"}
	if not (source is HumanoidData):
		return {"success": false, "reason": "invalid_source", "action_name": "Use Quick Item", "source_name": source._name}
	var humanoid_source := source as HumanoidData
	if humanoid_source.equipment == null:
		return {"success": false, "reason": "missing_equipment", "action_name": "Use Quick Item", "source_name": source._name}
	var slot_index := int(context.get("quick_slot_index", -1))
	var quick_item := _get_quick_item_from_equipment(humanoid_source.equipment, slot_index)
	if quick_item == null or quick_item._name.is_empty():
		return {
			"success": false,
			"reason": "empty_quick_slot",
			"action_name": "Use Quick Item",
			"source_name": source._name,
			"quick_slot_index": slot_index,
		}
	if quick_item is Utility:
		var use_result = (quick_item as Utility).use(source, source, context)
		if use_result is Dictionary:
			use_result["source_name"] = source._name
			use_result["target_name"] = source._name
			use_result["action_name"] = "Use Quick Item"
			use_result["quick_item_name"] = quick_item._name
			use_result["quick_slot_index"] = slot_index
			if bool(use_result.get("success", false)):
				_set_quick_item_in_equipment(humanoid_source.equipment, slot_index, null)
			return use_result
	return {
		"success": false,
		"reason": "unsupported_utility",
		"action_name": "Use Quick Item",
		"source_name": source._name,
		"target_name": source._name,
		"quick_item_name": quick_item._name,
		"quick_slot_index": slot_index,
	}

func getDamageHealingPercent(source: CreatureData) -> float:
	if source == null:
		return 0.0
	var attribute: Attribute = source._get_attribute("Might")
	return float(source._evaluate_attribute_bonus(attribute, "Damage & Healing:"))

func getDamageHealingMultiplier(source: CreatureData) -> float:
	return 1.0 + (getDamageHealingPercent(source) / 100.0)

func getActionAPCost(action: Action, weapon: Weapon = null) -> int:
	if action == null:
		return 0
	if action.is_attack_action():
		var weapon_ap_cost := weapon.base_ap_cost if weapon != null else 0
		return maxi(weapon_ap_cost + action.ap_cost, 1)
	var base_cost := maxi(action.ap_cost, 0)
	if action._name == "Wait":
		return base_cost
	return maxi(base_cost, 1)

func getWeaponBaseSpeed(weapon: Weapon = null) -> int:
	if weapon == null:
		return 25
	match weapon.speed_category:
		Weapon.WeaponSpeedCategory.VERY_FAST:
			return 15
		Weapon.WeaponSpeedCategory.FAST:
			return 20
		Weapon.WeaponSpeedCategory.SLOW:
			return 30
		_:
			return 25

func getActionSpeed(action: Action, weapon: Weapon = null) -> int:
	if action == null:
		return 0
	if action.is_attack_action():
		var weapon_base_speed := getWeaponBaseSpeed(weapon)
		var speed_percent := float(action.base_speed) / 100.0
		return maxi(int(round(weapon_base_speed * speed_percent)), 1)
	return maxi(action.base_speed, 1)

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
	if defence_name == "Deflection":
		defence_value += getEquipLoadDeflectionBonus(target)
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

	var temporary_dt_bonuses: Dictionary = target.get_meta("temporary_dt_bonuses", {})
	var item := _get_equipped_item_at_location(target, target_location)
	if not (item is Armor):
		match damage_profile.origin:
			DamageProfile.DamageOrigin.MAGICAL:
				return int((temporary_dt_bonuses.get("magical", {}) as Dictionary).get("amount", 0))
			DamageProfile.DamageOrigin.NECROTIC:
				return int((temporary_dt_bonuses.get("necrotic", {}) as Dictionary).get("amount", 0))
			_:
				return int((temporary_dt_bonuses.get("physical", {}) as Dictionary).get("amount", 0))

	var armor := item as Armor
	match damage_profile.origin:
		DamageProfile.DamageOrigin.MAGICAL:
			return armor.magicalDT + int((temporary_dt_bonuses.get("magical", {}) as Dictionary).get("amount", 0))
		DamageProfile.DamageOrigin.NECROTIC:
			return armor.necroticDT + int((temporary_dt_bonuses.get("necrotic", {}) as Dictionary).get("amount", 0))
		_:
			return armor.physicalDT + int((temporary_dt_bonuses.get("physical", {}) as Dictionary).get("amount", 0))

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

func get_grid_attack_distance(source_cell: Vector2i, target_cell: Vector2i) -> int:
	var x_delta: int = absi(source_cell.x - target_cell.x)
	var y_delta: int = absi(source_cell.y - target_cell.y)
	return maxi(x_delta, y_delta)

func evaluate_weapon_range(weapon: Weapon, grid_distance: int, source_engaged: bool = false) -> Dictionary:
	var normalized_distance: int = maxi(grid_distance, 0)
	if weapon == null or weapon.weaponRange == Weapon.WeaponRange.MELEE:
		return {
			"legal": normalized_distance == 1,
			"accuracy_modifier": 0,
			"range_state": "melee" if normalized_distance == 1 else "out_of_melee",
			"engaged_penalty": false,
			"optimal_bonus": false,
			"distance": normalized_distance,
		}

	var accuracy_modifier: int = 0
	var engaged_penalty: bool = false
	var optimal_bonus: bool = false
	var range_state: String = "standard"

	if source_engaged:
		accuracy_modifier += RANGED_ADJACENT_ACCURACY_PENALTY
		engaged_penalty = true
		range_state = "engaged_penalty"

	var optimal_range: Vector2i = _get_optimal_range_band(weapon.weaponRange)
	if normalized_distance >= optimal_range.x and normalized_distance <= optimal_range.y:
		accuracy_modifier += RANGED_OPTIMAL_ACCURACY_BONUS
		optimal_bonus = true
		range_state = "optimal"
	elif normalized_distance > UNIVERSAL_RANGED_MAX_DISTANCE:
		accuracy_modifier += RANGED_BEYOND_MAX_ACCURACY_PENALTY
		range_state = "beyond_max_penalty"
	elif normalized_distance <= 1:
		range_state = "adjacent"

	return {
		"legal": true,
		"accuracy_modifier": accuracy_modifier,
		"range_state": range_state,
		"engaged_penalty": engaged_penalty,
		"optimal_bonus": optimal_bonus,
		"distance": normalized_distance,
	}

func _get_optimal_range_band(weapon_range: Weapon.WeaponRange) -> Vector2i:
	match weapon_range:
		Weapon.WeaponRange.CLOSE:
			return Vector2i(2, 5)
		Weapon.WeaponRange.MEDIUM:
			return Vector2i(6, 9)
		Weapon.WeaponRange.LONG:
			return Vector2i(10, 12)
		_:
			return Vector2i(1, 1)

func roll_random_target_location() -> Item.ItemSlots:
	var roll: int = rollDice(1, 100)
	if roll <= 10:
		return Item.ItemSlots.Head
	if roll <= 25:
		return Item.ItemSlots.RightArm
	if roll <= 40:
		return Item.ItemSlots.LeftArm
	if roll <= 70:
		return Item.ItemSlots.Torso
	if roll <= 85:
		return Item.ItemSlots.RightLeg
	return Item.ItemSlots.LeftLeg

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
	defence_name = str(context.get("defence_name", defence_name))

	var target_location: Item.ItemSlots = Item.ItemSlots.Torso
	if context.has("target_location"):
		target_location = int(context.get("target_location", target_location)) as Item.ItemSlots
	var targeting_mode: String = str(context.get("targeting_mode", "single"))
	var target_location_mode: String = str(context.get("target_location_mode", TARGET_LOCATION_MODE_RANDOM))
	if targeting_mode != "single":
		target_location = Item.ItemSlots.Torso
	elif target_location_mode == TARGET_LOCATION_MODE_RANDOM:
		target_location = roll_random_target_location()

	var weapon: Weapon = null
	if context.get("weapon", null) is Weapon:
		weapon = context.get("weapon", null)
	var grid_distance: int = int(context.get("grid_distance", 1))
	var source_engaged: bool = bool(context.get("source_engaged", false))
	var range_evaluation: Dictionary = evaluate_weapon_range(weapon, grid_distance, source_engaged)
	if not bool(range_evaluation.get("legal", true)):
		return {
			"success": false,
			"reason": "out_of_range",
			"target_name": target._name,
			"source_name": source._name if source != null else "",
			"action_name": action._name if action != null else "",
			"distance": grid_distance,
			"range_state": str(range_evaluation.get("range_state", "invalid")),
		}

	var range_accuracy_modifier: int = int(range_evaluation.get("accuracy_modifier", 0))
	var attack_mana_cost := 0
	if action is Attack:
		attack_mana_cost = maxi((action as Attack).mana_cost, 0)
	if attack_mana_cost > 0 and getCurrentMana(source) < attack_mana_cost:
		return {
			"success": false,
			"reason": "insufficient_mana",
			"target_name": target._name,
			"source_name": source._name if source != null else "",
			"action_name": action._name if action != null else "",
			"mana_cost": attack_mana_cost,
			"remaining_mana": getCurrentMana(source),
		}
	if attack_mana_cost > 0:
		source.currentMana = maxi(source.currentMana - attack_mana_cost, 0)
	var accuracy := getAccuracy(source, action) + int(context.get("accuracy_bonus", 0)) + range_accuracy_modifier
	var hit_roll := rollDice(1, DiceType.D20)
	var to_hit_total := hit_roll + accuracy
	var defence_value := getDefenceValue(target, defence_name)
	var did_hit := to_hit_total >= defence_value
	var crit_die := getCritDie(source, action)
	var forced_outcome := str(context.get("forced_outcome", ""))
	if forced_outcome == "miss":
		did_hit = false
		to_hit_total = defence_value - 1
	elif forced_outcome == "hit":
		did_hit = true
		to_hit_total = maxi(to_hit_total, defence_value)
	elif forced_outcome == "crit":
		did_hit = true
		to_hit_total = maxi(to_hit_total, defence_value)
	var concentration_result := {
		"success": false,
		"remaining_concentration": getCurrentConcentration(target),
		"concentration_broken": false,
	}
	var condition_result := {
		"success": false,
		"condition_name": "",
		"condition_applied": false,
	}

	var damage_roll: float = 0.0
	var crit_roll: float = 0.0
	var did_crit := false
	var raw_damage: float = 0.0
	var location_dt: float = 0.0
	var final_damage: float = 0.0
	var absorbed_by_temporary_health: float = 0.0
	var health_damage: float = 0.0
	var vitality_damage: float = 0.0

	if did_hit:
		if profile.damage_die > 0:
			damage_roll = float(rollDice(1, profile.damage_die))
		if profile.damage_die > 0 and damage_roll >= profile.damage_die and crit_die > 0:
			did_crit = true
			crit_roll = float(rollDice(1, crit_die))
		if forced_outcome == "crit":
			did_crit = crit_die > 0
			if did_crit and crit_roll <= 0.0:
				crit_roll = float(rollDice(1, crit_die))
		var damage_bonus: float = float(context.get("damage_bonus", 0))
		var might_multiplier: float = getDamageHealingMultiplier(source)
		var attack_power_multiplier: float = 1.0
		if action is Attack:
			attack_power_multiplier = maxf(float((action as Attack).attack_power) / 100.0, 0.0)
		raw_damage = maxf((float(profile.base_damage) + damage_roll + crit_roll + damage_bonus) * might_multiplier * attack_power_multiplier, 0.0)
		location_dt = float(getLocationDamageThreshold(target, target_location, profile))
		final_damage = maxf(raw_damage - location_dt, 0.0)
		absorbed_by_temporary_health = minf(target.temporaryHealth, final_damage)
		target.temporaryHealth = maxf(target.temporaryHealth - absorbed_by_temporary_health, 0.0)
		health_damage = maxf(final_damage - absorbed_by_temporary_health, 0.0)
		vitality_damage = health_damage
		target.currentHP = maxf(target.currentHP - health_damage, 0.0)
		target.currentVitality = maxf(target.currentVitality - vitality_damage, 0.0)
		if final_damage > 0.0:
			concentration_result = damageConcentration(target, 1)
			if action is Attack:
				var attack_condition := (action as Attack).condition.strip_edges()
				if not attack_condition.is_empty():
					condition_result = resolveConditionApplication(source, target, attack_condition)

	var result := {
		"success": true,
		"target_name": target._name,
		"source_name": source._name if source != null else "",
		"action_name": action._name if action != null else "",
		"mana_cost": attack_mana_cost,
		"remaining_source_mana": getCurrentMana(source),
		"defence_name": defence_name,
		"defence_value": defence_value,
		"distance": grid_distance,
		"range_state": str(range_evaluation.get("range_state", "standard")),
		"range_accuracy_modifier": range_accuracy_modifier,
		"target_location": int(target_location),
		"target_location_name": _location_to_string(target_location),
		"accuracy": accuracy,
		"forced_outcome": forced_outcome,
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
		"remaining_concentration": concentration_result.get("remaining_concentration", getCurrentConcentration(target)),
		"remaining_mana": concentration_result.get("remaining_mana", getCurrentMana(target)),
		"concentration_broken": concentration_result.get("concentration_broken", false),
		"condition_name": condition_result.get("condition_name", ""),
		"condition_defence": condition_result.get("condition_defence", ""),
		"condition_defence_value": condition_result.get("condition_defence_value", 0),
		"potency": condition_result.get("potency", 0),
		"condition_roll": condition_result.get("condition_roll", 0),
		"condition_total": condition_result.get("condition_total", 0),
		"condition_applied": condition_result.get("condition_applied", false),
		"condition_already_present": condition_result.get("condition_already_present", false),
		"remaining_hp": target.currentHP,
		"remaining_vitality": target.currentVitality,
		"remaining_temporary_health": target.temporaryHealth,
		"remaining_conditions": target.conditions.duplicate(true),
		"is_unconscious": isUnconscious(target),
		"is_dead": isDead(target),
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

func resolveSkillCheck(source: CreatureData, skill_name: String, difficulty: int, context: Dictionary = {}) -> Dictionary:
	if source == null:
		return {"success": false, "reason": "null_source"}

	var normalized_skill_name := skill_name.strip_edges()
	if normalized_skill_name.is_empty():
		return {"success": false, "reason": "missing_skill"}

	var skill_value := getSkillValue(source, normalized_skill_name)
	var roll := rollDice(1, DiceType.D20)
	var total := roll + skill_value + int(context.get("modifier", 0))
	var normalized_difficulty := maxi(difficulty, 0)
	var passed := total >= normalized_difficulty
	var source_name := str(context.get("source_name", source._name))
	var text := "%s rolled %s vs DC %s: %s + %s = %s, %s" % [
		source_name,
		normalized_skill_name,
		normalized_difficulty,
		roll,
		skill_value,
		total,
		"Success" if passed else "Failure"
	]
	var tooltip := "d20 (%s) + %s (%s) = %s vs DC %s" % [roll, normalized_skill_name, skill_value, total, normalized_difficulty]

	return {
		"success": true,
		"action_name": "Perform Skill Test",
		"contested": false,
		"source_name": source_name,
		"target_name": str(context.get("target_name", source_name)),
		"skill_test_description": str(context.get("skill_test_description", "")),
		"skill_name": normalized_skill_name,
		"skill_value": skill_value,
		"difficulty": normalized_difficulty,
		"roll": roll,
		"modifier": int(context.get("modifier", 0)),
		"total": total,
		"passed": passed,
		"text": text,
		"tooltip": tooltip,
	}

func resolveContestedSkillCheck(source: CreatureData, target: CreatureData, skill_name: String, context: Dictionary = {}) -> Dictionary:
	if source == null:
		return {"success": false, "reason": "null_source"}
	if target == null:
		return {"success": false, "reason": "null_target"}
	var normalized_skill_name := skill_name.strip_edges()
	if normalized_skill_name.is_empty():
		return {"success": false, "reason": "missing_skill"}
	var source_skill_value := getSkillValue(source, normalized_skill_name)
	var target_skill_value := getSkillValue(target, normalized_skill_name)
	var source_roll := rollDice(1, DiceType.D20)
	var target_roll := rollDice(1, DiceType.D20)
	var source_total := source_roll + source_skill_value + int(context.get("modifier", 0))
	var target_total := target_roll + target_skill_value + int(context.get("target_modifier", 0))
	var passed := source_total >= target_total
	var source_name := str(context.get("source_name", source._name))
	var target_name := str(context.get("target_name", target._name))
	var description := str(context.get("skill_test_description", ""))
	var text := "%s contests %s with %s: %s (%s + %s) vs %s (%s + %s), %s" % [
		source_name,
		target_name,
		normalized_skill_name,
		source_total,
		source_roll,
		source_skill_value,
		target_total,
		target_roll,
		target_skill_value,
		"Success" if passed else "Failure"
	]
	var tooltip := "%s: d20 (%s) + %s (%s) = %s | %s: d20 (%s) + %s (%s) = %s" % [
		source_name,
		source_roll,
		normalized_skill_name,
		source_skill_value,
		source_total,
		target_name,
		target_roll,
		normalized_skill_name,
		target_skill_value,
		target_total,
	]
	return {
		"success": true,
		"action_name": "Perform Skill Test",
		"contested": true,
		"source_name": source_name,
		"target_name": target_name,
		"skill_test_description": description,
		"skill_name": normalized_skill_name,
		"source_roll": source_roll,
		"target_roll": target_roll,
		"source_skill_value": source_skill_value,
		"target_skill_value": target_skill_value,
		"source_total": source_total,
		"target_total": target_total,
		"modifier": int(context.get("modifier", 0)),
		"target_modifier": int(context.get("target_modifier", 0)),
		"passed": passed,
		"tie": source_total == target_total,
		"text": text,
		"tooltip": tooltip,
	}

func performSkillTest(source: CreatureData, target: CreatureData = null, context: Dictionary = {}) -> Dictionary:
	if source == null:
		return {"success": false, "reason": "null_source"}
	var skill_name := str(context.get("skill_name", "")).strip_edges()
	if skill_name.is_empty():
		return {"success": false, "reason": "missing_skill", "action_name": "Perform Skill Test", "source_name": source._name}
	var no_target := bool(context.get("no_target", false))
	if not no_target and target != null and target != source:
		return resolveContestedSkillCheck(source, target, skill_name, context)
	return resolveSkillCheck(source, skill_name, int(context.get("skill_difficulty", 0)), context)

func rollDice(num: int, sides: int) -> int:
	var rng := RandomNumberGenerator.new()
	var total := 0
	for i in num:
		var res := rng.randi_range(1, sides)
		total += res
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

func addAllDefenceBonuses(target: CreatureData, amount: int, duration: String = "round") -> Dictionary:
	if target == null:
		push_error("addAllDefenceBonuses called with null target.")
		return {"success": false, "reason": "null_target"}
	var defence_names: Array[String] = ["Deflection", "Endurance", "Reflex", "Mind"]
	var applied_bonuses: Dictionary = {}
	for defence_name in defence_names:
		var bonus_result := addDefenceBonus(target, defence_name, amount, duration)
		applied_bonuses[defence_name] = int(bonus_result.get("total_bonus", amount))
	return {
		"success": true,
		"target_name": target._name,
		"defence_names": defence_names,
		"amount": amount,
		"duration": duration,
		"applied_bonuses": applied_bonuses,
	}

func hasUsedRoundLimitedAction(source: CreatureData, action_name: String) -> bool:
	if source == null or action_name.is_empty():
		return false
	var used_actions: Dictionary = source.get_meta("round_limited_actions", {})
	return bool(used_actions.get(action_name, false))

func markRoundLimitedActionUsed(source: CreatureData, action_name: String) -> void:
	if source == null or action_name.is_empty():
		return
	var used_actions: Dictionary = source.get_meta("round_limited_actions", {})
	used_actions[action_name] = true
	source.set_meta("round_limited_actions", used_actions)

func addDTBonus(target: CreatureData, dt_type: String, amount: int, duration: String = "round") -> Dictionary:
	if target == null:
		push_error("addDTBonus called with null target.")
		return {"success": false, "reason": "null_target"}
	var dt_bonuses: Dictionary = target.get_meta("temporary_dt_bonuses", {})
	var dt_state: Dictionary = dt_bonuses.get(dt_type, {"amount": 0, "duration": duration})
	dt_state["amount"] = int(dt_state.get("amount", 0)) + amount
	dt_state["duration"] = duration
	dt_bonuses[dt_type] = dt_state
	target.set_meta("temporary_dt_bonuses", dt_bonuses)
	return {
		"success": true,
		"target_name": target._name,
		"dt_type": dt_type,
		"amount": amount,
		"duration": duration,
		"total_bonus": dt_state["amount"],
	}

func addBraceBonuses(target: CreatureData, amount: int, duration: String = "round") -> Dictionary:
	if target == null:
		push_error("addBraceBonuses called with null target.")
		return {"success": false, "reason": "null_target"}
	var applied_bonuses := {
		"physical": int(addDTBonus(target, "physical", amount, duration).get("total_bonus", amount)),
		"magical": int(addDTBonus(target, "magical", amount, duration).get("total_bonus", amount)),
	}
	return {
		"success": true,
		"target_name": target._name,
		"amount": amount,
		"duration": duration,
		"applied_bonuses": applied_bonuses,
	}

func clearRoundBonuses(target: CreatureData) -> void:
	if target == null:
		return
	target.remove_meta("temporary_defence_bonuses")
	target.remove_meta("temporary_dt_bonuses")
	target.remove_meta("round_limited_actions")

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
