extends Node

const DB_PATH := "res://data/Codex.db"
const DATA_ROOT := "res://data"
const CODEX_SCRIPT := preload("res://content/codex/Codex.gd")

const ARMOR_SIDE_SUFFIXES := [" Left", " Right"]

const OUTPUT_FOLDERS := {
	"Action": "Action",
	"Attribute": "Attribute",
	"Background": "Background",
	"Condition": "Condition",
	"Defence": "Defence",
	"Homeland": "Homeland",
	"Item": "Item",
	"NPC": "NPC",
	"Perk": "Perk",
	"Race": "Race",
	"Rule": "Rule",
	"Skill": "Skill",
}

@export var run_on_ready: bool = true
@export var wipe_existing_files: bool = true
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

	_prepare_output_folders()
	if wipe_existing_files:
		_wipe_existing_tres_files()

	var keywords := _load_keyword_metadata(db)
	var perks := _build_perks(db)
	var attributes := _build_attributes(db, keywords)
	var skills := _build_skills(db, keywords)
	var rules := _build_rules(db, keywords)
	var backgrounds := _build_backgrounds(db, keywords, perks)
	var conditions := _build_conditions(db)
	var homelands := _build_homelands(db, keywords, perks)
	var races := _build_races(db, keywords, perks)
	var defences := _build_defences(db, keywords, attributes)
	var actions := _build_actions(db)
	var items := _build_items(db, keywords, actions)
	var npcs := _build_npcs(db, attributes)

	_build_codex_tres(races, backgrounds, homelands, attributes, skills, defences, perks, conditions, rules, actions, items, npcs)

	if log_progress:
		print("Finished rebuilding codex .tres files from SQL.")

	return true

func _prepare_output_folders() -> void:
	for folder in OUTPUT_FOLDERS.values():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("%s/%s" % [DATA_ROOT, folder]))

func _wipe_existing_tres_files() -> void:
	for folder in OUTPUT_FOLDERS.values():
		var dir := DirAccess.open("%s/%s" % [DATA_ROOT, folder])
		if dir == null:
			continue

		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".tres"):
				dir.remove(file_name)
			file_name = dir.get_next()

func _load_keyword_metadata(db: SQLite) -> Dictionary:
	var result := {}
	for row in _query(db, "SELECT keyword, short_description, long_description FROM Keyword"):
		result[_text(row, "keyword")] = {
			"short_description": _text(row, "short_description"),
			"long_description": _text(row, "long_description"),
		}
	return result

func _build_perks(db: SQLite) -> Dictionary[String, Perk]:
	var result: Dictionary[String, Perk] = {}
	for row in _query(db, "SELECT name, short_description, long_description, category FROM Perk ORDER BY ID"):
		var perk := Perk.new()
		perk._name = _text(row, "name")
		perk.short_description = _text(row, "short_description")
		perk.long_description = _text(row, "long_description")
		perk.category = _text(row, "category")
		_save_tres(perk, "Perk", perk._name)
		result[perk._name] = perk
	return result

func _build_attributes(db: SQLite, keywords: Dictionary) -> Dictionary[String, Attribute]:
	var result: Dictionary[String, Attribute] = {}
	for row in _query(db, "SELECT name, short_description, long_description, bonus_1_prefix, bonus_2_prefix, bonus_1_expression, bonus_2_expression, bonus_1_suffix, bonus_2_suffix FROM Attribute ORDER BY ID"):
		var attribute := Attribute.new()
		attribute._name = _text(row, "name")
		attribute.short_description = _meta_text(keywords, attribute._name, "short_description", _text(row, "short_description"))
		attribute.long_description = _meta_text(keywords, attribute._name, "long_description", _text(row, "long_description"))
		attribute.value = 0
		attribute.bonus_1_prefix = _text(row, "bonus_1_prefix")
		attribute.bonus_2_prefix = _text(row, "bonus_2_prefix")
		attribute.bonus_1_expression = _text(row, "bonus_1_expression")
		attribute.bonus_2_expression = _text(row, "bonus_2_expression")
		attribute.bonus_1_suffix = _text(row, "bonus_1_suffix")
		attribute.bonus_2_suffix = _text(row, "bonus_2_suffix")
		_save_tres(attribute, "Attribute", attribute._name)
		result[attribute._name] = attribute
	return result

