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
