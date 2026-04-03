extends Node

const DB_PATH := "res://data/Codex2.db"
const OUTPUT_PATH := "res://data/baseRules.tres"
const ITEM_OUTPUT_ROOT := "res://data/Imported"

const ATTRIBUTE_SCRIPT := "res://content/codex/character_options/attribute.gd"
const BACKGROUND_SCRIPT := "res://content/codex/character_options/background.gd"
const CONDITION_SCRIPT := "res://content/codex/gameplay/condition.gd"
const CONSUMABLE_SCRIPT := "res://content/codex/items/consumable.gd"
const DAMAGE_ORIGIN_SCRIPT := "res://content/codex/gameplay/damage_origin.gd"
const DAMAGE_TYPE_SCRIPT := "res://content/codex/gameplay/damage_type.gd"
const DEFENCE_SCRIPT := "res://content/codex/character_options/defence.gd"
const EFFECT_SCRIPT := "res://content/codex/gameplay/effects.gd"
const HOMELAND_SCRIPT := "res://content/codex/character_options/homeland.gd"
const MODIFIER_SCRIPT := "res://content/codex/gameplay/modifier.gd"
const NPC_SCRIPT := "res://content/codex/NPC/NPC.gd"
const PERK_SCRIPT := "res://content/codex/character_options/perk.gd"
const PLAYER_DATA_BLUEPRINT_SCRIPT := "res://content/codex/system/player_data_blueprint_entry.gd"
const RACE_SCRIPT := "res://content/codex/character_options/race.gd"
const RANGE_SCRIPT := "res://content/codex/gameplay/range.gd"
const SKILL_SCRIPT := "res://content/codex/character_options/skill.gd"
const SPELL_SCRIPT := "res://content/codex/gameplay/spells.gd"
const SPELL_SCHOOL_SCRIPT := "res://content/codex/gameplay/spell_schools.gd"
const SPELL_VARIANT_SCRIPT := "res://content/codex/gameplay/spell_variant.gd"
const ACTION_SCRIPT := "res://content/codex/gameplay/Action.gd"
const ATTACK_SCRIPT := "res://content/codex/gameplay/Attack.gd"
const ARMOR_SCRIPT := "res://content/codex/items/armor.gd"
const CLOTHING_SCRIPT := "res://content/codex/items/clothing.gd"
const UTILITY_SCRIPT := "res://content/codex/items/utility.gd"
const WEAPON_SCRIPT := "res://content/codex/items/weapon.gd"
const STARTER_PACK_SCRIPT := "res://content/codex/items/starter_pack.gd"
const STARTER_PACK_ITEM_SCRIPT := "res://content/codex/items/starter_pack_item.gd"
const STRAIN_RESULT_SCRIPT := "res://content/codex/gameplay/strain_result.gd"
const WEAPON_QUALITY_SCRIPT := "res://content/codex/gameplay/weapon_quality.gd"

@export var run_on_ready: bool = true
@export var preserve_existing_rules: bool = true
@export var write_item_resources: bool = true
@export var wipe_existing_item_resources: bool = true
@export var log_progress: bool = true
@export var quit_when_done: bool = true


func _ready() -> void:
	if not run_on_ready:
		return

	var ok := rebuild_from_database()
	if quit_when_done:
		get_tree().quit(0 if ok else 1)