func _build_skills(db: SQLite, keywords: Dictionary) -> Dictionary[String, Skill]:
	var result: Dictionary[String, Skill] = {}
	for row in _query(db, "SELECT name, short_description, long_description FROM Skill ORDER BY ID"):
		var skill := Skill.new()
		skill._name = _text(row, "name")
		skill.short_description = _meta_text(keywords, skill._name, "short_description", _text(row, "short_description"))
		skill.long_description = _meta_text(keywords, skill._name, "long_description", _text(row, "long_description"))
		skill.value = 0
		_save_tres(skill, "Skill", skill._name)
		result[skill._name] = skill
	return result

func _build_rules(db: SQLite, keywords: Dictionary) -> Dictionary[String, Rule]:
	var result: Dictionary[String, Rule] = {}
	for row in _query(db, "SELECT name, expression FROM Rule ORDER BY ID"):
		var rule := Rule.new()
		rule._name = _text(row, "name")
		rule.short_description = _meta_text(keywords, rule._name, "short_description", "")
		rule.long_description = _meta_text(keywords, rule._name, "long_description", "")
		rule.expression = _text(row, "expression")
		_save_tres(rule, "Rule", rule._name)
		result[rule._name] = rule
	return result

func _build_conditions(db: SQLite) -> Dictionary[String, Condition]:
	var result: Dictionary[String, Condition] = {}
	for row in _query(db, "SELECT name, short_description, long_description FROM Condition ORDER BY ID"):
		var condition := Condition.new()
		condition._name = _text(row, "name")
		condition.short_description = _text(row, "short_description")
		condition.long_description = _text(row, "long_description")
		_save_tres(condition, "Condition", condition._name)
		result[condition._name] = condition
	return result

func _build_backgrounds(db: SQLite, keywords: Dictionary, perks: Dictionary[String, Perk]) -> Dictionary[String, Background]:
	var result: Dictionary[String, Background] = {}
	for row in _query(db, "SELECT name, short_description, long_description, perk FROM Background ORDER BY ID"):
		var background := Background.new()
		background._name = _text(row, "name")
		background.short_description = _meta_text(keywords, background._name, "short_description", _text(row, "short_description"))
		background.long_description = _meta_text(keywords, background._name, "long_description", _text(row, "long_description"))
		background.perk = perks.get(_text(row, "perk"), null)
		_save_tres(background, "Background", background._name)
		result[background._name] = background
	return result

func _build_homelands(db: SQLite, keywords: Dictionary, perks: Dictionary[String, Perk]) -> Dictionary[String, Homeland]:
	var result: Dictionary[String, Homeland] = {}
	for row in _query(db, "SELECT name, short_description, long_description, perk FROM Homeland ORDER BY ID"):
		var homeland := Homeland.new()
		homeland._name = _text(row, "name")
		homeland.short_description = _meta_text(keywords, homeland._name, "short_description", _text(row, "short_description"))
		homeland.long_description = _meta_text(keywords, homeland._name, "long_description", _text(row, "long_description"))
		homeland.perk = perks.get(_text(row, "perk"), null)
		_save_tres(homeland, "Homeland", homeland._name)
		result[homeland._name] = homeland
	return result

func _build_races(db: SQLite, keywords: Dictionary, perks: Dictionary[String, Perk]) -> Dictionary[String, Race]:
	var result: Dictionary[String, Race] = {}
	for row in _query(db, "SELECT name, short_description, long_description, perk FROM Race ORDER BY ID"):
		var race := Race.new()
		race._name = _text(row, "name")
		race.short_description = _meta_text(keywords, race._name, "short_description", _text(row, "short_description"))
		race.long_description = _meta_text(keywords, race._name, "long_description", _text(row, "long_description"))
		race.perk = perks.get(_text(row, "perk"), null)
		_save_tres(race, "Race", race._name)
		result[race._name] = race
	return result

