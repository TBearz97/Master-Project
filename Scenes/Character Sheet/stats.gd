extends ScrollContainer

@export var attGrid : GridContainer
@export var statGrid : GridContainer

var atts = PlayerVariables.getAttributes()
var optionButton : OptionButton
var btns : Array[Button]

func _ready() -> void:
	var _attGrid = _setupAttHeader()
	var _statGrid = _setupStatHeader()
	_setup(_attGrid, _statGrid)
	_update_percentage(0)

func _setup(_grid : GridContainer, _grid2 : GridContainer) :
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	container.custom_minimum_size = Vector2(400, 0)
	container.add_theme_constant_override("separation", 50)
	_setupAttributes(container, _grid)
	_setupSkills(container)

func _setupAttributes(main: VBoxContainer, _grid : GridContainer) :
	var container = VBoxContainer.new()
	main.add_child(container)
	
	var attributeTitle = Label.new()
	attributeTitle.text = "Attributes"
	attributeTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attributeTitle.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(attributeTitle)
	container.add_child(_grid)
	
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	add_child(main)
	
	for child in _grid.get_children() :
		var btn = Button.new()
		btn.text = child.get_child(1).text
		btn.set_meta("Value", child.get_child(1).text)
		btn.pressed.connect(func () : print("Roll for " + child.get_child(0).text.split(']')[2].rstrip("[/color") + ": " + ("Succeeded" if skillCheck(int(child.get_child(1).text)) else "Failed") ))
		child.remove_child(child.get_child(1))
		child.add_child(btn)
		btns.append(btn)
	
	for att in atts :
		var split = VSplitContainer.new()
		
		var bonus1 = CampaignVariables.prepareLabel(RichTextLabel.new())
		bonus1.text = CampaignVariables.replaceText(att.bonus_1_prefix + " " + str(RuleEngine.evaluate(att.bonus_1_expression, ["x"], [att.value])) + " " + att.bonus_1_suffix)
	
		var bonus2 = CampaignVariables.prepareLabel(RichTextLabel.new())
		bonus2.text = CampaignVariables.replaceText(att.bonus_2_prefix + " " + str(RuleEngine.evaluate(att.bonus_2_expression, ["x"], [att.value])) + " " + att.bonus_2_suffix)
		
		split.add_child(bonus1)
		split.add_child(bonus2)
		_grid.add_child(split)

func _setupSkills(main: VBoxContainer) :
	var container = VBoxContainer.new()
	main.add_child(container)
	
	var attributeTitle = Label.new()
	attributeTitle.text = "Skills"
	attributeTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attributeTitle.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(attributeTitle)
	
	var difLable = Label.new()
	difLable.text = "Difficulty"
	difLable.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difLable.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(difLable)
	
	optionButton = OptionButton.new()
	optionButton.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	optionButton.item_selected.connect(_update_percentage)
	for type in RuleEngine.DiceType.values() :
		optionButton.add_item(str(type))
	container.add_child(optionButton)
	
	for skill in PlayerVariables.getSkills() :
		var split = HSplitContainer.new()
		split.dragging_enabled = false
		split.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
		split.split_offset = 200
		split.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		split.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		split.custom_minimum_size = Vector2(300, 0)
		
		var lbl = CampaignVariables.prepareLabel(RichTextLabel.new())
		lbl.text = CampaignVariables.replaceText(skill._name)
		split.add_child(lbl)
		
		var btn = Button.new()
		btn.text = str(skill.value)
		btn.set_meta("Value", skill.value)
		btn.pressed.connect(func () : 
			%CampaignManager._add_combat_log(("Roll for " + skill._name + ": " + ("Succeeded" if skillCheck(int(skill.value)) else "Failed")))  
			)
		split.add_child(btn)
		btns.append(btn)
		
		container.add_child(split)

func _setupAttHeader() -> GridContainer:
	attGrid.columns = atts.size()
	for att in atts :
		var container = VSplitContainer.new()
		container.dragging_enabled = false
		container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
		
		var label = CampaignVariables.prepareLabel(RichTextLabel.new())
		label.text = CampaignVariables.replaceText(att._name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(label)
		
		var value = Label.new()
		value.text = str(att.value)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(value)
		
		attGrid.add_child(container)
	return attGrid.duplicate()

#NOT FLEXIBLE FOR DATABASE CHANGE
func _setupStatHeader() -> GridContainer:
	var health = 0
	for child in statGrid.get_children() :
		match child.name :
			"Level" : child.get_child(1).text = str(PlayerVariables.getLevel())
			"Health" : 
				var att = PlayerVariables.getAttribute("Constitution")
				health = (RuleEngine.evaluate(att.bonus_1_expression, ["x"], [att.value])) * PlayerVariables.getLevel() - PlayerVariables.getNecroticDamage()
				child.get_child(1).text = str(health)
			"ActionPoints" :
				var att = PlayerVariables.getAttribute("Dexterity")
				child.get_child(1).text = str((RuleEngine.evaluate(att.bonus_1_expression, ["x"], [att.value]) - PlayerVariables.getFatigue()))
			"Experience" : child.get_child(1).text = str(PlayerVariables.getExperience())
			"Vitality" : 
				var att = PlayerVariables.getAttribute("Constitution")
				child.get_child(1).text = str((RuleEngine.evaluate(att.bonus_2_expression, ["x"], [att.value]) * health + PlayerVariables.getNecroticDamage()))
			"Fatigue" : child.get_child(1).text = str(PlayerVariables.getFatigue())
			"LevelUp" : 
				PlayerVariables.leveledUp.connect(func (): child.disabled = !PlayerVariables.getLevelAvailable())
				child.pressed.connect(func (): get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn"))
			"NecroticDamage" : child.get_child(1).text = str(PlayerVariables.getNecroticDamage())
		
	return statGrid.duplicate()

func skillCheck (skill : int) :
	var difficulty = int(optionButton.get_item_text(optionButton.selected))
	return RuleEngine.evaluate(CampaignVariables.codex.Rules["Skill Check"].expression, ["difficulty", "skill"], [difficulty, skill])

func _update_percentage(idx : int) :
	var difficulty = int(optionButton.get_item_text(idx))
	for btn in btns :
		var value = btn.get_meta("Value")
		_setTooltip(btn, str(value))
		var percentage = min(int((float(btn.get_meta("Value")) / float(difficulty)) * 100), 100)
		btn.text = str(value) + "	|	" + str(percentage) + "%"

func _setTooltip(btn: Button, value: String) :
	var difficulty = int(optionButton.get_item_text(optionButton.selected))
	btn.tooltip_text = "You will roll a d" + str(difficulty) + ". If you roll lower or equal than you skill level of: " + str(value) + " then you succeed, else you fail."
