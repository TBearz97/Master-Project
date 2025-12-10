extends Node

var data : PlayerData
var expThreshold : int

signal leveledUp()

func _ready() -> void:
	data = PlayerData.new()

# Character Info
func setName(value: String) -> void:
	data.character_name = value

func getName() -> String:
	return data.character_name

func setGender(value: String) -> void:
	data.gender = value

func getGender() -> String:
	return data.gender

func setAge(value: int) -> void:
	data.age = value

func getAge() -> int:
	return data.age

func setRace(value: String) -> void:
	data.race = value

func getRace() -> String:
	return data.race

func setHomeland(value: String) -> void:
	data.homeland = value

func getHomeland() -> String:
	return data.homeland

func setBackground(value: String) -> void:
	data.background = value

func getBackground() -> String:
	return data.background

func setBackstory(value: String) -> void:
	data.backstory = value

func getBackstory() -> String:
	return data.backstory


# Attributes
func setAttributes(value: Array) -> void:
	data.attributes = value

func getAttributes() -> Array:
	return data.attributes

func getAttribute(value : String) -> Attribute:
	for att in data.attributes :
		if att._name == value :
			return att
	return null

# Skills
func setSkills(value: Array) -> void:
	data.skills = value

func getSkills() -> Array:
	return data.skills

func getSkill(value : String) -> Skill:
	for sk in data.skills :
		if sk._name == value :
			return sk
	return null

#Conditions
func setFatigue(value: int) -> void:
	data.fatigue = value

func getFatigue() -> int :
	return data.fatigue

func addFatigue(value : int) -> void:
	data.fatigue += value

func setNecroticDamage(value : int) -> void:
	data.necroticDamage = value

func getNecroticDamage() -> int :
	return data.necroticDamage

func addNecroticDamage(value : int) -> void:
	data.necroticDamage += value

func setConditions(value : Array[Condition]) -> void:
	data.conditions = value

func getConditions() -> Array[Condition] :
	return data.conditions

func addConditions(value : Condition) -> void:
	data.conditions.append(value)

# Perks
func setPerks(value: Array[Perk]) -> void:
	data.perks = value

func getPerks() -> Array:
	return data.perks

func addPerk(value : Perk) -> void:
	data.perks.append(value)

# Inventory
func setInventory(value: Dictionary) -> void:
	data.inventory = value

func getInventory() -> Dictionary:
	return data.inventory

func addToInventory(value : Item) -> void:
	if data.inventory.has(value._name) :
		data.inventory[value._name] = [value]
	else :
		data.inventory[value._name].append(value)

func setEquipment(value : Equipment) -> void:
	data.equipment = value

func getEquipment () -> Equipment :
	return data.equipment

# Money
func setMoney(value: int) -> void:
	data.money = value

func getMoney() -> int:
	return data.money

func addMoney(value : int) -> void:
	data.money += value

# Level Up
func setLevelAvailable(value : bool) -> void:
	data.levelAvailable = value

func getLevelAvailable() -> bool:
	return data.levelAvailable

func setLevel(value: int) -> void:
	data.level = value

func getLevel() -> int:
	return data.level

func setExperience(value : int) -> void:
	data.experience = value

func getExperience() -> int :
	return data.experience

func addExperience(value : int) -> void:
	data.experience += value
	if data.experience > expThreshold :
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

func calucalte_Defence (att1 : int, att2 : int):
	return att1 + att2

func level_Up() -> void :
	emit_signal("leveledUp")
	data.levelAvailable = true
	data.level += 1
	data.attribute_points += 1
	data.skill_points += 2
	data.perk_points += 1

func save() -> void:
	var path = "user://characters/" + data.character_name + ".res"
	var err = ResourceSaver.save(data, path)
	if err != OK:
		push_error("Failed to save player data. Error code: %s" % err)

func load(_name : String) :
	var path = "user://characters/" + _name + ".res"
	data = ResourceLoader.load(path)
	if not FileAccess.file_exists(path):
		push_error("File %s does not exist" % path)

	var res := ResourceLoader.load(path)
	if res is PlayerData:
		data = res
	else:
		push_error("Save file %s is not a PlayerData resource" % path)

func print_character_info() -> void:
	print("Character Info")
	print("Name: ", data.character_name)
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
