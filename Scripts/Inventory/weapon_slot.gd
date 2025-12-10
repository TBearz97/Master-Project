extends "res://Scripts/Inventory/item_slot.gd"

enum weaponSets {Primary, Secondary, Tertiary, Quaternary}
enum weaponSlot {Left, Right}

@export var weaponSet : weaponSets
@export var slot : weaponSlot

func _ready() -> void:
	var slots = Item.ItemSlots
	if item_slot != Item.ItemSlots.WeaponSlot:
		return
	var equipment = PlayerVariables.getEquipment()
	match item_slot:
		slots.WeaponSlot :
			if weaponSet == weaponSets.Primary :
				if slot == weaponSlot.Left :
					set_item(equipment.weapon1Left) 
				if slot == weaponSlot.Right :
					set_item(equipment.weapon1Right) 
			if weaponSet == weaponSets.Secondary :
				if slot == weaponSlot.Left :
					set_item(equipment.weapon2Left) 
				if slot == weaponSlot.Right :
					set_item(equipment.weapon2Right) 

@warning_ignore("unused_parameter")
func set_item(item: Item, recursion: bool = false) -> void:
	super.set_item(item)
	var slots = Item.ItemSlots
	if item_slot != Item.ItemSlots.WeaponSlot:
		return
	var equipment = PlayerVariables.getEquipment()
	match item_slot:
		slots.WeaponSlot :
			if weaponSet == weaponSets.Primary :
				if slot == weaponSlot.Left :
					equipment.weapon1Left = item
				if slot == weaponSlot.Right :
					equipment.weapon1Right = item
			if weaponSet == weaponSets.Secondary :
				if slot == weaponSlot.Left :
					equipment.weapon2Left = item
				if slot == weaponSlot.Right :
					equipment.weapon2Right = item
