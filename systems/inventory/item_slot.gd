extends Panel
class_name ItemSlot

@export var item_slot: Item.ItemSlots

@onready var DTReference: VBoxContainer = %Equipment
@onready var icon: TextureRect = $Icon

var equipped: Item = null
var inventory: ItemList
var _default_tooltip_text := ""

const DRAG_HINT_LAYER_NAME := "InventoryDragHintLayer"
const DRAG_HINT_PANEL_NAME := "InventoryDragHintPanel"
const DRAG_HINT_LABEL_NAME := "InventoryDragHintLabel"

func _is_real_item(item: Variant) -> bool:
	return item is Item and item._name != ""

func _refresh_tooltip() -> void:
	_default_tooltip_text = equipped._print() if equipped else ""
	tooltip_text = _default_tooltip_text
	icon.tooltip_text = _default_tooltip_text

func _show_drop_validation_reason(reason: String) -> void:
	tooltip_text = reason
	icon.tooltip_text = reason
	_show_drag_hint(reason)

func _get_drag_hint_panel() -> PanelContainer:
	var root := get_tree().root
	if root == null:
		return null
	var layer := root.get_node_or_null(DRAG_HINT_LAYER_NAME) as CanvasLayer
	if layer == null:
		layer = CanvasLayer.new()
		layer.name = DRAG_HINT_LAYER_NAME
		layer.layer = 100
		root.add_child(layer)
	var panel := layer.get_node_or_null(DRAG_HINT_PANEL_NAME) as PanelContainer
	if panel == null:
		panel = PanelContainer.new()
		panel.name = DRAG_HINT_PANEL_NAME
		panel.visible = false
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.z_index = 100
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.16, 0.07, 0.07, 0.95)
		style.border_color = Color(0.82, 0.24, 0.24, 1.0)
		style.set_border_width_all(1)
		style.set_corner_radius_all(6)
		style.set_content_margin_all(8)
		panel.add_theme_stylebox_override("panel", style)
		var label := Label.new()
		label.name = DRAG_HINT_LABEL_NAME
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(220, 0)
		label.add_theme_color_override("font_color", Color(1.0, 0.92, 0.92, 1.0))
		panel.add_child(label)
		layer.add_child(panel)
	return panel

func _show_drag_hint(reason: String) -> void:
	var panel := _get_drag_hint_panel()
	if panel == null:
		return
	var label := panel.get_node_or_null(DRAG_HINT_LABEL_NAME) as Label
	if label == null:
		return
	label.text = reason
	panel.visible = true
	_update_drag_hint_position()

func _hide_drag_hint() -> void:
	var panel := _get_drag_hint_panel()
	if panel != null:
		panel.visible = false

func _update_drag_hint_position() -> void:
	var panel := _get_drag_hint_panel()
	if panel == null or not panel.visible:
		return
	var mouse_position := get_viewport().get_mouse_position()
	panel.position = mouse_position + Vector2(18, 18)

func _covers_multiple_slots(item: Item) -> bool:
	return item is Clothing and item.allowed_slots.size() > 1

func _duplicate_equipment_shallow(source: Equipment) -> Equipment:
	var equipment_copy := Equipment.new()
	if source == null:
		return equipment_copy
	equipment_copy.head = source.head
	equipment_copy.torso = source.torso
	equipment_copy.leftArm = source.leftArm
	equipment_copy.rightArm = source.rightArm
	equipment_copy.leftLeg = source.leftLeg
	equipment_copy.rightLeg = source.rightLeg
	equipment_copy.weapon1Left = source.weapon1Left
	equipment_copy.weapon1Right = source.weapon1Right
	equipment_copy.weapon2Left = source.weapon2Left
	equipment_copy.weapon2Right = source.weapon2Right
	equipment_copy.quickItem1 = source.quickItem1
	equipment_copy.quickItem2 = source.quickItem2
	equipment_copy.quickItem3 = source.quickItem3
	equipment_copy.quickItem4 = source.quickItem4
	return equipment_copy

func _get_equipment_item(equipment: Equipment, slot_id: Item.ItemSlots) -> Item:
	if equipment == null:
		return null
	match slot_id:
		Item.ItemSlots.Head:
			return equipment.head
		Item.ItemSlots.RightArm:
			return equipment.rightArm
		Item.ItemSlots.LeftArm:
			return equipment.leftArm
		Item.ItemSlots.Torso:
			return equipment.torso
		Item.ItemSlots.RightLeg:
			return equipment.rightLeg
		Item.ItemSlots.LeftLeg:
			return equipment.leftLeg
		_:
			return null

func _set_equipment_item(equipment: Equipment, slot_id: Item.ItemSlots, item: Item) -> void:
	if equipment == null:
		return
	match slot_id:
		Item.ItemSlots.Head:
			equipment.head = item as Armor
		Item.ItemSlots.RightArm:
			equipment.rightArm = item as Armor
		Item.ItemSlots.LeftArm:
			equipment.leftArm = item as Armor
		Item.ItemSlots.Torso:
			equipment.torso = item as Armor
		Item.ItemSlots.RightLeg:
			equipment.rightLeg = item as Armor
		Item.ItemSlots.LeftLeg:
			equipment.leftLeg = item as Armor

func _clear_item_references(equipment: Equipment, item: Item) -> void:
	if equipment == null or item == null:
		return
	for slot_id: Item.ItemSlots in [Item.ItemSlots.Head, Item.ItemSlots.RightArm, Item.ItemSlots.LeftArm, Item.ItemSlots.Torso, Item.ItemSlots.RightLeg, Item.ItemSlots.LeftLeg]:
		if _get_equipment_item(equipment, slot_id) == item:
			_set_equipment_item(equipment, slot_id, null)

