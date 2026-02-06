extends ScrollContainer

@export var grid : GridContainer

func _ready() -> void:
	%CampaignManager.use_enet()
	_setup()
	for child in grid.get_children() :
		match child.name :
			"Name" : child.get_child(1).text = PlayerVariables.getName()
			"Gender" : child.get_child(1).text = PlayerVariables.getGender()
			"Age" : child.get_child(1).text = str(PlayerVariables.getAge())
			"Race" : 
				var rt = CampaignVariables.prepareLabel(RichTextLabel.new())
				rt.text = CampaignVariables.replaceText(PlayerVariables.getRace()._name)
				child.add_child(rt)
			"Homeland" : 
				var rt = CampaignVariables.prepareLabel(RichTextLabel.new())
				rt.text = CampaignVariables.replaceText(PlayerVariables.getHomeland()._name)
				child.add_child(rt)
			"Background" : 
				var rt = CampaignVariables.prepareLabel(RichTextLabel.new())
				rt.text = CampaignVariables.replaceText(PlayerVariables.getBackground()._name)
				child.add_child(rt)

func _setup() -> void:
	var box = VBoxContainer.new()
	box.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	box.custom_minimum_size = Vector2(400, 0)
	box.add_theme_constant_override("separation", 50)
	add_child(box)
	
	# Character Info
	_add_info(box, "Character Name: ", PlayerVariables.getName())
	_add_info(box, "Gender: ", PlayerVariables.getGender())
	_add_info(box, "Race: ", PlayerVariables.getRace())
	_add_info(box, "Homeland: ", PlayerVariables.getHomeland())
	_add_info(box, "Background: ", PlayerVariables.getBackground())

	# Backstory (multiline)
	var backstoryContainer = VBoxContainer.new()
	var backstoryLabel = Label.new()
	backstoryLabel.text = "Backstory:"
	backstoryLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	backstoryContainer.add_child(backstoryLabel)

	var backstoryValue = CampaignVariables.prepareLabel(RichTextLabel.new(), false)
	backstoryValue.text = PlayerVariables.getBackstory()
	backstoryContainer.add_child(backstoryValue)
	box.add_child(backstoryContainer)

func _add_info(parent: VBoxContainer, label_text: String, codexItem) -> void:
	var container = VBoxContainer.new()
	var lbl = Label.new()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(lbl)

	if codexItem is CodexItem:
		lbl.text = label_text + codexItem._name
		var rt = CampaignVariables.prepareLabel(RichTextLabel.new(), false)
		rt.text = CampaignVariables.replaceText(codexItem.long_description)
		container.add_child(rt)
	elif codexItem is String :
		lbl.text = label_text + codexItem
	
	parent.add_child(container)