func rebuild_from_database() -> bool:
	var db := SQLite.new()
	db.path = DB_PATH
	if not db.open_db():
		push_error("Failed to open database: %s" % DB_PATH)
		return false

	var existing_codex := _load_existing_codex()
	var codex := Codex.new()

	var modifiers := _build_modifiers(db)
	var attributes := _build_attributes(db, modifiers)
	var skills := _build_skills(db)
	var defences := _build_defences(db, attributes)
	var conditions := _build_conditions(db)
	var perks := _build_perks(db)
	var races := _build_races(db, perks)
	var homelands := _build_homelands(db, perks)
	var backgrounds := _build_backgrounds(db, perks, skills)
	var ranges := _build_ranges(db)
	var damage_origins := _build_damage_origins(db)
	var damage_types := _build_damage_types(db)
	var effects := _build_effects(db, defences)
	var rules := _build_rules(db)
	var player_data_blueprint := _build_player_data_blueprint(db)
	var actions := _build_actions(db)
	var attacks := _build_attacks(db)
	var spell_schools := _build_spell_schools(db)
	var spells := _build_spells(db, spell_schools, ranges)
	var spell_variants := _build_spell_variants(db, spells)
	var weapon_qualities := _build_weapon_qualities(db)
	var weapons := _build_weapons(db, attacks, ranges, weapon_qualities)
	var armor_items := _build_armor(db)
	var clothing_items := _build_clothing(db)
	var utilities := _build_utilities(db)
	var consumables := _build_consumables(db)
	var items := _merge_item_dictionaries([weapons, armor_items, clothing_items, utilities, consumables])
	var starter_packs := _build_starter_packs(db, items)
	var strain_results := _build_strain_results(db)
	var npcs := _build_npcs(db, attributes, skills, attacks, perks)

	_populate_codex_dictionary(codex.Races, races)
	_populate_codex_dictionary(codex.Backgrounds, backgrounds)
	_populate_codex_dictionary(codex.Homelands, homelands)
	_populate_codex_dictionary(codex.Attributes, attributes)
	_populate_codex_dictionary(codex.Skills, skills)
	_populate_codex_dictionary(codex.Defences, defences)
	_populate_codex_dictionary(codex.Perks, perks)
	_populate_codex_dictionary(codex.Conditions, conditions)
	_populate_codex_dictionary(codex.Modifiers, modifiers)
	_populate_codex_dictionary(codex.DamageOrigins, damage_origins)
	_populate_codex_dictionary(codex.DamageTypes, damage_types)
	_populate_codex_dictionary(codex.Effects, effects)
	_populate_codex_dictionary(codex.Ranges, ranges)
	if not rules.is_empty():
		_populate_codex_dictionary(codex.Rules, rules)
	elif preserve_existing_rules and existing_codex != null:
		_populate_codex_dictionary(codex.Rules, existing_codex.Rules)
	_populate_codex_dictionary(codex.PlayerDataBlueprint, player_data_blueprint)
	_populate_codex_dictionary(codex.Actions, _merge_named_dictionaries([actions, attacks]))
	_populate_codex_dictionary(codex.Attacks, attacks)
	_populate_codex_dictionary(codex.SpellSchools, spell_schools)
	_populate_codex_dictionary(codex.Spells, spells)
	_populate_codex_dictionary(codex.SpellVariants, spell_variants)
	_populate_codex_dictionary(codex.Items, items)
	_populate_codex_dictionary(codex.Weapons, weapons)
	_populate_codex_dictionary(codex.ArmorItems, armor_items)
	_populate_codex_dictionary(codex.ClothingItems, clothing_items)
	_populate_codex_dictionary(codex.Consumables, consumables)
	_populate_codex_dictionary(codex.Utilities, utilities)
	_populate_codex_dictionary(codex.StarterPacks, starter_packs)
	_populate_codex_dictionary(codex.WeaponQualities, weapon_qualities)
	_populate_codex_dictionary(codex.StrainResults, strain_results)
	_populate_codex_dictionary(codex.NPCs, npcs)
	codex.createKeywords()

	if write_item_resources:
		if wipe_existing_item_resources:
			_wipe_existing_imports()
		var export_ok := _export_codex_items(codex)
		if not export_ok:
			db.close_db()
			return false

	var save_error := ResourceSaver.save(codex, OUTPUT_PATH)
	db.close_db()
	if save_error != OK:
		push_error("Failed saving codex to %s (error %s)" % [OUTPUT_PATH, save_error])
		return false

	if log_progress:
		print("Rebuilt codex from %s to %s" % [DB_PATH, OUTPUT_PATH])

	return true


func _build_modifiers(db: SQLite) -> Dictionary:
	return _build_named_table(db, "modifiers", MODIFIER_SCRIPT)


