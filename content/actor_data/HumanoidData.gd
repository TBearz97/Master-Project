extends CreatureData
class_name HumanoidData

@export var skills: Array[Skill]
@export var equipment: Equipment
@export var race: Race
@export var homeland: Homeland
@export var background: Background

func _init() -> void:
	super()
	skills = []
	equipment = Equipment.new()
	race = Race.new()
	homeland = Homeland.new()
	background = Background.new()

func get_available_actions(loadout: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_weapons: Array[Weapon] = []
	for action in actions:
		result.append({"action": action, "weapon": null, "hand": "Innate"})
	var slots: Array[Dictionary] = []
	match loadout:
		1:
			slots = [
				{"weapon": equipment.weapon1Right, "hand": "Right Hand"},
				{"weapon": equipment.weapon1Left, "hand": "Left Hand"},
			]
		2:
			slots = [
				{"weapon": equipment.weapon2Right, "hand": "Right Hand"},
				{"weapon": equipment.weapon2Left, "hand": "Left Hand"},
			]
		_:
			slots = [
				{"weapon": equipment.weapon1Right, "hand": "Right Hand"},
				{"weapon": equipment.weapon1Left, "hand": "Left Hand"},
				{"weapon": equipment.weapon2Right, "hand": "Right Hand"},
				{"weapon": equipment.weapon2Left, "hand": "Left Hand"},
			]
	for slot_data in slots:
		var weapon: Weapon = slot_data.get("weapon", null)
		var hand := str(slot_data.get("hand", "Unknown Hand"))
		if weapon == null or weapon._name.is_empty():
			continue
		# Two-handed weapons occupy both slot references, so only expose their
		# actions once and mark the hand source accordingly.
		if seen_weapons.has(weapon):
			continue
		seen_weapons.append(weapon)
		if weapon.size == Weapon.WeaponSize.TWO_HANDED:
			hand = "Two-Handed"
		for action in weapon.actions:
			result.append({"action": action, "weapon": weapon, "hand": hand})
	return result
