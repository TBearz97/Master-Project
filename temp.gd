extends Control

var temp : Codex = Codex.new()

func _ready() -> void:
	getAttribute()
	getPerk()
	getArmor()
	getBackground()
	getClothing()
	getConsumable()
	getDefence()
	getHomeland()
	getRace()
	getRule()
	getSkill()
	getUtility()
	getWeapon()
	
	var error = ResourceSaver.save(temp, ("res://data/baseRules.res"))
	print(error)
	
func getArmor():
	var rows = DbHelper.db_fetch("SELECT * FROM Armor")
	for row in rows:
		var obj = Armor.new(row["item"], "", "", row["weight"], row["cost"], row["armor_slot"], row["physical_dt"], row["magical_dt"], row["necrotic_dt"])
		temp.addToDictionary(temp.Items, obj)

func getAttribute():
	var rows = DbHelper.db_fetch("SELECT * FROM Attribute")
	for row in rows:
		var obj = Attribute.new(row["name"],  row["short_description"], row["long_description"], 0, row["bonus_1_prefix"], row["bonus_2_prefix"], row["bonus_1_expression"], row["bonus_2_expression"], row["bonus_1_suffix"], row["bonus_2_suffix"])
		temp.addToDictionary(temp.Attributes, obj)

func getPerk():
	var rows = DbHelper.db_fetch("SELECT * FROM Perk")
	for row in rows:
		var obj = Perk.new(row["name"], row["short_description"], row["long_description"], row["category"])
		temp.addToDictionary(temp.Perks, obj)

func getBackground():
	var rows = DbHelper.db_fetch(("SELECT * FROM Background"))
	for row in rows:
		var obj = Background.new(row["name"], row["short_description"], row["long_description"], findPerk(row["perk"]))
		temp.addToDictionary(temp.Backgrounds, obj)

func getClothing():
	var rows = DbHelper.db_fetch("SELECT * FROM Clothing")
	for row in rows:
		var obj = Clothing.new(row["item"], "", "", row["weight"], row["cost"], row["locations_covered"], 0, 0, 0, "")
		temp.addToDictionary(temp.Items, obj)

func getConsumable():
	var rows = DbHelper.db_fetch("SELECT * FROM Consumable")
	for row in rows:
		var obj = Consumable.new(row["item"], "", "", row["weight"], row["hp_healed"], str(row["effect"]), row["addiction_threshold"] if row["addiction_threshold"] != null else  0 ,  row["cost"])
		temp.addToDictionary(temp.Items, obj)
	
func getDefence():
	var rows = DbHelper.db_fetch("SELECT * FROM Defence")
	for row in rows:
		var obj = Defence.new(row["name"], "", "", findAttribute(row["attribute1"]), findAttribute(row["attribute2"]))
		temp.addToDictionary(temp.Defences, obj)

func getHomeland():
	var rows = DbHelper.db_fetch("SELECT * FROM Homeland")
	for row in rows:
		var obj = Homeland.new(row["name"], row["short_description"], row["long_description"], findPerk(row["perk"]))
		temp.addToDictionary(temp.Homelands, obj)

func getRace():
	var rows = DbHelper.db_fetch("SELECT * FROM Race")
	for row in rows:
		var obj = Race.new(row["name"], row["short_description"], row["long_description"], findPerk(row["perk"]))
		temp.addToDictionary(temp.Races, obj)

func getSkill():
	var rows = DbHelper.db_fetch("SELECT * FROM Skill")
	for row in rows:
		var obj = Skill.new(row["name"], row["short_description"], row["long_description"], 0)
		temp.addToDictionary(temp.Skills, obj)

func getUtility():
	var rows = DbHelper.db_fetch("SELECT * FROM Utility")
	for row in rows:
		var obj = Utility.new(row["item"], "", "", row["weight"], row["effect"],  row["cost"])
		temp.addToDictionary(temp.Items, obj)

func getWeapon():
	var rows = DbHelper.db_fetch("SELECT * FROM Weapon")
	for row in rows:
		var obj = Weapon.new(row["item"], "", "", row["weight"], row["cost"], row["damage_multiplier"], row["base_speed"], str(row["qualities"]), str(row["size"]), str(row["range"]))
		temp.addToDictionary(temp.Items, obj)
	
func getRule():
	var rows = DbHelper.db_fetch(("SELECT * FROM Rule"))
	for row in rows:
		var obj = Rule.new(row["name"], "", "", row["expression"])
		temp.addToDictionary(temp.Rules, obj)

func findAttribute(_name) -> Attribute:
	for a in temp.Attributes.values():
		if a._name == _name:
			return a
	return Attribute.new()

func findPerk(_name) -> Perk:
	for p in temp.Perks.values():
		if p._name == _name :
			return p
	return Perk.new()
