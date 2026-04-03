extends Node

var data: PlayerData
var expThreshold: int

signal leveledUp()
signal combat_loadout_changed()

func _ready() -> void:
	data = PlayerData.new()
	_ensure_modifier_state()

# Character Info
func setName(value: String) -> void:
	data._name = value

func getName() -> String:
	return data._name

func setGender(value: String) -> void:
	data.gender = value

func getGender() -> String:
	return data.gender

func setAge(value: int) -> void:
	data.age = value

func getAge() -> int:
	return data.age

func setRace(value: Race) -> void:
	data.race = value

func getRace() -> Race:
	return data.race

func setHomeland(value: Homeland) -> void:
	data.homeland = value

func getHomeland() -> Homeland:
	return data.homeland

func setBackground(value: Background) -> void:
	data.background = value

func getBackground() -> Background:
	return data.background

func setBackstory(value: String) -> void:
	data.backstory = value

func getBackstory() -> String:
	return data.backstory

# Attributes
func setAttributes(value: Array[Attribute]) -> void:
	data.attributes = value

func getAttributes() -> Array[Attribute]:
	return data.attributes

func getAttribute(value: String) -> Attribute:
	for att in data.attributes:
		if att._name == value:
			return att
	return null

func getAttributeById(value: int) -> Attribute:
	for att in data.attributes:
		if att.id == value:
			return att
	return null

# Skills
func setSkills(value: Array[Skill]) -> void:
	data.skills = value

func getSkills() -> Array[Skill]:
	return data.skills

func getSkill(value: String) -> Skill:
	for sk in data.skills:
		if sk._name == value:
			return sk
	return null

# Conditions
func setFatigue(value: int) -> void:
	setBlueprintModifierValue("fatigue", value)

func getFatigue() -> int:
	return int(RuleEngine.resolve_player_variable("fatigue"))

func addFatigue(value: int) -> void:
	setFatigue(getFatigue() + value)

func setNecroticDamage(value: int) -> void:
	setBlueprintModifierValue("necrotic_damage", value)

func getNecroticDamage() -> int:
	return int(RuleEngine.resolve_player_variable("necrotic_damage"))

func addNecroticDamage(value: int) -> void:
	setNecroticDamage(getNecroticDamage() + value)

func getModifiers() -> Dictionary[int, Array[Modifier]]:
	_ensure_modifier_state()
	return data.modifiers

func hasModifierBucket(modifier_id: int) -> bool:
	_ensure_modifier_state()
	return data.modifiers.has(modifier_id) and not data.modifiers[modifier_id].is_empty()

func getModifierTotal(modifier_id: int, base_value: float = 0.0) -> float:
	_ensure_modifier_state()
	return data.get_modifier_total(modifier_id, base_value)

func getModifierTotalByName(modifier_name: String, base_value: float = 0.0) -> float:
	_ensure_modifier_state()
	var modifier_id := _get_modifier_id_by_name(modifier_name)
	if modifier_id < 0:
		return base_value
	return data.get_modifier_total(modifier_id, base_value)

func addModifier(modifier: Modifier) -> void:
	_ensure_modifier_state()
	if modifier == null:
		return
	data.add_modifier(modifier)
	_sync_legacy_field_for_modifier(modifier.id)

func clearModifierBucket(modifier_id: int) -> void:
	_ensure_modifier_state()
	data.clear_modifier_bucket(modifier_id)
	_sync_legacy_field_for_modifier(modifier_id)

func getDataField(field_name: String, default_value: Variant = null) -> Variant:
	if data == null or not _has_data_field(field_name):
		return default_value
	return data.get(field_name)

func setDataField(field_name: String, value: Variant) -> void:
	if data == null or not _has_data_field(field_name):
		return
	data.set(field_name, value)

func setBlueprintModifierValue(variable_name: String, value: int) -> void:
	_ensure_modifier_state()
	var entry := _get_blueprint_entry(variable_name)
	if entry == null or entry.source_type != PlayerDataBlueprintEntry.SourceType.MODIFIER:
		return
	_set_modifier_bucket_value(entry.source_id, value)
	_sync_legacy_field_for_modifier(entry.source_id)

