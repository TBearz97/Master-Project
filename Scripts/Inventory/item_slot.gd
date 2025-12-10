extends Panel

@export var item_slot: Item.ItemSlots

@onready var icon: TextureRect = $Icon

var equipped: Item = null
var inventory : ItemList

func _ready() -> void:
	var slots = Item.ItemSlots
	var equipment = PlayerVariables.getEquipment()
	match item_slot:
		slots.Head:
			add_to_group("Armor Slots")
			set_item(equipment.head) 
		slots.RightArm:
			add_to_group("Armor Slots")
			set_item(equipment.rightArm)
		slots.LeftArm:
			add_to_group("Armor Slots")
			set_item(equipment.leftArm)
		slots.Torso:
			add_to_group("Armor Slots")
			set_item(equipment.torso)
		slots.RightLeg:
			add_to_group("Armor Slots")
			set_item(equipment.rightLeg)
		slots.LeftLeg:
			add_to_group("Armor Slots")
			set_item(equipment.leftLeg)

func set_item(item: Item, recursion: bool = false) -> void:
	var slots = Item.ItemSlots
	var equipment = PlayerVariables.getEquipment()
	equipped = item
	icon.texture = item.icon if item else null
	icon.tooltip_text = item._print() if item else ""
	match item_slot:
		slots.Head:
			equipment.head = item
		slots.RightArm:
			equipment.rightArm = item
		slots.LeftArm:
			equipment.leftArm = item
		slots.Torso:
			equipment.torso = item
		slots.RightLeg:
			equipment.rightLeg = item
		slots.LeftLeg:
			equipment.leftLeg = item
	if item != null and not recursion:
		if item.allowed_slots.size() > 1 :
			var other_slots = get_tree().get_nodes_in_group("Armor Slots")
			for slot in other_slots :
				for item_slots in item.allowed_slots :
					if slot.item_slot == item_slots :
						if slot.equipped != null and inventory != null :
							if slot.equipped.allowed_slots.size() == 1:
								inventory._add_item(slot.equipped)
						slot.set_item(item, true)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if equipped == null:
		return null

	var data := {
		"item": equipped,
		"source": "slot",
		"from_slot": self
	}

	var preview := TextureRect.new()
	preview.texture = equipped.icon
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item"):
		return false

	var item = data["item"]
	if not item is Item:
		return false

	# only allow items that can go into this slot
	return item_slot in item.allowed_slots


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	
	var item: Item = data["item"]
	var previous := equipped
	
	var source = data.get("source", "")

	if source == "slot":
		# dragged from another equipment slot, so swap
		var source_slot: Node = data["from_slot"]
		if "set_item" in source_slot:
			source_slot.set_item(previous)

	elif source == "inventory":
		# dragged from ItemList, so remove one from backend + list
		inventory = data.get("inventory_list")
		if inventory and "remove_item_from_inventory" in inventory:
			inventory.remove_item_from_inventory(item, 1)
		if previous != null :
			inventory._add_item(previous)
			if previous.allowed_slots.size() > 1 :
				if previous is Armor :
					for slots in get_tree().get_nodes_in_group("Armor Slots") :
						if previous.allowed_slots.has(slots.item_slot) :
							slots.set_item(null)
		else :
			var done = false
			if item.allowed_slots.size() > 1:
				for itemSlot in item.allowed_slots:
					for slots in get_tree().get_nodes_in_group("Armor Slots"):
						if itemSlot == slots.item_slot and slots.equipped != null:
							inventory._add_item(slots.equipped)
							done = true
							break
					if done:
						break

	
	set_item(item)

	
