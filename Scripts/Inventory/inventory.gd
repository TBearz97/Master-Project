extends ItemList

var inventory = PlayerVariables.getInventory()

func _ready() -> void:
	if !inventory.is_empty() :
		for item in inventory.values():
			add_item_from_resource(item[0])

func _add_item(item: Item) -> void:
	if inventory.has(item._name) :
		inventory[item._name].append(item)
		_update_item_row_in_list(item._name, inventory[item._name].size(), item)
	else :
		inventory[item._name] = [item]
		add_item_from_resource(item)

func add_item_from_resource(item: Item) -> void:
	var idx = add_item(item._name, item.icon)
	set_item_metadata(idx, item)
	set_item_tooltip(idx, item._print())
			
	var qty = inventory[item._name].size()
	var _size = add_item(str(qty))
	set_item_selectable(_size, false)
	set_item_disabled(_size, true)
	var _weight = add_item(str(item.weight * qty))
	set_item_selectable(_weight, false)
	set_item_disabled(_weight, true)
	var _value = add_item(str(item.value * qty))
	set_item_selectable(_value, false)
	set_item_disabled(_value, true)

func remove_item_from_inventory(item: Item, count: int = 1) -> void:
	if item == null:
		return
	if not inventory.has(item._name):
		return

	var stack: Array = inventory[item._name]

	if stack.is_empty():
		return

	var remove_count := mini(count, stack.size())
	for i in remove_count:
		stack.pop_back()

	if stack.is_empty():
		inventory.erase(item._name)
		_remove_item_row_from_list(item._name)
	else:
		_update_item_row_in_list(item._name, stack.size(), item)

func _remove_item_row_from_list(item_name: String) -> void:
	var base_index := _find_item_row_base_index(item_name)
	if base_index == -1:
		return

	# Remove 4 entries that belong to this item
	for i in range(4):
		remove_item(base_index)

func _update_item_row_in_list(item_name: String, qty: int, proto: Item) -> void:
	var base_index := _find_item_row_base_index(item_name)
	if base_index == -1:
		return

	# Column order: [name] [qty] [weight] [value]
	set_item_text(base_index + 1, str(qty))
	set_item_text(base_index + 2, str(proto.weight * qty))
	set_item_text(base_index + 3, str(proto.value * qty))

func _find_item_row_base_index(item_name: String) -> int:
	var count := get_item_count()
	var i := 0
	while i < count:
		if get_item_text(i) == item_name:
			return i
		i += 4   # skip to next logical row
	return -1

func _get_drag_data(at_position: Vector2) -> Variant:
	var idx := get_item_at_position(at_position)
	if idx == -1:
		return null

	# your logical row is 4 entries, so find the base index for this row
	var base := idx - (idx % 4)

	var item: Item = get_item_metadata(base)
	if item == null:
		return null

	var data := {
		"item": item,
		"source": "inventory",
		"inventory_list": self
	}

	var preview := TextureRect.new()
	preview.texture = item.icon
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	set_drag_preview(preview)

	return data


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if typeof(data) != TYPE_DICTIONARY:
		return false
	if not data.has("item"):
		return false
	var item = data["item"]
	return item is Item


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(_at_position, data):
		return

	var item: Item = data["item"]
	var source = data.get("source", "")

	if source == "slot":
		_handle_drop_from_slot(item, data)


func _handle_drop_from_slot(item: Item, data: Dictionary) -> void:
	var item_name := item._name

	# 1. Update backend inventory
	if not inventory.has(item_name):
		# New stack
		inventory[item_name] = [item]
		# Create a new row in the list
		add_item_from_resource(item)
	else:
		# Existing stack, increase quantity and update row
		var stack: Array = inventory[item_name]
		stack.append(item)
		_update_item_row_in_list(item_name, stack.size(), stack[0])

	# 2. Clear the source slot
	var from_slot = data.get("from_slot", null)
	if from_slot and "set_item" in from_slot:
		for itemSlot in item.allowed_slots :
			if item is Armor :
				for slot in get_tree().get_nodes_in_group("Armor Slots") :
					if slot.item_slot == itemSlot :
						slot.set_item(null)
			else :
				from_slot.set_item(null)