func setConditions(value: Array[Condition]) -> void:
	data.conditions = value

func getConditions() -> Array[Condition]:
	return data.conditions

func addConditions(value: Condition) -> void:
	data.conditions.append(value)

# Perks
func setPerks(value: Array[Perk]) -> void:
	data.perks = value

func getPerks() -> Array[Perk]:
	return data.perks

func addPerk(value: Perk) -> void:
	data.perks.append(value)

# Inventory
func setInventory(value: Dictionary[String, Array]) -> void:
	data.inventory = value

func getInventory() -> Dictionary[String, Array]:
	return data.inventory

func addToInventory(value: Item) -> void:
	if not data.inventory.has(value._name):
		data.inventory[value._name] = [value]
	else:
		data.inventory[value._name].append(value)

func setEquipment(value: Equipment) -> void:
	data.equipment = value
	combat_loadout_changed.emit()

func getEquipment() -> Equipment:
	return data.equipment

func notify_combat_loadout_changed() -> void:
	# Inventory/weapon slot scripts call this after mutating equipment in place,
	# since those edits do not always flow through setEquipment().
	combat_loadout_changed.emit()

# Money
func setMoney(value: int) -> void:
	data.money = value

func getMoney() -> int:
	return data.money

func addMoney(value: int) -> void:
	data.money += value

# Level Up
func setLevelAvailable(value: bool) -> void:
	data.levelAvailable = value

func getLevelAvailable() -> bool:
	return data.levelAvailable

func setLevel(value: int) -> void:
	data.level = value

func getLevel() -> int:
	return data.level

func setExperience(value: int) -> void:
	data.experience = value

func getExperience() -> int:
	return data.experience

func addExperience(value: int) -> void:
	data.experience += value
	if data.experience > expThreshold:
		data.experience -= expThreshold
		level_Up()

func setAttributePoints(value: int) -> void:
	data.attribute_points = value

func getAttributePoints() -> int:
	return data.attribute_points

func setSkillPoints(value: int) -> void:
	data.skill_points = value

func getSkillPoints() -> int:
	return data.skill_points

func setPerkPoints(value: int) -> void:
	data.perk_points = value

func getPerkPoints() -> int:
	return data.perk_points

func level_Up() -> void:
	leveledUp.emit()
	data.levelAvailable = true
	data.level += 1
	data.attribute_points += 1
	data.skill_points += 2
	data.perk_points += 1

func save() -> void:
	if not _ensure_character_directory():
		return

	var file_path := "user://characters/%s.res" % data._name

	var result := ResourceSaver.save(data, file_path)
	if result != OK:
		push_error("Failed to save player data. Error code: %s" % result)

func load(character_name: String) -> void:
	if not _ensure_character_directory():
		return

	var file_path := "user://characters/%s.res" % character_name

	if not FileAccess.file_exists(file_path):
		push_error("File %s does not exist" % file_path)
		return

	var resource := ResourceLoader.load(file_path)
	if resource is PlayerData:
		data = resource
		_ensure_modifier_state()
	else:
		push_error("Save file %s is not a PlayerData resource" % file_path)

func _ensure_modifier_state() -> void:
	if data == null:
		data = PlayerData.new()
	if data.modifiers == null:
		data.modifiers = {}
	for entry in _get_blueprint_entries():
		if entry.source_type != PlayerDataBlueprintEntry.SourceType.MODIFIER:
			continue
		_backfill_modifier_from_legacy_field(entry)
		_sync_legacy_field_for_modifier(entry.source_id)

func _set_modifier_bucket_value(modifier_id: int, value: int) -> void:
	if modifier_id < 0:
		return
	var template: Modifier = CampaignVariables.codex.Modifiers.get(modifier_id, null)
	if template == null:
		return
	var runtime_modifier := template.duplicate(true) as Modifier
	runtime_modifier.value = value
	runtime_modifier.application_type = Modifier.ApplicationType.FLAT
	data.set_modifier_bucket(modifier_id, [runtime_modifier])