func _build_defences(db: SQLite, keywords: Dictionary, attributes: Dictionary[String, Attribute]) -> Dictionary[String, Defence]:
	var result: Dictionary[String, Defence] = {}
	for row in _query(db, "SELECT name, attribute1, attribute2 FROM Defence ORDER BY ID"):
		var defence := Defence.new()
		defence._name = _text(row, "name")
		defence.short_description = _meta_text(keywords, defence._name, "short_description", "")
		defence.long_description = _meta_text(keywords, defence._name, "long_description", "")
		defence.attribute1 = attributes.get(_text(row, "attribute1"), null)
		defence.attribute2 = attributes.get(_text(row, "attribute2"), null)
		_save_tres(defence, "Defence", defence._name)
		result[defence._name] = defence
	return result

func _build_actions(db: SQLite) -> Dictionary[String, Action]:
	var result: Dictionary[String, Action] = {}
	for row in _query(db, "SELECT name, short_description, long_description, expressions FROM Action ORDER BY ID"):
		var action_name := _text(row, "name")
		if result.has(action_name):
			continue
		var action := Action.new()
		action._name = action_name
		action.short_description = _text(row, "short_description")
		action.long_description = _text(row, "long_description")
		var expressions_json := _text(row, "expressions")
		if not expressions_json.is_empty():
			var parsed: Variant = JSON.parse_string(expressions_json)
			if parsed is Array:
				action.expressions.assign(parsed)
		_save_tres(action, "Action", action._name)
		result[action._name] = action
	return result

func _build_items(db: SQLite, keywords: Dictionary, actions: Dictionary[String, Action]) -> Dictionary[String, Item]:
	var result: Dictionary[String, Item] = {}
	var armor_rows := _query(db, "SELECT item, armor_slot, physical_dt, magical_dt, necrotic_dt FROM Armor")
	var clothing_rows := _rows_by_key(_query(db, "SELECT item, locations_covered, type FROM Clothing"), "item")
	var consumable_rows := _rows_by_key(_query(db, "SELECT item, type, hp_healed, effect, duration, addiction_threshold, alcoholic FROM Consumable"), "item")
	var utility_rows := _rows_by_key(_query(db, "SELECT item, category, effect FROM Utility"), "item")
	var weapon_rows := _rows_by_key(_query(db, "SELECT item, damage_die, crit_die, base_speed, qualities, size, range, actions FROM Weapon"), "item")

	for row in _query(db, "SELECT name, weight, cost, type FROM Item ORDER BY ID"):
		var item_name := _text(row, "name")
		var item_type := _text(row, "type")
		var item := _make_item_resource(item_name, item_type, row, keywords, armor_rows, clothing_rows, consumable_rows, utility_rows, weapon_rows, actions)
		if item != null:
			_save_tres(item, "Item", item._name)
			result[item._name] = item
	return result

func _build_npcs(db: SQLite, attributes: Dictionary[String, Attribute]) -> Dictionary[String, NPC]:
	var result: Dictionary[String, NPC] = {}
	for row in _query(db, "SELECT name, short_description, long_description, creature_type, max_hp, level, attributes FROM NPC ORDER BY ID"):
		var creature_data := _make_npc_creature_data(row, attributes)
		var npc := NPC.new()
		npc._name = _text(row, "name")
		npc.short_description = _text(row, "short_description")
		npc.long_description = _text(row, "long_description")
		npc.data = creature_data
		_save_tres(npc, "NPC", npc._name)
		result[npc._name] = npc
	return result

func _build_codex_tres(races: Dictionary[String, Race], backgrounds: Dictionary[String, Background], homelands: Dictionary[String, Homeland], attributes: Dictionary[String, Attribute], skills: Dictionary[String, Skill], defences: Dictionary[String, Defence], perks: Dictionary[String, Perk], conditions: Dictionary[String, Condition], rules: Dictionary[String, Rule], actions: Dictionary[String, Action], items: Dictionary[String, Item], npcs: Dictionary[String, NPC]) -> void:
	var codex := Resource.new()
	codex.set_script(CODEX_SCRIPT)
	codex.Races = races
	codex.Backgrounds = backgrounds
	codex.Homelands = homelands
	codex.Attributes = attributes
	codex.Skills = skills
	codex.Defences = defences
	codex.Perks = perks
	codex.Conditions = conditions
	codex.Rules = rules
	codex.Actions = actions
	codex.Items = items
	codex.NPCs = npcs
	codex.createKeywords()
	var error := ResourceSaver.save(codex, "res://data/baseRules.tres")
	if error != OK:
		push_error("Failed saving res://data/baseRules.tres (error %s)" % error)
	elif log_progress:
		print("Saved res://data/baseRules.tres")

