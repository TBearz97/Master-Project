extends ScrollContainer

func _ready() -> void:
	if not PlayerVariables.perks_changed.is_connected(_rebuild):
		PlayerVariables.perks_changed.connect(_rebuild)
	_rebuild()

func _rebuild() -> void:
	for child in get_children():
		child.queue_free()

	var main := VBoxContainer.new()
	main.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	main.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	main.custom_minimum_size = Vector2(500, 0)
	main.add_theme_constant_override("separation", 20)
	add_child(main)

	var title := Label.new()
	title.text = "Perks"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	main.add_child(title)

	var perks: Array[Perk] = PlayerVariables.getAllPerks()
	if perks.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No perks selected."
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		main.add_child(empty_label)
		return

	for perk: Perk in perks:
		if perk == null:
			continue
		main.add_child(_build_perk_entry(perk))

func _build_perk_entry(perk: Perk) -> Control:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 6)

	var header := HBoxContainer.new()
	header.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var name_label := Label.new()
	name_label.text = perk._name
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header.add_child(name_label)

	var category_label := Label.new()
	category_label.text = perk.category
	category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	header.add_child(category_label)

	container.add_child(header)

	if not perk.short_description.is_empty():
		var short_label := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
		short_label.fit_content = true
		short_label.text = CampaignVariables.replaceText(perk.short_description)
		container.add_child(short_label)

	if not perk.long_description.is_empty():
		var long_label := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
		long_label.fit_content = true
		long_label.text = CampaignVariables.replaceText(perk.long_description)
		container.add_child(long_label)

	var divider := HSeparator.new()
	container.add_child(divider)
	return container