func _build_attributes(db: SQLite, modifiers: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM attributes ORDER BY name")
	var modifiers_by_id := _index_by_id(modifiers)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(ATTRIBUTE_SCRIPT) as Attribute
		_apply_common_fields(item, row)
		item.modifier_1 = modifiers_by_id.get(_int(row, "modifier_id_1"), null)
		item.modifier_1_expression = _text(row, "modifier_expression_1")
		item.modifier_2 = modifiers_by_id.get(_int(row, "modifier_id_2"), null)
		item.modifier_2_expression = _text(row, "modifier_expression_2")
		item.min_value = _int(row, "min_value")
		item.max_value = _int(row, "max_value")
		result[item._name] = item
	return result


func _build_skills(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM skills ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(SKILL_SCRIPT) as Skill
		_apply_common_fields(item, row)
		item.min_rank = _int(row, "min_rank")
		item.max_rank = _int(row, "max_rank")
		result[item._name] = item
	return result


func _build_defences(db: SQLite, attributes: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM defenses ORDER BY name")
	var attributes_by_id := _index_by_id(attributes)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(DEFENCE_SCRIPT) as Defence
		_apply_common_fields(item, row)
		item.attribute1 = attributes_by_id.get(_int(row, "attribute_1"), null)
		item.attribute2 = attributes_by_id.get(_int(row, "attribute_2"), null)
		result[item._name] = item
	return result


func _build_conditions(db: SQLite) -> Dictionary:
	return _build_named_table(db, "conditions", CONDITION_SCRIPT)


func _build_perks(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM perks ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(PERK_SCRIPT) as Perk
		_apply_common_fields(item, row)
		item.category = _text(row, "category")
		item.requirement_text = _text(row, "requirement_text")
		result[item._name] = item
	return result


func _build_races(db: SQLite, perks: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM races ORDER BY name")
	var perks_by_id := _index_by_id(perks)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(RACE_SCRIPT) as Race
		_apply_common_fields(item, row)
		item.perk = perks_by_id.get(_int(row, "perk_id"), null)
		result[item._name] = item
	return result


func _build_homelands(db: SQLite, perks: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM homelands ORDER BY name")
	var perks_by_id := _index_by_id(perks)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(HOMELAND_SCRIPT) as Homeland
		_apply_common_fields(item, row)
		item.perk = perks_by_id.get(_int(row, "perk_id"), null)
		result[item._name] = item
	return result


func _build_backgrounds(db: SQLite, perks: Dictionary, skills: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM backgrounds ORDER BY name")
	var perks_by_id := _index_by_id(perks)
	var skills_by_id := _index_by_id(skills)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(BACKGROUND_SCRIPT) as Background
		_apply_common_fields(item, row)
		item.perk = perks_by_id.get(_int(row, "perk_id"), null)
		item.skill_1 = skills_by_id.get(_int(row, "skill_id_1"), null)
		item.skill_2 = skills_by_id.get(_int(row, "skill_id_2"), null)
		result[item._name] = item
	return result


func _build_ranges(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM ranges ORDER BY max_distance, name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(RANGE_SCRIPT) as ActionRange
		_apply_common_fields(item, row)
		item.max_distance = _int(row, "max_distance")
		item.short_hand = _text(row, "short_hand")
		result[item._name] = item
	return result


func _build_damage_origins(db: SQLite) -> Dictionary:
	return _build_named_table(db, "damage_origins", DAMAGE_ORIGIN_SCRIPT)


func _build_damage_types(db: SQLite) -> Dictionary:
	return _build_named_table(db, "damage_types", DAMAGE_TYPE_SCRIPT)


func _build_effects(db: SQLite, defences: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM effects ORDER BY name")
	var defences_by_id := _index_by_id(defences)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(EFFECT_SCRIPT) as Effect
		_apply_common_fields(item, row)
		item.defence = defences_by_id.get(_int(row, "defense_id"), null)
		result[item._name] = item
	return result


func _build_rules(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM rules ORDER BY id")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item("res://content/codex/rule/rule.gd") as Rule
		_apply_common_fields(item, row)
		item.expression = _text(row, "expression")
		result[item._name] = item
	return result


func _build_player_data_blueprint(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM player_data_blueprint ORDER BY sort_order, name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(PLAYER_DATA_BLUEPRINT_SCRIPT) as PlayerDataBlueprintEntry
		if item == null:
			continue
		item.id = _int(row, "id")
		item._name = _text(row, "name")
		item.short_description = _text(row, "description")
		item.long_description = _text(row, "description")
		item.source_type = _player_blueprint_source_type(_text(row, "source_type"))
		item.source_id = _int(row, "source_id")
		item.source_key = _text(row, "source_key")
		item.expression = _text(row, "expression")
		item.sort_order = _int(row, "sort_order")
		item.enabled = _bool(row, "enabled")
		result[item._name] = item
	return result


func _build_actions(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM actions ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(ACTION_SCRIPT) as Action
		_apply_common_fields(item, row)
		item.ap_cost = _int(row, "action_point_cost")
		item.speed = _int(row, "speed")
		item.expressions = _string_array(row.get("expression", ""))
		result[item._name] = item
	return result


func _build_attacks(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM attacks ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(ATTACK_SCRIPT) as Attack
		_apply_common_fields(item, row)
		item.attack_tier = _text(row, "attack_tier")
		item.ap_cost = _int(row, "action_point_cost")
		item.speed = _int(row, "speed")
		item.expressions = _string_array(row.get("expression", ""))
		result[item._name] = item
	return result


func _build_spell_schools(db: SQLite) -> Dictionary:
	return _build_named_table(db, "spell_schools", SPELL_SCHOOL_SCRIPT)


func _build_spells(db: SQLite, spell_schools: Dictionary, ranges: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM spells ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(SPELL_SCRIPT) as Spell
		_apply_common_fields(item, row)
		item.school = spell_schools.get(_text(row, "school"), null)
		item.tags = _split_csv(_text(row, "tags"))
		item.action_range = _range_for_value(ranges, _text(row, "range_band"))
		item.base_cast = _text(row, "base_cast")
		result[item._name] = item
	return result


func _build_spell_variants(db: SQLite, spells: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM spell_variants ORDER BY spell_id, id")
	var spells_by_id := _index_by_id(spells)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(SPELL_VARIANT_SCRIPT) as SpellVariant
		_apply_common_fields(item, row)
		item.spell = spells_by_id.get(_int(row, "spell_id"), null)
		item.mana_cost = _parse_first_int(_text(row, "mana_cost"))
		result[_variant_key(item)] = item
	return result
	

func _build_weapon_qualities(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM weapon_qualities ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(WEAPON_QUALITY_SCRIPT) as WeaponQuality
		_apply_common_fields(item, row)
		item.expression = _text(row, "expression")
		result[item._name] = item
	return result


func _build_weapons(db: SQLite, attacks: Dictionary, ranges: Dictionary, weapon_qualities: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM weapons ORDER BY name")
	var attacks_by_id := _index_by_id(attacks)
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(WEAPON_SCRIPT) as Weapon
		_apply_common_fields(item, row)
		item.allowed_slots = [Item.ItemSlots.WeaponSlot]
		item.weight = _float(row, "weight")
		item.value = int(round(_float(row, "cost")))
		item.damage_profile = DamageProfile.new(_parse_die_value(_text(row, "damage_die")), _int(row, "base_speed"), _range_for_value(ranges, _text(row, "range_band")))
		item.handedness = _weapon_size_from_text(_text(row, "handedness"))
		item.size = item.handedness
		item.actions = _attacks_from_csv(_text(row, "attack_ids"), attacks_by_id)
		item.qualities = _weapon_qualities_from_csv(_text(row, "qualities"), weapon_qualities)
		result[item._name] = item
	return result


func _build_armor(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM armor ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(ARMOR_SCRIPT) as Armor
		_apply_common_fields(item, row)
		item.allowed_slots = _slots_from_locations(_text(row, "locations_covered"))
		item.physicalDT = _int(row, "physical_dt")
		item.magicalDT = _int(row, "magical_dt")
		item.necroticDT = _int(row, "necrotic_dt")
		item.value = int(round(_float(row, "cost")))
		item.weight = _float(row, "weight")
		result[item._name] = item
	return result


func _build_clothing(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM clothing ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(CLOTHING_SCRIPT) as Clothing
		_apply_common_fields(item, row)
		item.clothing_type = _text(row, "clothing_type")
		item.allowed_slots = _slots_from_locations(_text(row, "locations_covered"))
		item.effect = _text(row, "effect_text")
		item.value = int(round(_float(row, "cost")))
		item.weight = _float(row, "weight")
		result[item._name] = item
	return result


func _build_utilities(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM utilities ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(UTILITY_SCRIPT) as Utility
		_apply_common_fields(item, row)
		item.category = _text(row, "category")
		item.effect = _text(row, "effect_text")
		item.value = int(round(_float(row, "cost")))
		item.weight = _float(row, "weight")
		result[item._name] = item
	return result


func _build_consumables(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM consumables ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(CONSUMABLE_SCRIPT) as Consumable
		_apply_common_fields(item, row)
		item.category = _text(row, "consumable_type")
		item.effect = _text(row, "short_description")
		item.healing = _int(row, "hp_healed")
		item.addiction = _int(row, "addiction_threshold")
		item.alcoholic = _bool(row, "alcoholic")
		item.duration = _text(row, "duration")
		item.value = int(round(_float(row, "cost")))
		item.weight = _float(row, "weight")
		result[item._name] = item
	return result


func _build_starter_packs(db: SQLite, items: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM starter_packs ORDER BY name")
	var result: Dictionary = {}
	var packs_by_id := {}
	for row in rows:
		var item := _make_item(STARTER_PACK_SCRIPT)
		_apply_common_fields(item, row)
		item.leftover_gold = _float(row, "leftover_gold")
		item.items = []
		result[item._name] = item
		packs_by_id[item.id] = item

	var item_rows := _query(db, "SELECT * FROM starter_pack_items ORDER BY starter_pack_id, id")
	var items_by_table_and_id := _index_items_by_table_and_id(items)
	for row in item_rows:
		var pack = packs_by_id.get(_int(row, "starter_pack_id"), null)
		if pack == null:
			continue
		var entry := _make_item(STARTER_PACK_ITEM_SCRIPT)
		entry.item_table = _text(row, "item_table")
		entry.item_id = _int(row, "item_id")
		entry.quantity = _int(row, "quantity")
		entry.loadout_group = _text(row, "loadout_group")
		entry.item = _item_from_table_lookup(items_by_table_and_id, entry.item_table, entry.item_id)
		pack.items.append(entry)

	return result


func _build_strain_results(db: SQLite) -> Dictionary:
	var rows := _query(db, "SELECT * FROM strain_table ORDER BY roll_total")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(STRAIN_RESULT_SCRIPT)
		item.id = _int(row, "roll_total")
		item._name = _text(row, "result_name")
		item.roll_total = _int(row, "roll_total")
		item.outcome = _text(row, "outcome")
		result[_strain_key(item)] = item
	return result


func _build_npcs(db: SQLite, attributes: Dictionary, skills: Dictionary, attacks: Dictionary, perks: Dictionary) -> Dictionary:
	var rows := _query(db, "SELECT * FROM npcs ORDER BY name")
	var result: Dictionary = {}
	for row in rows:
		var item := _make_item(NPC_SCRIPT) as NPC
		_apply_common_fields(item, row)
		item.data = _build_npc_data(row, attributes, skills, attacks, perks)
		result[item._name] = item
	return result


func _build_npc_data(row: Dictionary, attributes: Dictionary, skills: Dictionary, attacks: Dictionary, perks: Dictionary) -> CreatureData:
	var npc_type := _text(row, "type").to_lower()
	var data: CreatureData
	match npc_type:
		"humanoid":
			data = HumanoidData.new()
		"beast":
			data = BeastData.new()
		"undead":
			data = UndeadData.new()
		_:
			data = CreatureData.new()

	data.id = _int(row, "id")
	data.name = _text(row, "name")
	data.short_description = _text(row, "short_description")
	data.long_description = _text(row, "long_description")
	data.type = _text(row, "type")
	data.category = _text(row, "category")
	data.level = _int(row, "level")
	data.max_hp = _int(row, "max_hp")
	data.maxHP = data.max_hp
	data.currentHP = data.max_hp
	data.attributes = []
	for attribute in _build_stat_array(_dict_from_json(_text(row, "attributes")), attributes):
		data.attributes.append(attribute)
	if _has_property(data, "skills"):
		data.set("skills", [])
		for skill in _build_stat_array(_dict_from_json(_text(row, "skills")), skills):
			data.skills.append(skill)
	data.attacks = []
	for attack in _build_named_array(_string_array(row.get("attacks", "")), attacks):
		data.attacks.append(attack)
	data.actions = []
	for attack in data.attacks:
		data.actions.append(attack)
	data.perks = []
	for perk in _build_named_array(_string_array(row.get("perks", "")), perks):
		data.perks.append(perk)
	data.conditions = []
	return data


func _build_named_table(db: SQLite, table_name: String, script_path: String) -> Dictionary:
	var rows := _query(db, "SELECT * FROM %s ORDER BY name" % table_name)
	var result := {}
	for row in rows:
		var item := _make_item(script_path) as CodexItem
		_apply_common_fields(item, row)
		result[item._name] = item
	return result


func _merge_item_dictionaries(dictionaries: Array) -> Dictionary:
	var result: Dictionary = {}
	for dictionary in dictionaries:
		for key in dictionary.keys():
			result[key] = dictionary[key]
	return result


func _merge_named_dictionaries(dictionaries: Array) -> Dictionary:
	var result: Dictionary = {}
	for dictionary in dictionaries:
		for key in dictionary.keys():
			result[key] = dictionary[key]
	return result


func _populate_codex_dictionary(target: Dictionary, source: Dictionary) -> void:
	target.clear()
	for item in source.values():
		if item is CodexItem:
			target[item.id] = item


func _export_codex_items(codex: Codex) -> bool:
	var exports := [
		{"folder": "races", "items": codex.Races},
		{"folder": "backgrounds", "items": codex.Backgrounds},
		{"folder": "homelands", "items": codex.Homelands},
		{"folder": "attributes", "items": codex.Attributes},
		{"folder": "skills", "items": codex.Skills},
		{"folder": "defences", "items": codex.Defences},
		{"folder": "perks", "items": codex.Perks},
		{"folder": "conditions", "items": codex.Conditions},
		{"folder": "modifiers", "items": codex.Modifiers},
		{"folder": "damage_origins", "items": codex.DamageOrigins},
		{"folder": "damage_types", "items": codex.DamageTypes},
		{"folder": "effects", "items": codex.Effects},
		{"folder": "ranges", "items": codex.Ranges},
		{"folder": "rules", "items": codex.Rules},
		{"folder": "player_data_blueprint", "items": codex.PlayerDataBlueprint},
		{"folder": "actions", "items": codex.Actions},
		{"folder": "attacks", "items": codex.Attacks},
		{"folder": "spell_schools", "items": codex.SpellSchools},
		{"folder": "spells", "items": codex.Spells},
		{"folder": "spell_variants", "items": codex.SpellVariants},
		{"folder": "items", "items": codex.Items},
		{"folder": "weapons", "items": codex.Weapons},
		{"folder": "armor", "items": codex.ArmorItems},
		{"folder": "clothing", "items": codex.ClothingItems},
		{"folder": "consumables", "items": codex.Consumables},
		{"folder": "utilities", "items": codex.Utilities},
		{"folder": "starter_packs", "items": codex.StarterPacks},
		{"folder": "weapon_qualities", "items": codex.WeaponQualities},
		{"folder": "strain_results", "items": codex.StrainResults},
		{"folder": "npcs", "items": codex.NPCs},
	]

	var ok := true
	for export in exports:
		ok = _save_codex_dictionary(str(export.folder), export.items) and ok
	return ok


func _save_codex_dictionary(folder_name: String, items: Dictionary) -> bool:
	var folder_path := "%s/%s" % [ITEM_OUTPUT_ROOT, folder_name]
	var make_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder_path))
	if make_error != OK:
		push_error("Failed creating folder %s (error %s)" % [folder_path, make_error])
		return false

	var ok := true
	for item in items.values():
		if not item is CodexItem:
			continue
		var file_path := "%s/%s.tres" % [folder_path, _resource_file_name(item)]
		var save_error := ResourceSaver.save(item, file_path)
		if save_error != OK:
			push_error("Failed saving %s (error %s)" % [file_path, save_error])
			ok = false
		elif log_progress:
			print("Saved %s" % file_path)
	return ok


func _wipe_existing_imports() -> void:
	_remove_tres_files_recursively(ITEM_OUTPUT_ROOT)


func _remove_tres_files_recursively(path: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		var child_path := "%s/%s" % [path, entry]
		if dir.current_is_dir():
			if entry != "." and entry != "..":
				_remove_tres_files_recursively(child_path)
		elif entry.ends_with(".tres"):
			dir.remove(entry)
		entry = dir.get_next()
	dir.list_dir_end()


func _resource_file_name(item: CodexItem) -> String:
	var parts: Array[String] = []
	if item.id >= 0:
		parts.append(str(item.id))
	if not item._name.is_empty():
		parts.append(_safe_file_name(item._name))
	if parts.is_empty():
		return "entry"
	return "_".join(parts)


func _safe_file_name(value: String) -> String:
	return value.replace("/", "-").replace("\\", "-").replace(":", "").replace("?", "").replace("*", "").replace('"', "").replace("<", "").replace(">", "").replace("|", "").strip_edges()


func _dictionary_by_id(dictionary: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for item in dictionary.values():
		if item is CodexItem:
			result[item.id] = item
	return result


func _load_existing_codex() -> Codex:
	if not ResourceLoader.exists(OUTPUT_PATH):
		return null
	return load(OUTPUT_PATH) as Codex


func _make_item(script_path: String) -> Resource:
	var script := load(script_path)
	if script == null:
		push_error("Missing script: %s" % script_path)
		return null
	var resource := Resource.new()
	resource.set_script(script)
	return resource


func _apply_common_fields(item: CodexItem, row: Dictionary) -> void:
	item.id = _int(row, "id")
	item._name = _text(row, "name")
	item.short_description = _text(row, "short_description")
	item.long_description = _text(row, "long_description")


func _index_by_id(dictionary: Dictionary) -> Dictionary:
	var result := {}
	for value in dictionary.values():
		if value is CodexItem:
			result[value.id] = value
	return result


func _index_items_by_table_and_id(items: Dictionary) -> Dictionary:
	var result := {}
	for item in items.values():
		if item is Weapon:
			_store_table_item(result, "weapons", item)
		elif item is Armor and not (item is Clothing):
			_store_table_item(result, "armor", item)
		elif item is Clothing:
			_store_table_item(result, "clothing", item)
		elif item is Consumable:
			_store_table_item(result, "consumables", item)
		elif item is Utility:
			_store_table_item(result, "utilities", item)
	return result


func _store_table_item(index: Dictionary, table_name: String, item: Item) -> void:
	if not index.has(table_name):
		index[table_name] = {}
	index[table_name][item.id] = item


func _item_from_table_lookup(index: Dictionary, table_name: String, item_id: int) -> Item:
	var table: Dictionary = index.get(table_name, {})
	return table.get(item_id, null)


func _range_for_value(ranges: Dictionary, value: String) -> ActionRange:
	if value.is_empty():
		return null
	for range_item in ranges.values():
		if range_item._name == value or range_item.short_hand == value:
			return range_item
	return null


func _slots_from_locations(locations: String) -> Array[Item.ItemSlots]:
	var result: Array[Item.ItemSlots] = []
	for token in _split_csv(locations):
		match token.to_lower():
			"head":
				result.append(Item.ItemSlots.Head)
			"torso", "body":
				result.append(Item.ItemSlots.Torso)
			"arm", "arms":
				result.append(Item.ItemSlots.LeftArm)
				result.append(Item.ItemSlots.RightArm)
			"left arm":
				result.append(Item.ItemSlots.LeftArm)
			"right arm":
				result.append(Item.ItemSlots.RightArm)
			"leg", "legs":
				result.append(Item.ItemSlots.LeftLeg)
				result.append(Item.ItemSlots.RightLeg)
			"left leg":
				result.append(Item.ItemSlots.LeftLeg)
			"right leg":
				result.append(Item.ItemSlots.RightLeg)
	return _dedupe_slots(result)


func _dedupe_slots(slots: Array[Item.ItemSlots]) -> Array[Item.ItemSlots]:
	var result: Array[Item.ItemSlots] = []
	for slot in slots:
		if not result.has(slot):
			result.append(slot)
	return result


func _weapon_size_from_text(value: String) -> Weapon.WeaponSize:
	match value.strip_edges().to_upper():
		"2H":
			return Weapon.WeaponSize.TWO_HANDED
		_:
			return Weapon.WeaponSize.ONE_HANDED


func _attacks_from_csv(value: String, attacks_by_id: Dictionary) -> Array[Action]:
	var result: Array[Action] = []
	for token in _split_csv(value):
		var attack := attacks_by_id.get(int(token), null) as Attack
		if attack != null:
			result.append(attack)
	return result


func _weapon_qualities_from_csv(value: String, weapon_qualities: Dictionary) -> Array:
	var result: Array = []
	for token in _split_csv(value):
		var quality: Variant = weapon_qualities.get(token, null)
		if quality != null:
			result.append(quality)
	return result


func _build_stat_array(values: Dictionary, templates: Dictionary) -> Array:
	var result: Array = []
	for key in values.keys():
		var template: Variant = templates.get(str(key), null)
		if template == null:
			continue
		var clone: Variant = template.duplicate(true)
		if _has_property(clone, "value"):
			clone.value = int(values[key])
		result.append(clone)
	return result


func _build_named_array(names: Array[String], values: Dictionary) -> Array:
	var result: Array = []
	for _name in names:
		var item = values.get(_name, null)
		if item != null:
			result.append(item)
	return result


func _dict_from_json(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}


func _string_array(value: Variant) -> Array[String]:
	if value is Array:
		var direct: Array[String] = []
		for entry in value:
			direct.append(str(entry))
		return direct

	var text := str(value).strip_edges()
	if text.is_empty():
		return []
	if text.begins_with("[") and text.ends_with("]"):
		if text.contains('""'):
			return _parse_quoted_array(text)
		var parsed = JSON.parse_string(text)
		if parsed is Array:
			var result: Array[String] = []
			for entry in parsed:
				result.append(str(entry))
			return result
		return _parse_quoted_array(text)
	return _split_csv(text)


func _parse_quoted_array(text: String) -> Array[String]:
	var result: Array[String] = []
	var body := text.substr(1, text.length() - 2)
	var current := ""
	var in_quotes := false
	var i := 0
	while i < body.length():
		var character := body[i]
		if character == '"':
			if in_quotes and i + 1 < body.length() and body[i + 1] == '"':
				current += '"'
				i += 1
			else:
				in_quotes = not in_quotes
		elif character == "," and not in_quotes:
			var trimmed := current.strip_edges()
			if not trimmed.is_empty():
				result.append(trimmed)
			current = ""
		else:
			current += character
		i += 1
	var final_value := current.strip_edges()
	if not final_value.is_empty():
		result.append(final_value)
	return result


func _split_csv(value: String) -> Array[String]:
	var result: Array[String] = []
	for token in value.split(",", false):
		var trimmed := token.strip_edges()
		if not trimmed.is_empty():
			result.append(trimmed)
	return result


func _variant_key(item: SpellVariant) -> String:
	if item.spell == null:
		return item._name
	return "%s :: %s" % [item.spell._name, item._name]


func _strain_key(item) -> String:
	return "%s :: %s" % [str(item.roll_total), item._name]


func _parse_die_value(value: String) -> int:
	return _parse_first_int(value)


func _parse_first_int(value: String) -> int:
	var digits := ""
	for character in value:
		if character >= "0" and character <= "9":
			digits += character
		elif not digits.is_empty():
			break
	if digits.is_empty():
		return 0
	return int(digits)


func _has_property(resource: Resource, property_name: String) -> bool:
	for property_info in resource.get_property_list():
		if str(property_info.get("name", "")) == property_name:
			return true
	return false


func _text(row: Dictionary, key: String) -> String:
	if not row.has(key) or row[key] == null:
		return ""
	return str(row[key])


func _int(row: Dictionary, key: String) -> int:
	if not row.has(key) or row[key] == null:
		return 0
	return int(row[key])


func _float(row: Dictionary, key: String) -> float:
	if not row.has(key) or row[key] == null:
		return 0.0
	return float(row[key])


func _bool(row: Dictionary, key: String) -> bool:
	if not row.has(key) or row[key] == null:
		return false
	return bool(row[key])


func _query(db: SQLite, sql: String) -> Array:
	if not db.query(sql):
		push_error("SQL query failed: %s" % sql)
		return []
	return db.query_result


func _player_blueprint_source_type(value: String) -> PlayerDataBlueprintEntry.SourceType:
	match value.strip_edges().to_lower():
		"attribute":
			return PlayerDataBlueprintEntry.SourceType.ATTRIBUTE
		"modifier":
			return PlayerDataBlueprintEntry.SourceType.MODIFIER
		"player_field":
			return PlayerDataBlueprintEntry.SourceType.PLAYER_FIELD
		"player_method":
			return PlayerDataBlueprintEntry.SourceType.PLAYER_METHOD
		"derived_expression":
			return PlayerDataBlueprintEntry.SourceType.DERIVED_EXPRESSION
		_:
			return PlayerDataBlueprintEntry.SourceType.ATTRIBUTE
