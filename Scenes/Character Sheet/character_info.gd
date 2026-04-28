extends ScrollContainer

@export var grid: GridContainer

func _ready() -> void:
	%CampaignManager.use_steam()
	_setup()
	var player := PlayerVariables.current()
	for child in grid.get_children():
		match child.name:
			"Name": child.get_child(1).text = player._name
			"Gender": child.get_child(1).text = player.gender
			"Age": child.get_child(1).text = str(player.age)
			"Race":
				var rt := CampaignVariables.prepareLabel(RichTextLabel.new())
				rt.text = CampaignVariables.replaceText(player.race._name)
				child.add_child(rt)

func _setup() -> void:
	var player := PlayerVariables.current()
	var box := VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	box.custom_minimum_size = Vector2(400, 0)
	box.add_theme_constant_override("separation", 50)
	add_child(box)

	_add_info(box, "Character Name: ", player._name)
	_add_info(box, "Gender: ", player.gender)
	_add_info(box, "Race: ", player.race)

	var backstoryContainer := VBoxContainer.new()
	var backstoryLabel := Label.new()
	backstoryLabel.text = "Backstory:"
	backstoryLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	backstoryContainer.add_child(backstoryLabel)

	var backstoryValue := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
	backstoryValue.text = player.backstory
	backstoryContainer.add_child(backstoryValue)
	box.add_child(backstoryContainer)

func _add_info(parent: VBoxContainer, label_text: String, codexItem: Variant) -> void:
	var container := VBoxContainer.new()
	var lbl := Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(lbl)

	if codexItem is CodexItem:
		lbl.text = label_text + codexItem._name
		var rt := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
		rt.text = CampaignVariables.replaceText(codexItem.long_description)
		container.add_child(rt)
	elif codexItem is String:
		lbl.text = label_text + codexItem

	parent.add_child(container)
