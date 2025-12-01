extends ScrollContainer

@export var grid : GridContainer

func _ready() -> void:
	_setup()
	for child in grid.get_children() :
		match child.name :
			"Name" : child.get_child(1).text = PlayerVariables.getName()
			"Gender" : child.get_child(1).text = PlayerVariables.getGender()
			"Age" : child.get_child(1).text = str(PlayerVariables.getAge())
			"Race" : 
				var rt = DbHelper.prepareLabel(RichTextLabel.new())
				rt.text = DbHelper.replaceText(PlayerVariables.getRace())
				child.add_child(rt)
			"Homeland" : 
				var rt = DbHelper.prepareLabel(RichTextLabel.new())
				rt.text = DbHelper.replaceText(PlayerVariables.getHomeland())
				child.add_child(rt)
			"Background" : 
				var rt = DbHelper.prepareLabel(RichTextLabel.new())
				rt.text = DbHelper.replaceText(PlayerVariables.getBackground())
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

	var backstoryValue = DbHelper.prepareLabel(RichTextLabel.new(), false)
	backstoryValue.text = PlayerVariables.getBackstory()
	backstoryContainer.add_child(backstoryValue)
	box.add_child(backstoryContainer)

func _add_info(parent: VBoxContainer, label_text: String, value_text: String) -> void:
	var container = VBoxContainer.new()
	var lbl = Label.new()
	lbl.text = label_text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(lbl)

	var val = Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(val)
	
	var table = label_text.split(": ")
	if table[0] != "Gender" and table[0] != "Character Name":
		var query = 'SELECT * FROM ' + table[0] + ' WHERE name = "' + value_text + '"'
		var rows = DbHelper.db_fetch(query)
		var rt = DbHelper.prepareLabel(RichTextLabel.new(), false)
		rt.text = DbHelper.replaceText(rows[0]["long_description"])
		container.add_child(rt)
	parent.add_child(container)