func _make_npc_creature_data(row: Dictionary, attribute_templates: Dictionary[String, Attribute]) -> CreatureData:
	var creature_type := _text(row, "creature_type")
	var creature_data: CreatureData
	match creature_type:
		"HumanoidData":
			creature_data = HumanoidData.new()
		"UndeadData":
			creature_data = UndeadData.new()
		"BeastData":
			creature_data = BeastData.new()
		_:
			creature_data = CreatureData.new()

	creature_data._name = _text(row, "name")
	creature_data.maxHP = _int(row, "max_hp")
	creature_data.currentHP = creature_data.maxHP
	creature_data.level = _int(row, "level")
	creature_data.attributes = _build_npc_attributes(_text(row, "attributes"), attribute_templates)
	return creature_data

func _build_npc_attributes(attributes_json: String, attribute_templates: Dictionary[String, Attribute]) -> Array[Attribute]:
	var parsed: Variant = JSON.parse_string(attributes_json)
	var result: Array[Attribute] = []
	if parsed is Dictionary:
		for attribute_name in parsed.keys():
			var template: Attribute = attribute_templates.get(str(attribute_name), null)
			if template == null:
				continue
			var attribute := template.duplicate(true) as Attribute
			attribute.value = int(parsed[attribute_name])
			result.append(attribute)
	return result

func _make_item_resource(item_name: String, item_type: String, item_row: Dictionary, keywords: Dictionary, armor_rows: Array, clothing_rows: Dictionary, consumable_rows: Dictionary, utility_rows: Dictionary, weapon_rows: Dictionary, actions: Dictionary[String, Action]) -> Item:
	var item: Item = null
	match item_type:
		"Armor":
			var armor := Armor.new()
			_apply_item_metadata(armor, item_name, item_row, keywords)
			_apply_armor_metadata(armor, _find_armor_rows(item_name, armor_rows))
			_ensure_item_descriptions(armor, item_type)
			armor._load_icon_from_name()
			item = armor
		"Clothing":
			var clothing := Clothing.new()
			var extra: Dictionary = clothing_rows.get(item_name, {})
			_apply_item_metadata(clothing, item_name, item_row, keywords)
			clothing.allowed_slots = _parse_armor_slots(_text(extra, "locations_covered"))
			clothing.effect = _text(extra, "type")
			_ensure_item_descriptions(clothing, item_type)
			clothing._load_icon_from_name()
			item = clothing
		"Consumable":
			var consumable := Consumable.new()
			var extra: Dictionary = consumable_rows.get(item_name, {})
			_apply_item_metadata(consumable, item_name, item_row, keywords)
			consumable.allowed_slots = [Item.ItemSlots.QuickItem]
			consumable.category = "Consumable"
			consumable.consumable_type = _text(extra, "type")
			consumable.healing = _int(extra, "hp_healed")
			consumable.effect = _text(extra, "effect")
			consumable.duration = _text(extra, "duration")
			consumable.addiction = _int(extra, "addiction_threshold")
			consumable.alcoholic = _bool(extra, "alcoholic")
			_ensure_item_descriptions(consumable, item_type)
			consumable._load_icon_from_name()
			item = consumable
		"Utility":
			var utility := Utility.new()
			var extra: Dictionary = utility_rows.get(item_name, {})
			_apply_item_metadata(utility, item_name, item_row, keywords)
			utility.allowed_slots = [Item.ItemSlots.QuickItem]
			utility.category = _text(extra, "category")
			utility.effect = _text(extra, "effect")
			_ensure_item_descriptions(utility, item_type)
			utility._load_icon_from_name()
			item = utility
		"Weapon":
			var weapon := Weapon.new()
			var extra: Dictionary = weapon_rows.get(item_name, {})
			_apply_item_metadata(weapon, item_name, item_row, keywords)
			weapon.allowed_slots = [Item.ItemSlots.WeaponSlot]
			weapon.damage_profile = DamageProfile.new(0, _int(extra, "damage_die"), _int(extra, "crit_die"))
			weapon.speed = _int(extra, "base_speed")
			weapon.qualities = []
			var qualities := _text(extra, "qualities")
			if not qualities.is_empty():
				for quality in qualities.split(",", false):
					var cleaned := quality.strip_edges()
					if not cleaned.is_empty():
						weapon.qualities.append(cleaned)
			weapon.size = _parse_weapon_size(_text(extra, "size"))
			weapon.weaponRange = _parse_weapon_range(_text(extra, "range"))
			var action_names := _text(extra, "actions")
			if not action_names.is_empty():
				for action_name in action_names.split(",", false):
					var action: Action = actions.get(action_name.strip_edges(), null)
					if action != null:
						weapon.actions.append(action)
			_ensure_item_descriptions(weapon, item_type)
			weapon._load_icon_from_name()
			item = weapon
	return item

