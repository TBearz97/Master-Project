extends ScrollContainer

@export var attGrid: GridContainer
@export var statGrid: GridContainer

var atts: Array[Attribute] = PlayerVariables.getAttributes()
var optionButton: OptionButton
var btns: Array[Button]

func _ready() -> void:
	var _attGrid := _setupAttHeader()
	var _statGrid := _setupStatHeader()
	_setup(_attGrid, _statGrid)
	_update_percentage(0)

func _setup(_grid: GridContainer, _grid2: GridContainer) -> void:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	container.custom_minimum_size = Vector2(400, 0)
	container.add_theme_constant_override("separation", 50)
	_setupAttributes(container, _grid)
	_setupSkills(container)

func _setupAttributes(main: VBoxContainer, _grid: GridContainer) -> void:
	var container := VBoxContainer.new()
	main.add_child(container)

	var attributeTitle := Label.new()
	attributeTitle.text = "Attributes"
	attributeTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attributeTitle.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(attributeTitle)
	container.add_child(_grid)
	
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	add_child(main)

	for child in _grid.get_children():
		var btn := Button.new()
		btn.text = child.get_child(1).text
		btn.set_meta("Value", child.get_child(1).text)
		btn.pressed.connect(func() -> void: print("Roll for " + child.get_child(0).text.split(']')[2].rstrip("[/color") + ": " + ("Succeeded" if skillCheck(int(child.get_child(1).text)) else "Failed")))
		child.remove_child(child.get_child(1))
		child.add_child(btn)
		btns.append(btn)

	for att in atts:
		var split := VSplitContainer.new()
		
		var bonus1 := CampaignVariables.prepareLabel(RichTextLabel.new())
		bonus1.text = _format_modifier_text(att, att.modifier_1, att.modifier_1_expression)

		var bonus2 := CampaignVariables.prepareLabel(RichTextLabel.new())
		bonus2.text = _format_modifier_text(att, att.modifier_2, att.modifier_2_expression)

		split.add_child(bonus1)
		split.add_child(bonus2)
		_grid.add_child(split)

func _setupSkills(main: VBoxContainer) -> void:
	var container := VBoxContainer.new()
	main.add_child(container)

	var attributeTitle := Label.new()
	attributeTitle.text = "Skills"
	attributeTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attributeTitle.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(attributeTitle)

	var difLable := Label.new()
	difLable.text = "Difficulty"
	difLable.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difLable.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(difLable)

	optionButton = OptionButton.new()
	optionButton.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	optionButton.item_selected.connect(_update_percentage)
	for type in RuleEngine.DiceType.values():
		optionButton.add_item(str(type))
	container.add_child(optionButton)

	for skill in PlayerVariables.getSkills():
		var split := HSplitContainer.new()
		split.dragging_enabled = false
		split.dragger_visibility = SplitContainer.DRAGGER_HIDDEN
		split.split_offset = 200
		split.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		split.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		split.custom_minimum_size = Vector2(300, 0)

		var lbl := CampaignVariables.prepareLabel(RichTextLabel.new())
		lbl.text = CampaignVariables.replaceText(skill._name)
		split.add_child(lbl)

		var btn := Button.new()
		btn.text = str(skill.value)
		btn.set_meta("Value", skill.value)
		btn.pressed.connect(func() -> void:
			%CampaignManager._add_combat_log("Roll for " + skill._name + ": " + ("Succeeded" if skillCheck(int(skill.value)) else "Failed"))
			)
		split.add_child(btn)
		btns.append(btn)

		container.add_child(split)

func _setupAttHeader() -> GridContainer:
	attGrid.columns = atts.size()
	for att in atts:
		var container := VSplitContainer.new()
		container.dragging_enabled = false
		container.dragger_visibility = SplitContainer.DRAGGER_HIDDEN

		var label := CampaignVariables.prepareLabel(RichTextLabel.new())
		label.text = CampaignVariables.replaceText(att._name)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(label)

		var value := Label.new()
		value.text = str(att.value)
		value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		container.add_child(value)

		attGrid.add_child(container)
	return attGrid.duplicate()

func _setupStatHeader() -> GridContainer:
	for child in statGrid.get_children():
		match child.name:
			"LevelUp":
				PlayerVariables.leveledUp.connect(func() -> void: child.disabled = !PlayerVariables.getLevelAvailable())
				child.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn"))
			_:
				if child.get_child_count() > 1:
					child.get_child(1).text = str(_resolve_stat_value(child.name))

	return statGrid.duplicate()

func _format_modifier_text(attribute: Attribute, modifier: Modifier, expression: String) -> String:
	if modifier == null or expression.is_empty():
		return ""
	return CampaignVariables.replaceText("%s %s" % [modifier._name, str(int(RuleEngine.evaluate_player_expression(expression, {"x": attribute.value})))])

func _resolve_stat_value(control_name: String) -> int:
	var variable_name := _control_name_to_variable_name(control_name)
	var blueprint_entry := CampaignVariables.codex.get_player_data_blueprint(variable_name)
	if blueprint_entry != null and blueprint_entry.enabled:
		return int(RuleEngine.resolve_player_variable(variable_name))
	var modifier_name := _humanize_control_name(control_name)
	var modifier := CampaignVariables.codex.get_by_name(CampaignVariables.codex.Modifiers, modifier_name) as Modifier
	if modifier != null:
		return int(RuleEngine.resolve_modifier_value(modifier.id))
	var getter_name := "get%s" % control_name
	if PlayerVariables.has_method(getter_name):
		return int(PlayerVariables.call(getter_name))
	return 0

func _control_name_to_variable_name(control_name: String) -> String:
	var variable_name := ""
	for i in range(control_name.length()):
		var character := control_name[i]
		var lower := character.to_lower()
		if i > 0 and character != lower and control_name[i - 1] != "_":
			variable_name += "_"
		variable_name += lower
	return variable_name

func _humanize_control_name(control_name: String) -> String:
	var variable_name := _control_name_to_variable_name(control_name)
	var parts := variable_name.split("_", false)
	for i in range(parts.size()):
		parts[i] = parts[i].capitalize()
	return " ".join(parts)

func skillCheck(skill: int) -> Variant:
	var difficulty := int(optionButton.get_item_text(optionButton.selected))
	var skill_check_rule := CampaignVariables.codex.get_rule("Skill Check")
	var expression := "rollDice(1, difficulty) <= skill"
	if skill_check_rule != null and not skill_check_rule.expression.is_empty():
		expression = skill_check_rule.expression
	return RuleEngine.evaluate(expression, ["difficulty", "skill"], [difficulty, skill])

func _update_percentage(idx: int) -> void:
	var difficulty := int(optionButton.get_item_text(idx))
	for btn in btns:
		var value: Variant = btn.get_meta("Value")
		_setTooltip(btn, str(value))
		var percentage: int = min(int((float(btn.get_meta("Value")) / float(difficulty)) * 100), 100)
		btn.text = str(value) + "	|	" + str(percentage) + "%"

func _setTooltip(btn: Button, value: String) -> void:
	var difficulty := int(optionButton.get_item_text(optionButton.selected))
	btn.tooltip_text = "You will roll a d" + str(difficulty) + ". If you roll lower or equal than you skill level of: " + str(value) + " then you succeed, else you fail."
