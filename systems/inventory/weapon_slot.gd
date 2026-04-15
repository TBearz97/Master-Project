extends ItemSlot

enum WeaponSets { Primary, Secondary, Tertiary, Quaternary }
enum WeaponSlot { Left, Right }

@export var weaponSet: WeaponSets
@export var slot: WeaponSlot

func _ready() -> void:
	var slots := Item.ItemSlots
	if item_slot != Item.ItemSlots.WeaponSlot:
		return
	var equipment := PlayerVariables.getEquipment()
	match item_slot:
		slots.WeaponSlot:
			if weaponSet == WeaponSets.Primary:
				if slot == WeaponSlot.Left:
					add_to_group("Weapon Set 1")
					set_item(equipment.weapon1Left)
				if slot == WeaponSlot.Right:
					add_to_group("Weapon Set 1")
					set_item(equipment.weapon1Right)
			if weaponSet == WeaponSets.Secondary:
				if slot == WeaponSlot.Left:
					add_to_group("Weapon Set 2")
					set_item(equipment.weapon2Left)
				if slot == WeaponSlot.Right:
					add_to_group("Weapon Set 2")
					set_item(equipment.weapon2Right)

func _get_weapon_set_slots(equipment: Equipment) -> Array[Weapon]:
	if weaponSet == WeaponSets.Primary:
		return [equipment.weapon1Left, equipment.weapon1Right]
	return [equipment.weapon2Left, equipment.weapon2Right]

func _set_weapon_set_slots(equipment: Equipment, left_weapon: Weapon, right_weapon: Weapon) -> void:
	if weaponSet == WeaponSets.Primary:
		equipment.weapon1Left = left_weapon
		equipment.weapon1Right = right_weapon
		return
	equipment.weapon2Left = left_weapon
	equipment.weapon2Right = right_weapon

func _apply_item_to_projected_equipment(equipment: Equipment, item: Item) -> void:
	var set_slots := _get_weapon_set_slots(equipment)
	var left_weapon := set_slots[0]
	var right_weapon := set_slots[1]
	var current_weapon: Weapon = left_weapon if slot == WeaponSlot.Left else right_weapon
	if current_weapon != null and current_weapon.size == Weapon.WeaponSize.TWO_HANDED:
		left_weapon = null
		right_weapon = null
	if item is Weapon and item.size == Weapon.WeaponSize.TWO_HANDED:
		left_weapon = item
		right_weapon = item
	else:
		if slot == WeaponSlot.Left:
			left_weapon = item as Weapon
		else:
			right_weapon = item as Weapon
	_set_weapon_set_slots(equipment, left_weapon, right_weapon)

@warning_ignore("unused_parameter")
func set_item(item: Item, recursion: bool = false) -> void:
	super.set_item(item)
	var slots := Item.ItemSlots
	if item_slot != Item.ItemSlots.WeaponSlot:
		return
	var equipment := PlayerVariables.getEquipment()
	match item_slot:
		slots.WeaponSlot:
			if weaponSet == WeaponSets.Primary:
				if slot == WeaponSlot.Left:
					equipment.weapon1Left = item
				if slot == WeaponSlot.Right:
					equipment.weapon1Right = item
			if weaponSet == WeaponSets.Secondary:
				if slot == WeaponSlot.Left:
					equipment.weapon2Left = item
				if slot == WeaponSlot.Right:
					equipment.weapon2Right = item
	if item != null and not recursion:
		if item is Weapon and item.size == Weapon.WeaponSize.TWO_HANDED:
			var other_slots = get_tree().get_nodes_in_group("Weapon Set 1") if get_tree().get_nodes_in_group("Weapon Set 1").has(self) else get_tree().get_nodes_in_group("Weapon Set 2")
			for slt in other_slots:
				if slt != self:
					if slt.equipped != null and inventory != null:
						if slt.equipped.size == Weapon.WeaponSize.ONE_HANDED:
							inventory._add_item(slt.equipped)
					slt.set_item(item, true)
	PlayerVariables.notify_combat_loadout_changed()