func _apply_item_metadata(item: Item, item_name: String, item_row: Dictionary, keywords: Dictionary) -> void:
	item._name = item_name
	item.short_description = _meta_text(keywords, item_name, "short_description", "")
	item.long_description = _meta_text(keywords, item_name, "long_description", "")
	item.weight = _float(item_row, "weight")
	item.value = _int(item_row, "cost")

func _apply_armor_metadata(armor: Armor, rows: Array) -> void:
	var allowed_slots: Array[Item.ItemSlots] = []
	for row in rows:
		for slot in _parse_armor_slots(_text(row, "armor_slot")):
			if not allowed_slots.has(slot):
				allowed_slots.append(slot)
		armor.physicalDT = max(armor.physicalDT, _int(row, "physical_dt"))
		armor.magicalDT = max(armor.magicalDT, _int(row, "magical_dt"))
		armor.necroticDT = max(armor.necroticDT, _int(row, "necrotic_dt"))
	armor.allowed_slots = allowed_slots

func _find_armor_rows(item_name: String, armor_rows: Array) -> Array:
	var result: Array = []
	for row in armor_rows:
		if _normalize_armor_item_name(_text(row, "item")) == item_name:
			result.append(row)
	return result

func _normalize_armor_item_name(value: String) -> String:
	for suffix in ARMOR_SIDE_SUFFIXES:
		if value.ends_with(suffix):
			return value.left(value.length() - suffix.length())
	return value

func _ensure_item_descriptions(item: Item, item_type: String) -> void:
	if item.short_description.is_empty():
		item.short_description = _build_item_short_description(item, item_type)
	if item.long_description.is_empty():
		item.long_description = _build_item_long_description(item, item_type)

func _build_item_short_description(item: Item, item_type: String) -> String:
	match item_type:
		"Armor":
			return "Armor for %s." % _describe_item_slots(item.allowed_slots)
		"Clothing":
			return "Clothing for %s." % _describe_item_slots(item.allowed_slots)
		"Consumable":
			var consumable := item as Consumable
			if consumable != null and not consumable.consumable_type.is_empty():
				return "%s consumable." % consumable.consumable_type
			return "A consumable item."
		"Utility":
			var utility := item as Utility
			if utility != null and not utility.category.is_empty():
				return "%s item." % utility.category
			return "A utility item."
		"Weapon":
			return "A weapon used in combat."
	return "%s item." % item_type

func _build_item_long_description(item: Item, item_type: String) -> String:
	match item_type:
		"Armor":
			var armor := item as Armor
			if armor == null:
				return ""
			return "Provides coverage for %s and grants %s physical DT, %s magical DT, and %s necrotic DT." % [_describe_item_slots(armor.allowed_slots), armor.physicalDT, armor.magicalDT, armor.necroticDT]
		"Clothing":
			var clothing := item as Clothing
			if clothing == null:
				return ""
			var clothing_effect := "."
			if not clothing.effect.is_empty():
				clothing_effect = " Its style or role is %s." % clothing.effect
			return "A clothing item worn on %s%s" % [_describe_item_slots(clothing.allowed_slots), clothing_effect]
		"Consumable":
			var consumable := item as Consumable
			if consumable == null:
				return ""
			var parts: Array[String] = []
			if not consumable.consumable_type.is_empty():
				parts.append("Type: %s." % consumable.consumable_type)
			if consumable.healing > 0:
				parts.append("Restores %s HP." % consumable.healing)
			if not consumable.effect.is_empty():
				parts.append("Effect: %s." % consumable.effect)
			if not consumable.duration.is_empty():
				parts.append("Duration: %s." % consumable.duration)
			if consumable.addiction > 0:
				parts.append("Addiction threshold: %s." % consumable.addiction)
			if consumable.alcoholic:
				parts.append("This item is alcoholic.")
			return " ".join(parts)
		"Utility":
			var utility := item as Utility
			if utility == null:
				return ""
			var utility_parts: Array[String] = []
			if not utility.category.is_empty():
				utility_parts.append("Category: %s." % utility.category)
			if not utility.effect.is_empty():
				utility_parts.append("Effect: %s." % utility.effect)
			return " ".join(utility_parts)
		"Weapon":
			var weapon := item as Weapon
			if weapon == null:
				return ""
			var qualities := ""
			if not weapon.qualities.is_empty():
				qualities = " Qualities: %s." % ", ".join(weapon.qualities)
			return "Deals %s damage at speed %s.%s" % [weapon.damage_profile.describe(), weapon.speed, qualities]
	return ""

