extends Node

var data: PlayerData
var expThreshold: int

signal leveledUp()
signal combat_loadout_changed()
signal vitals_changed()
signal handouts_changed()

func _ready() -> void:
	data = PlayerData.new()
	_ensure_valid_vitals(true)

func current() -> PlayerData:
	return data

func replace_data(value: PlayerData, refill_if_uninitialized: bool = true) -> void:
	data = value if value != null else PlayerData.new()
	data._ensure_handout_store()
	_ensure_valid_vitals(refill_if_uninitialized)
	handouts_changed.emit()
	combat_loadout_changed.emit()

func reset_current_player() -> void:
	replace_data(PlayerData.new())

func start_new_character(basic_actions: Array[Action] = []) -> void:
	var player := PlayerData.new()
	player.actions = basic_actions
	player.attribute_points = 29
	player.skill_points = 12
	player.perk_points = 3
	player.money = 300
	replace_data(player)

func apply_combatant_payload(payload: Dictionary) -> void:
	if data == null:
		return
	if payload.has("current_hp"):
		data.currentHP = float(payload.get("current_hp", data.currentHP))
	if payload.has("max_hp"):
		data.maxHP = float(payload.get("max_hp", data.maxHP))
	if payload.has("current_vitality"):
		data.currentVitality = float(payload.get("current_vitality", data.currentVitality))
	if payload.has("max_vitality"):
		data.maxVitality = float(payload.get("max_vitality", data.maxVitality))
	if payload.has("temporary_health"):
		data.temporaryHealth = float(payload.get("temporary_health", data.temporaryHealth))
	if payload.has("current_concentration"):
		data.currentConcentration = int(payload.get("current_concentration", data.currentConcentration))
	if payload.has("max_concentration"):
		data.maxConcentration = int(payload.get("max_concentration", data.maxConcentration))
	if payload.has("current_mana"):
		data.currentMana = int(payload.get("current_mana", data.currentMana))
	if payload.has("conditions"):
		var runtime_conditions: Array[Condition] = []
		for condition_name_variant in payload.get("conditions", []):
			var condition_name := str(condition_name_variant)
			if condition_name.is_empty():
				continue
			var condition: Condition = null
			if CampaignVariables.codex != null:
				condition = CampaignVariables.codex.Conditions.get(condition_name, null)
			if condition != null:
				runtime_conditions.append(condition.duplicate(true) as Condition)
			else:
				runtime_conditions.append(Condition.new(condition_name))
		data.conditions = runtime_conditions
	if payload.has("stunned_round"):
		var stunned_round := int(payload.get("stunned_round", -1))
		if stunned_round > 0:
			data.set_meta("stunned_round", stunned_round)
		else:
			data.remove_meta("stunned_round")
	if payload.has("stunned_resolve_speed"):
		var stunned_resolve_speed := int(payload.get("stunned_resolve_speed", 0))
		if stunned_resolve_speed > 0:
			data.set_meta("stunned_resolve_speed", stunned_resolve_speed)
		else:
			data.remove_meta("stunned_resolve_speed")
	if payload.has("stunned_spent_ap"):
		var stunned_spent_ap := int(payload.get("stunned_spent_ap", 0))
		if stunned_spent_ap > 0:
			data.set_meta("stunned_spent_ap", stunned_spent_ap)
		else:
			data.remove_meta("stunned_spent_ap")
	if payload.has("bleed_turns_remaining"):
		RuleEngine.setBleedTurnsRemaining(data, int(payload.get("bleed_turns_remaining", 0)))
	if payload.has("level"):
		data.level = int(payload.get("level", data.level))
	vitals_changed.emit()

func _ensure_valid_vitals(refill_if_uninitialized: bool = false) -> void:
	if data == null:
		return
	data.normalizeVitals(refill_if_uninitialized)
	vitals_changed.emit()

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

func getHandouts() -> Array[Dictionary]:
	return data.getHandouts()

func addOrUpdateHandout(title: String, text: String, shared_by: String, shared_at: String) -> Dictionary:
	var handout := data.addOrUpdateHandout(title, text, shared_by, shared_at)
	handouts_changed.emit()
	return handout

func deleteHandout(id: String) -> bool:
	var deleted := data.deleteHandout(id)
	if deleted:
		handouts_changed.emit()
	return deleted

func markHandoutRead(id: String) -> bool:
	var marked := data.markHandoutRead(id)
	if marked:
		handouts_changed.emit()
	return marked

# Attributes
func setAttributes(value: Array[Attribute]) -> void:
	data.attributes = value
	_ensure_valid_vitals(true)

func getAttributes() -> Array[Attribute]:
	return data.attributes

func getAttribute(value: String) -> Attribute:
	for att in data.attributes:
		if att._name == value:
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
	data.fatigue = value

func getFatigue() -> int:
	return data.fatigue

func addFatigue(value: int) -> void:
	data.fatigue += value

func setNecroticDamage(value: int) -> void:
	data.necroticDamage = value
	_ensure_valid_vitals()

func getNecroticDamage() -> int:
	return data.necroticDamage

func addNecroticDamage(value: int) -> void:
	data.necroticDamage += value
	_ensure_valid_vitals()

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
	_ensure_valid_vitals(true)

func setCurrentHP(value: float) -> void:
	data.currentHP = clampf(value, 0.0, data.maxHP)
	vitals_changed.emit()

func getCurrentHP() -> float:
	return data.currentHP

func setMaxHP(value: float) -> void:
	data.maxHP = maxf(value, 1.0)
	data.currentHP = clampf(data.currentHP, 0.0, data.maxHP)
	vitals_changed.emit()

func getMaxHP() -> float:
	return data.maxHP

func setCurrentVitality(value: float) -> void:
	data.currentVitality = clampf(value, 0.0, data.maxVitality)
	vitals_changed.emit()

func getCurrentVitality() -> float:
	return data.currentVitality

func setMaxVitality(value: float) -> void:
	data.maxVitality = maxf(value, 1.0)
	data.currentVitality = clampf(data.currentVitality, 0.0, data.maxVitality)
	vitals_changed.emit()

func getMaxVitality() -> float:
	return data.maxVitality

func setTemporaryHealth(value: float) -> void:
	data.temporaryHealth = maxf(value, 0.0)
	vitals_changed.emit()

func getTemporaryHealth() -> float:
	return data.temporaryHealth

func getLevel() -> int:
	return data.level

func setExperience(value: int) -> void:
	data.experience = value

func getExperience() -> int:
	return data.experience

func addExperience(value: int) -> void:
	if data.addExperienceWithThreshold(value, expThreshold):
		leveledUp.emit()
		vitals_changed.emit()

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
	data.levelUp()
	vitals_changed.emit()

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
		replace_data(resource)
	else:
		push_error("Save file %s is not a PlayerData resource" % file_path)

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

func _ensure_handout_store() -> void:
	if data != null:
		data._ensure_handout_store()

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
