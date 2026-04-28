extends CreatureData
class_name BeastData

@export var equipment: Equipment

func _init() -> void:
	super()
	equipment = Equipment.new()

func get_available_actions(loadout: int = 0) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var seen_weapons: Array[Weapon] = []
	for action in actions:
		result.append({"action": action, "weapon": null, "hand": "Innate"})
	var slots: Array[Dictionary] = []
	match loadout:
		1:
			slots = [
				{"weapon": equipment.weapon1Right, "hand": "Right Side"},
				{"weapon": equipment.weapon1Left, "hand": "Left Side"},
			]
		2:
			slots = [
				{"weapon": equipment.weapon2Right, "hand": "Right Side"},
				{"weapon": equipment.weapon2Left, "hand": "Left Side"},
			]
		_:
			slots = [
				{"weapon": equipment.weapon1Right, "hand": "Right Side"},
				{"weapon": equipment.weapon1Left, "hand": "Left Side"},
				{"weapon": equipment.weapon2Right, "hand": "Right Side"},
				{"weapon": equipment.weapon2Left, "hand": "Left Side"},
			]
	for slot_data in slots:
		var weapon: Weapon = slot_data.get("weapon", null)
		var hand := str(slot_data.get("hand", "Unknown Side"))
		if weapon == null or weapon._name.is_empty():
			continue
		if seen_weapons.has(weapon):
			continue
		seen_weapons.append(weapon)
		if weapon.size == Weapon.WeaponSize.TWO_HANDED:
			hand = "Whole Body"
		for action in weapon.actions:
			result.append({"action": action, "weapon": weapon, "hand": hand})
	return result