func _describe_item_slots(slots: Array[Item.ItemSlots]) -> String:
	var names: Array[String] = []
	for slot in slots:
		match slot:
			Item.ItemSlots.Head:
				names.append("the head")
			Item.ItemSlots.RightArm:
				names.append("the right arm")
			Item.ItemSlots.LeftArm:
				names.append("the left arm")
			Item.ItemSlots.Torso:
				names.append("the torso")
			Item.ItemSlots.RightLeg:
				names.append("the right leg")
			Item.ItemSlots.LeftLeg:
				names.append("the left leg")
			Item.ItemSlots.QuickItem:
				names.append("a quick-use slot")
			Item.ItemSlots.WeaponSlot:
				names.append("a weapon slot")
	if names.is_empty():
		return "no slots"
	if names.size() == 1:
		return names[0]
	return ", ".join(names.slice(0, names.size() - 1)) + " and " + names[names.size() - 1]

func _query(db: SQLite, sql: String) -> Array:
	if not db.query(sql):
		push_error("SQL query failed: %s" % sql)
		return []
	return db.query_result

func _rows_by_key(rows: Array, key: String) -> Dictionary:
	var result := {}
	for row in rows:
		result[_text(row, key)] = row
	return result

func _save_tres(resource: Resource, folder_name: String, resource_name: String) -> void:
	var path := "%s/%s/%s.tres" % [DATA_ROOT, folder_name, _safe_file_name(resource_name)]
	var error := ResourceSaver.save(resource, path)
	if error != OK:
		push_error("Failed saving %s (error %s)" % [path, error])
	elif log_progress:
		print("Saved %s" % path)

func _meta_text(keywords: Dictionary, key: String, field: String, fallback: String) -> String:
	if keywords.has(key):
		return str(keywords[key].get(field, fallback))
	return fallback

func _safe_file_name(value: String) -> String:
	return value.replace("/", "-").replace("\\", "-").replace(":", "").strip_edges()

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

func _parse_armor_slots(value: String) -> Array[Item.ItemSlots]:
	var slots: Array[Item.ItemSlots] = []
	for token in value.split(",", false):
		match token.strip_edges():
			"Head":
				slots.append(Item.ItemSlots.Head)
			"Torso":
				slots.append(Item.ItemSlots.Torso)
			"Arm Left", "Left Arm":
				slots.append(Item.ItemSlots.LeftArm)
			"Arm Right", "Right Arm":
				slots.append(Item.ItemSlots.RightArm)
			"Leg Left", "Left Leg":
				slots.append(Item.ItemSlots.LeftLeg)
			"Leg Right", "Right Leg":
				slots.append(Item.ItemSlots.RightLeg)
	return slots

func _parse_weapon_size(value: String) -> Weapon.WeaponSize:
	match value:
		"2H":
			return Weapon.WeaponSize.TWO_HANDED
		_:
			return Weapon.WeaponSize.ONE_HANDED

func _parse_weapon_range(value: String) -> Weapon.WeaponRange:
	match value:
		"C":
			return Weapon.WeaponRange.CLOSE
		"M":
			return Weapon.WeaponRange.MEDIUM
		"L":
			return Weapon.WeaponRange.LONG
		_:
			return Weapon.WeaponRange.MELEE
