extends Panel

@onready var icon: TextureRect = $Icon


func _get_drag_data(_at_position: Vector2) -> Variant:
	if icon.texture == null :
		return
	
	var preview = duplicate()
	var c = Control.new()
	c.add_child(preview)
	preview.position -= Vector2(25, 25)
	preview.self_modulate = Color.TRANSPARENT
	c.modulate = Color(c.modulate, 0.5)
	
	set_drag_preview(c)
	return icon

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not icon.has_meta("Slot"):
		return false
	if not data.has_meta("Slot"):
		return false

	return icon.get_meta("Slot") == data.get_meta("Slot")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	var tmp = icon.texture
	icon.texture = data.texture
	data.texture = tmp
