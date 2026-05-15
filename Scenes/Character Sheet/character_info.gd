extends ScrollContainer

@export var grid: GridContainer

var content_box: VBoxContainer

func _ready() -> void:
	%CampaignManager.use_steam()
	_setup()
	resized.connect(_update_content_width)
	_update_content_width()
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
	content_box = VBoxContainer.new()
	content_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_box.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	content_box.custom_minimum_size = Vector2(400, 0)
	content_box.add_theme_constant_override("separation", 50)
	add_child(content_box)

	_add_info(content_box, "Character Name: ", player._name)
	_add_info(content_box, "Gender: ", player.gender)
	_add_info(content_box, "Race: ", player.race)

	var backstoryContainer := VBoxContainer.new()
	backstoryContainer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var backstoryLabel := Label.new()
	backstoryLabel.text = "Backstory:"
	backstoryLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	backstoryContainer.add_child(backstoryLabel)

	var backstoryValue := Label.new()
	backstoryValue.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	backstoryValue.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	backstoryValue.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	backstoryValue.text = player.backstory
	backstoryContainer.add_child(backstoryValue)
	content_box.add_child(backstoryContainer)

func _update_content_width() -> void:
	if content_box == null:
		return
	content_box.custom_minimum_size.x = maxf(size.x, 400.0)

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
