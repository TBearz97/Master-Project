extends ScrollContainer

@export var attGrid: GridContainer
@export var statGrid: GridContainer

var atts: Array[Attribute] = PlayerVariables.getAttributes()
var btns: Array[Button]
var displayed_stat_grid: GridContainer

func _ready() -> void:
	var _attGrid := _setupAttHeader()
	var _statGrid := _setupStatHeader()
	displayed_stat_grid = _statGrid
	_setup(_attGrid, _statGrid)
	if not PlayerVariables.vitals_changed.is_connected(_refresh_stat_values):
		PlayerVariables.vitals_changed.connect(_refresh_stat_values)
	_refresh_stat_values()

func _setup(_grid: GridContainer, _grid2: GridContainer) -> void:
	var container := VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN
	container.custom_minimum_size = Vector2(400, 0)
	container.add_theme_constant_override("separation", 50)
	_setupAttributes(container, _grid)
	_setupStats(container, _grid2)
	_setupSkills(container)
	add_child(container)

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

	for child in _grid.get_children():
		var btn := Button.new()
		btn.text = child.get_child(1).text
		btn.set_meta("Value", child.get_child(1).text)
		btn.disabled = true
		btn.tooltip_text = "Attribute checks are not part of the GM skill-check flow."
		child.remove_child(child.get_child(1))
		child.add_child(btn)
		btns.append(btn)

	for att in atts:
		var split := VSplitContainer.new()
		
		var bonus1 := CampaignVariables.prepareLabel(RichTextLabel.new())
		bonus1.text = CampaignVariables.replaceText(att.bonus_1_prefix + " " + str(RuleEngine.evaluate(att.bonus_1_expression, ["x"], [att.value])) + " " + att.bonus_1_suffix)

		var bonus2 := CampaignVariables.prepareLabel(RichTextLabel.new())
		bonus2.text = CampaignVariables.replaceText(att.bonus_2_prefix + " " + str(RuleEngine.evaluate(att.bonus_2_expression, ["x"], [att.value])) + " " + att.bonus_2_suffix)

		split.add_child(bonus1)
		split.add_child(bonus2)
		_grid.add_child(split)

func _setupStats(main: VBoxContainer, _grid: GridContainer) -> void:
	var container := VBoxContainer.new()
	main.add_child(container)

	var stats_title := Label.new()
	stats_title.text = "Quick Info"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(stats_title)
	container.add_child(_grid)
	container.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.size_flags_vertical = Control.SIZE_EXPAND | Control.SIZE_SHRINK_BEGIN

func _setupSkills(main: VBoxContainer) -> void:
	var container := VBoxContainer.new()
	main.add_child(container)

	var attributeTitle := Label.new()
	attributeTitle.text = "Skills"
	attributeTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	attributeTitle.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(attributeTitle)

	var info_label := Label.new()
	info_label.text = "Click a skill to request or resolve a skill check."
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.size_flags_horizontal = Control.SIZE_EXPAND | Control.SIZE_SHRINK_CENTER
	container.add_child(info_label)

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
		btn.text = "Check (%s)" % skill.value
		btn.set_meta("Value", skill.value)
		btn.pressed.connect(_request_skill_check.bind(skill._name))
		_setSkillTooltip(btn, skill)
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
	var grid := statGrid.duplicate()
	for child in grid.get_children():
		if child.name == "LevelUp":
			PlayerVariables.leveledUp.connect(func() -> void: child.disabled = !PlayerVariables.getLevelAvailable())
			child.pressed.connect(func() -> void: get_tree().change_scene_to_file("res://Scenes/Character Sheet/Character_Sheet.tscn"))
			child.disabled = !PlayerVariables.getLevelAvailable()
	_refresh_stat_values(grid)
	return grid

func _refresh_stat_values(grid: GridContainer = displayed_stat_grid) -> void:
	if grid == null:
		return
	var max_health := RuleEngine.getMaxHealth(PlayerVariables.data)
	var max_vitality := RuleEngine.getMaxVitality(PlayerVariables.data)
	for child in grid.get_children():
		match child.name:
			"Level": child.get_child(1).text = str(PlayerVariables.getLevel())
			"Health":
				child.get_child(1).text = str(PlayerVariables.data.currentHP) + "/" + str(max_health)
			"ActionPoints":
				child.get_child(1).text = str(RuleEngine.getActionPoints(PlayerVariables.data))
			"Experience": child.get_child(1).text = str(PlayerVariables.getExperience())
			"Vitality":
				child.get_child(1).text = str(PlayerVariables.data.currentVitality) + "/" + str(max_vitality)
			"Fatigue": child.get_child(1).text = str(PlayerVariables.getFatigue())
			"LevelUp": child.disabled = !PlayerVariables.getLevelAvailable()
			"NecroticDamage": child.get_child(1).text = str(PlayerVariables.getNecroticDamage())

func _setSkillTooltip(btn: Button, skill: Skill) -> void:
	var campaign_manager := _get_campaign_manager()
	var is_gm_connected = campaign_manager != null and campaign_manager.has_method("has_active_gm_connection") and campaign_manager.has_active_gm_connection()
	if is_gm_connected:
		btn.tooltip_text = "Request a GM-reviewed skill check using %s (%s)." % [skill._name, skill.value]
		return
	btn.tooltip_text = "Open a local skill check using %s (%s)." % [skill._name, skill.value]

func _request_skill_check(skill_name: String) -> void:
	var campaign_manager := _get_campaign_manager()
	if campaign_manager != null and campaign_manager.has_method("begin_skill_check_request"):
		campaign_manager.begin_skill_check_request(skill_name)

func _get_campaign_manager() -> Node:
	return get_node_or_null("%CampaignManager")
