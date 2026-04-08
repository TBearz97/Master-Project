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

func _ensure_valid_vitals(refill_if_uninitialized: bool = false) -> void:
	if data == null:
		return
	RuleEngine.normalizeVitals(data, refill_if_uninitialized)
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
	_ensure_handout_store()
	return data.handouts.duplicate(true)

func addOrUpdateHandout(title: String, text: String, shared_by: String, shared_at: String) -> Dictionary:
	_ensure_handout_store()
	var normalized_title := title.strip_edges()
	if normalized_title.is_empty():
		return {}

	for index in range(data.handouts.size()):
		var existing := data.handouts[index] as Dictionary
		if str(existing.get("title", "")) != normalized_title:
			continue
		existing["text"] = text
		existing["shared_by"] = shared_by
		existing["shared_at"] = shared_at
		existing["unread"] = true
		data.handouts[index] = existing
		handouts_changed.emit()
		return existing.duplicate(true)

	var handout := {
		"id": "%s_%s" % [normalized_title, str(Time.get_ticks_msec())],
		"title": normalized_title,
		"text": text,
		"shared_by": shared_by,
		"shared_at": shared_at,
		"unread": true,
	}
	data.handouts.append(handout)
	handouts_changed.emit()
	return handout.duplicate(true)

func deleteHandout(id: String) -> bool:
	_ensure_handout_store()
	for index in range(data.handouts.size()):
		var existing := data.handouts[index] as Dictionary
		if str(existing.get("id", "")) != id:
			continue
		data.handouts.remove_at(index)
		handouts_changed.emit()
		return true
	return false

func markHandoutRead(id: String) -> bool:
	_ensure_handout_store()
	for index in range(data.handouts.size()):
		var existing := data.handouts[index] as Dictionary
		if str(existing.get("id", "")) != id:
			continue
		if not bool(existing.get("unread", false)):
			return false
		existing["unread"] = false
		data.handouts[index] = existing
		handouts_changed.emit()
		return true
	return false

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

func setCurrentHP(value: int) -> void:
	data.currentHP = clampi(value, 0, data.maxHP)
	vitals_changed.emit()

func getCurrentHP() -> int:
	return data.currentHP

func setMaxHP(value: int) -> void:
	data.maxHP = maxi(value, 1)
	data.currentHP = clampi(data.currentHP, 0, data.maxHP)
	vitals_changed.emit()

func getMaxHP() -> int:
	return data.maxHP

func setCurrentVitality(value: int) -> void:
	data.currentVitality = clampi(value, 0, data.maxVitality)
	vitals_changed.emit()

func getCurrentVitality() -> int:
	return data.currentVitality

func setMaxVitality(value: int) -> void:
	data.maxVitality = maxi(value, 1)
	data.currentVitality = clampi(data.currentVitality, 0, data.maxVitality)
	vitals_changed.emit()

func getMaxVitality() -> int:
	return data.maxVitality

func setTemporaryHealth(value: int) -> void:
	data.temporaryHealth = maxi(value, 0)
	vitals_changed.emit()

func getTemporaryHealth() -> int:
	return data.temporaryHealth

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
	_ensure_valid_vitals(true)

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
		_ensure_handout_store()
		_ensure_valid_vitals(true)
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
	if data.handouts == null:
		data.handouts = []

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
