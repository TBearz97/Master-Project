extends ItemList




func _get_drag_data(_at_position: Vector2) -> Variant:
	var idx = get_selected_items()
	var icon = TextureRect.new()
	icon.texture = get_item_icon(idx[0])
	icon.set_meta("Slot", "LeftArm")
	set_drag_preview(icon)
	return icon