func _sync_legacy_field_for_modifier(modifier_id: int) -> void:
	if modifier_id < 0:
		return
	var entry := _get_blueprint_entry_by_modifier_id(modifier_id)
	if entry == null:
		return
	var field_name := _variable_to_field_name(entry._name)
	if not _has_data_field(field_name):
		return
	var total := data.get_modifier_total_int(modifier_id)
	data.set(field_name, total)

func _backfill_modifier_from_legacy_field(entry: PlayerDataBlueprintEntry) -> void:
	if entry == null or entry.source_id < 0 or data.modifiers.has(entry.source_id):
		return
	var field_name := _variable_to_field_name(entry._name)
	if not _has_data_field(field_name):
		return
	var fallback_value := int(data.get(field_name))
	if fallback_value == 0:
		return
	_set_modifier_bucket_value(entry.source_id, fallback_value)

func _get_blueprint_entries() -> Array[PlayerDataBlueprintEntry]:
	if CampaignVariables == null or CampaignVariables.codex == null:
		return []
	var entries: Array[PlayerDataBlueprintEntry] = []
	for entry: PlayerDataBlueprintEntry in CampaignVariables.codex.PlayerDataBlueprint.values():
		if entry != null and entry.enabled:
			entries.append(entry)
	entries.sort_custom(func(a: PlayerDataBlueprintEntry, b: PlayerDataBlueprintEntry) -> bool:
		return a.sort_order < b.sort_order
	)
	return entries

func _get_blueprint_entry(variable_name: String) -> PlayerDataBlueprintEntry:
	if CampaignVariables == null or CampaignVariables.codex == null:
		return null
	return CampaignVariables.codex.get_player_data_blueprint(variable_name)

func _get_blueprint_entry_by_modifier_id(modifier_id: int) -> PlayerDataBlueprintEntry:
	for entry in _get_blueprint_entries():
		if entry.source_type == PlayerDataBlueprintEntry.SourceType.MODIFIER and entry.source_id == modifier_id:
			return entry
	return null

func _get_modifier_id_by_name(modifier_name: String) -> int:
	if CampaignVariables == null or CampaignVariables.codex == null:
		return -1
	var modifier := CampaignVariables.codex.get_by_name(CampaignVariables.codex.Modifiers, modifier_name) as Modifier
	if modifier == null:
		return -1
	return modifier.id

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

func _has_data_field(field_name: String) -> bool:
	if data == null:
		return false
	for property_info in data.get_property_list():
		if str(property_info.get("name", "")) == field_name:
			return true
	return false

func _ensure_character_directory() -> bool:
	var directory := DirAccess.open("user://")
	if directory == null:
		push_error("Failed to open user:// directory")
		return false

	if directory.dir_exists("characters"):
		return true

	var result := directory.make_dir("characters")
	if result != OK:
		push_error("Failed to create characters directory. Error code: %s" % result)
		return false

	return true

func print_character_info() -> void:
	print("Character Info")
	print("Name: ", data._name)
	print("Gender: ", data.gender)
	print("Age: ", data.age)
	print("Race: ", data.race)
	print("Homeland: ", data.homeland)
	print("Background: ", data.background)
	print("Backstory: ", data.backstory)
	print("")

	print("Attributes")
	for p in data.attributes:
		print("  ", p._name + ": " + str(p.value))
	print("")

	print("Skills")
	for p in data.skills:
		print("  ", p._name + ": " + str(p.value))
	print("")

	print("Perks")
	for p in data.perks:
		print("  ", p._name)
	print("")

	print("Inventory")
	for i in data.inventory:
		print("  ", i + ": " + str(data.inventory[i].size()))
	print("")

	print("Money: ", data.money)
	print("")

	print("Level Up")
	print("  Level: ", data.level)
	print("  Attribute Points: ", data.attribute_points)
	print("  Skill Points: ", data.skill_points)
	print("  Perk Points: ", data.perk_points)
