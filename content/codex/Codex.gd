extends Resource
class_name Codex

@export var Races: Dictionary[int, Race] = {}
@export var Backgrounds: Dictionary[int, Background] = {}
@export var Homelands: Dictionary[int, Homeland] = {}

@export var Attributes: Dictionary[int, Attribute] = {}
@export var Skills: Dictionary[int, Skill] = {}
@export var Defences: Dictionary[int, Defence] = {}

@export var Perks: Dictionary[int, Perk] = {}
@export var Conditions: Dictionary[int, Condition] = {}

@export var Modifiers: Dictionary[int, Modifier] = {}
@export var DamageOrigins: Dictionary[int, DamageOrigin] = {}
@export var DamageTypes: Dictionary[int, DamageType] = {}
@export var Effects: Dictionary[int, Effect] = {}
@export var Ranges: Dictionary[int, ActionRange] = {}

@export var Rules: Dictionary[int, Rule] = {}
@export var PlayerDataBlueprint: Dictionary[int, PlayerDataBlueprintEntry] = {}

@export var Actions: Dictionary[int, Action] = {}
@export var Attacks: Dictionary[int, Attack] = {}

@export var SpellSchools: Dictionary[int, SpellSchool] = {}
@export var Spells: Dictionary[int, Spell] = {}
@export var SpellVariants: Dictionary[int, SpellVariant] = {}

@export var Items: Dictionary[int, Item] = {}
@export var Weapons: Dictionary[int, Weapon] = {}
@export var ArmorItems: Dictionary[int, Armor] = {}
@export var ClothingItems: Dictionary[int, Clothing] = {}
@export var Consumables: Dictionary[int, Consumable] = {}
@export var Utilities: Dictionary[int, Utility] = {}

@export var StarterPacks: Dictionary[int, StarterPack] = {}
@export var WeaponQualities: Dictionary[int, WeaponQuality] = {}
@export var StrainResults: Dictionary[int, StrainResult] = {}

@export var NPCs: Dictionary[int, NPC] = {}

var Keywords: Dictionary
var orderedKeywords: Array[String]

func addToDictionary(dict: Dictionary, new_item: CodexItem) -> void:
	dict[new_item.id] = new_item


func get_by_id(dict: Dictionary, item_id: int) -> CodexItem:
	return dict.get(item_id, null)


func get_by_name(dict: Dictionary, item_name: String) -> CodexItem:
	var normalized_name := _normalize_lookup_name(item_name)
	for item in dict.values():
		if item is CodexItem and (item._name == item_name or _normalize_lookup_name(item._name) == normalized_name):
			return item
	return null


func get_rule(rule_name: String) -> Rule:
	return get_by_name(Rules, rule_name) as Rule


func get_player_data_blueprint(variable_name: String) -> PlayerDataBlueprintEntry:
	return get_by_name(PlayerDataBlueprint, variable_name) as PlayerDataBlueprintEntry


func get_sorted_names(dict: Dictionary) -> Array[String]:
	var names: Array[String] = []
	for item in dict.values():
		if item is CodexItem:
			names.append(item._name)
	names.sort()
	return names

func createKeywords() -> void:
	if Keywords == null:
		Keywords = {}
	else:
		Keywords.clear()

	for d in [Races, Backgrounds, Homelands, Attributes, Skills, Defences, Perks, Conditions, Modifiers, DamageOrigins, DamageTypes, Effects, Ranges, Rules, Actions, Attacks, SpellSchools, Spells, SpellVariants, Items, Weapons, ArmorItems, ClothingItems, Consumables, Utilities, StarterPacks, WeaponQualities, StrainResults, NPCs]:
		for item in d.values():
			if item is CodexItem:
				Keywords[item._name] = item
	orderedKeywords = []
	for keyword in Keywords.keys():
		orderedKeywords.append(str(keyword))
	orderedKeywords.sort_custom(func(a, b): return a.length() > b.length())


func _normalize_lookup_name(value: String) -> String:
	var normalized := value.strip_edges().to_lower()
	for separator in [" ", "-", "/", ":"]:
		normalized = normalized.replace(separator, "_")
	while normalized.contains("__"):
		normalized = normalized.replace("__", "_")
	return normalized.strip_edges()