func _apply_item_to_projected_equipment(equipment: Equipment, item: Item) -> void:
	var current_item := _get_equipment_item(equipment, item_slot)
	if _covers_multiple_slots(current_item):
		_clear_item_references(equipment, current_item)
	if _covers_multiple_slots(item):
		for covered_slot: Item.ItemSlots in item.allowed_slots:
			var covered_item := _get_equipment_item(equipment, covered_slot)
			if _covers_multiple_slots(covered_item):
				_clear_item_references(equipment, covered_item)
		for covered_slot: Item.ItemSlots in item.allowed_slots:
			_set_equipment_item(equipment, covered_slot, item)
		return
	_set_equipment_item(equipment, item_slot, item)

func _build_projected_equipment(item: Item, data: Dictionary) -> Equipment:
	var projected := _duplicate_equipment_shallow(PlayerVariables.getEquipment())
	if str(data.get("source", "")) != "inventory":
		return projected
	_apply_item_to_projected_equipment(projected, item)
	return projected

func _would_exceed_equip_load(item: Item, data: Dictionary) -> bool:
	var projected := _build_projected_equipment(item, data)
	var projected_player := PlayerVariables.current().duplicate(true) as PlayerData
	if projected_player == null:
		return false
	projected_player.equipment = projected
	return not RuleEngine.canEquipWithinLoadLimit(projected_player)

func _ready() -> void:
	var slots := Item.ItemSlots
	var equipment := PlayerVariables.getEquipment()
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
	var slots := Item.ItemSlots
	var equipment := PlayerVariables.getEquipment()
	if not _is_real_item(item):
		item = null
	equipped = item
	icon.texture = item.icon if item else null
	_refresh_tooltip()
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
	if item != null and not recursion and _covers_multiple_slots(item):
		var other_slots = get_tree().get_nodes_in_group("Armor Slots")
		for slot in other_slots:
			for item_slots in item.allowed_slots:
				if slot.item_slot == item_slots:
					if _is_real_item(slot.equipped) and inventory != null:
						if not _covers_multiple_slots(slot.equipped):
							inventory._add_item(slot.equipped)
					slot.set_item(item, true)
	DTReference.recalculateDTs()
	if item_slot != Item.ItemSlots.WeaponSlot and item_slot != Item.ItemSlots.QuickItem:
		PlayerVariables.notify_combat_loadout_changed()

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not _is_real_item(equipped):
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
	_refresh_tooltip()

	return data


func _get_drop_validation(data: Variant) -> Dictionary:
	if typeof(data) != TYPE_DICTIONARY:
		return {"allowed": false, "reason": "Invalid drop data."}
	if not data.has("item"):
		return {"allowed": false, "reason": "Missing item data."}

	var item = data["item"]
	if not _is_real_item(item):
		return {"allowed": false, "reason": "Invalid item."}
	if not item_slot in item.allowed_slots:
		return {"allowed": false, "reason": "Cannot place that item in this slot."}
	if _would_exceed_equip_load(item, data):
		return {"allowed": false, "reason": "Would exceed max equip load."}

	return {"allowed": true, "reason": ""}


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var validation := _get_drop_validation(data)
	var allowed: bool = bool(validation.get("allowed", false))
	if allowed:
		_refresh_tooltip()
		_hide_drag_hint()
	else:
		_show_drop_validation_reason(str(validation.get("reason", "Cannot place item here.")))
	return allowed


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if not _can_drop_data(at_position, data):
		return
	
	var item: Item = data["item"]
	var previous := equipped
	
	var source = data.get("source", "")

	if source == "slot":
		var source_slot: Node = data["from_slot"]
		if "set_item" in source_slot:
			source_slot.set_item(previous)

	elif source == "inventory":
		inventory = data.get("inventory_list")
		if inventory and "remove_item_from_inventory" in inventory:
			inventory.remove_item_from_inventory(item, 1)
		if _is_real_item(previous):
			inventory._add_item(previous)
			if _covers_multiple_slots(previous):
				for slots in get_tree().get_nodes_in_group("Armor Slots"):
					if previous.allowed_slots.has(slots.item_slot):
						slots.set_item(null)
			if previous is Weapon:
				if previous.size == Weapon.WeaponSize.TWO_HANDED:
					var other_slots = get_tree().get_nodes_in_group("Weapon Set 1") if get_tree().get_nodes_in_group("Weapon Set 1").has(self) else get_tree().get_nodes_in_group("Weapon Set 2")
					for slt in other_slots:
						if slt != self:
							slt.set_item(null)

		else:
			var done = false
			if _covers_multiple_slots(item):
				for itemSlot in item.allowed_slots:
					for slots in get_tree().get_nodes_in_group("Armor Slots"):
						if itemSlot == slots.item_slot and _is_real_item(slots.equipped) and _covers_multiple_slots(slots.equipped):
							inventory._add_item(slots.equipped)
							done = true
							break
					if done:
						break
			if item is Weapon:
				if item.size == Weapon.WeaponSize.TWO_HANDED:
					var other_slots = get_tree().get_nodes_in_group("Weapon Set 1") if get_tree().get_nodes_in_group("Weapon Set 1").has(self) else get_tree().get_nodes_in_group("Weapon Set 2")
					for slots in other_slots:
						if slots != self and slots.equipped != null:
							inventory._add_item(slots.equipped)

	set_item(item)

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_refresh_tooltip()
		_hide_drag_hint()

func _process(_delta: float) -> void:
	_update_drag_hint_position()

	
