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


func evaluate_player_expression(command: String, explicit_context: Dictionary = {}, resolving: Array[String] = []) -> Variant:
	if command.is_empty():
		return 0
	var context := _build_player_expression_context(explicit_context, resolving)
	var variable_names: Array = []
	var variable_values: Array = []
	for key: String in context.keys():
		variable_names.append(key)
		variable_values.append(context[key])
	return evaluate(command, variable_names, variable_values)


func resolve_player_variable(variable_name: String, explicit_context: Dictionary = {}, resolving: Array[String] = []) -> Variant:
	if explicit_context.has(variable_name):
		return explicit_context[variable_name]
	if CampaignVariables == null or CampaignVariables.codex == null:
		return 0
	var entry := CampaignVariables.codex.get_player_data_blueprint(variable_name)
	if entry == null or not entry.enabled:
		return 0
	return _resolve_blueprint_entry(entry, explicit_context, resolving)


func resolve_modifier_value(modifier_id: int, explicit_context: Dictionary = {}, resolving: Array[String] = []) -> Variant:
	if modifier_id < 0:
		return 0
	var runtime_total := 0.0
	if PlayerVariables != null:
		runtime_total = PlayerVariables.getModifierTotal(modifier_id)
		if PlayerVariables.hasModifierBucket(modifier_id):
			return runtime_total
	var source := _find_modifier_source(modifier_id)
	if source.is_empty():
		return runtime_total
	var attribute := PlayerVariables.getAttributeById(int(source.get("attribute_id", -1)))
	if attribute == null:
		return runtime_total
	var local_context := explicit_context.duplicate(true)
	local_context["x"] = attribute.value
	return evaluate_player_expression(str(source.get("expression", "")), local_context, resolving)

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


func _build_player_expression_context(explicit_context: Dictionary, resolving: Array[String]) -> Dictionary:
	var context := explicit_context.duplicate(true)
	if CampaignVariables == null or CampaignVariables.codex == null:
		return context
	var blueprint_entries: Array[PlayerDataBlueprintEntry] = []
	for entry: PlayerDataBlueprintEntry in CampaignVariables.codex.PlayerDataBlueprint.values():
		if entry != null and entry.enabled:
			blueprint_entries.append(entry)
	blueprint_entries.sort_custom(func(a: PlayerDataBlueprintEntry, b: PlayerDataBlueprintEntry) -> bool:
		return a.sort_order < b.sort_order
	)
	for entry in blueprint_entries:
		if not context.has(entry._name):
			context[entry._name] = _resolve_blueprint_entry(entry, context, resolving)
	return context


func _resolve_blueprint_entry(entry: PlayerDataBlueprintEntry, explicit_context: Dictionary, resolving: Array[String]) -> Variant:
	if entry == null:
		return 0
	if explicit_context.has(entry._name):
		return explicit_context[entry._name]
	if resolving.has(entry._name):
		push_error("Circular player variable dependency: %s" % " -> ".join(resolving + [entry._name]))
		return 0
	var next_resolving := resolving.duplicate()
	next_resolving.append(entry._name)
	match entry.source_type:
		PlayerDataBlueprintEntry.SourceType.ATTRIBUTE:
			var attribute := PlayerVariables.getAttributeById(entry.source_id)
			return attribute.value if attribute != null else 0
		PlayerDataBlueprintEntry.SourceType.MODIFIER:
			return resolve_modifier_value(entry.source_id, explicit_context, next_resolving)
		PlayerDataBlueprintEntry.SourceType.PLAYER_FIELD:
			return PlayerVariables.getDataField(entry.source_key if not entry.source_key.is_empty() else _variable_to_field_name(entry._name), 0)
		PlayerDataBlueprintEntry.SourceType.PLAYER_METHOD:
			if PlayerVariables != null and PlayerVariables.has_method(entry.source_key):
				return PlayerVariables.call(entry.source_key)
			return 0
		PlayerDataBlueprintEntry.SourceType.DERIVED_EXPRESSION:
			return evaluate_player_expression(entry.expression, explicit_context, next_resolving)
		_:
			return 0


func _find_modifier_source(modifier_id: int) -> Dictionary:
	if CampaignVariables == null or CampaignVariables.codex == null:
		return {}
	for template_attribute: Attribute in CampaignVariables.codex.Attributes.values():
		if template_attribute == null:
			continue
		if template_attribute.modifier_1 != null and template_attribute.modifier_1.id == modifier_id:
			return {
				"attribute_id": template_attribute.id,
				"expression": template_attribute.modifier_1_expression,
			}
		if template_attribute.modifier_2 != null and template_attribute.modifier_2.id == modifier_id:
			return {
				"attribute_id": template_attribute.id,
				"expression": template_attribute.modifier_2_expression,
			}
	return {}


func _variable_to_field_name(variable_name: String) -> String:
	var parts := variable_name.split("_", false)
	if parts.is_empty():
		return variable_name
	var field_name := parts[0]
	for i in range(1, parts.size()):
		var part := parts[i]
		if part.is_empty():
			continue
		field_name += part.substr(0, 1).to_upper() + part.substr(1)
	return field_name


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
	var condition: Condition = CampaignVariables.codex.get_by_name(CampaignVariables.codex.Conditions, condition_name)
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
