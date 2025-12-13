extends "res://Scripts/Inventory/item_slot.gd"


@export_enum("1", "2", "3", "4") var slot: int = 1

func _ready() -> void:
	var slots = Item.ItemSlots
	if item_slot != Item.ItemSlots.QuickItem:
		return
	var equipment = PlayerVariables.getEquipment()
	match item_slot:
		slots.QuickItem :
			match slot :
				0 : set_item(equipment.quickItem1) 
				1 : set_item(equipment.quickItem2)
				2 : set_item(equipment.quickItem3)
				3 : set_item(equipment.quickItem4)

@warning_ignore("unused_parameter")
func set_item(item: Item, recursion: bool = false) -> void:
	super.set_item(item)
	var slots = Item.ItemSlots
	if item_slot != Item.ItemSlots.QuickItem:
		return
	var equipment = PlayerVariables.getEquipment()
	match item_slot:
		slots.QuickItem :
			match slot :
				0 : equipment.quickItem1 = item
				1 : equipment.quickItem2 = item
				2 : equipment.quickItem3 = item
				3 : equipment.quickItem4 = item
