extends VBoxContainer

@export var grid: GridContainer
@export var points: SpinBox
@export var defBox: HBoxContainer

var attributes: Array[Attribute] = PlayerVariables.getAttributes()
var spinBoxes: Array[SpinBox] = []
var prev: Dictionary = {}

var defences: Array[Defence] = []
var defence_labels: Dictionary = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()
	setupDefences()

func _setup() -> void:
	points.value = PlayerVariables.getAttributePoints()
	var _attributes := CampaignVariables.codex.Attributes

	for attribute: Attribute in _attributes.values():
		var label := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label.text = CampaignVariables.replaceText(attribute._name)

		var bonus1 := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		var bonus2 := CampaignVariables.prepareLabel(RichTextLabel.new(), true)

		var sb := SpinBox.new()
		spinBoxes.append(sb)
		sb.tooltip_text = attribute._name
		sb.set_meta(sb.tooltip_text.replace(" ", ""), attribute)
		sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.min_value = 1
		if attributes.any(func(a): return a._name == attribute._name):
			sb.value = attributes[attributes.find_custom(func(a): return a._name == attribute._name)].value
		sb.rounded = true
		sb.step = 1
		prev[sb] = 1
		sb.value_changed.connect(_on_value_changed.bind(bonus1, bonus2, attribute, sb))
		_on_value_changed(1, bonus1, bonus2, attribute, sb)

		grid.columns = 4
		grid.add_child(label)
		grid.add_child(sb)
		grid.add_child(bonus1)
		grid.add_child(bonus2)

func setupDefences() -> void:
	for child in defBox.get_children():
		child.queue_free()

	defences.clear()
	defence_labels.clear()

	for defence_template: Defence in CampaignVariables.codex.Defences.values():
		var row := defence_template.duplicate(true) as Defence
		defences.append(row)
		var _name: String = row._name

		var label_name := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label_name.text = CampaignVariables.replaceText(_name)

		var label_value := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label_value.text = "0"

		defence_labels[_name] = label_value

		defBox.add_child(label_name)
		defBox.add_child(label_value)

	for att_sb in spinBoxes:
		if not att_sb.value_changed.is_connected(_on_attribute_changed_for_defences):
			att_sb.value_changed.connect(_on_attribute_changed_for_defences)

	_recalculate_defences()


func _save() -> void:
	for sb in spinBoxes:
		var _name := sb.tooltip_text
		if attributes.any(func(a): return a._name == _name):
			attributes[attributes.find_custom(func(a): return a._name == _name)].value = int(sb.value)
		else:
			var att: Attribute = sb.get_meta(_name.replace(" ", ""))
			att.value = int(sb.value)
			attributes.append(att)
	PlayerVariables.setAttributes(attributes)
	PlayerVariables.data.defences = _build_preview_defences()
	PlayerVariables.setAttributePoints(int(points.value))

func _on_value_changed(new_value: int, bonus1: RichTextLabel, bonus2: RichTextLabel, rows: Attribute, sb: SpinBox) -> void:
	bonus1.text = CampaignVariables.replaceText(rows.bonus_1_prefix + " " + str(RuleEngine.evaluate(rows.bonus_1_expression, ["x"], [new_value])) + " " + rows.bonus_1_suffix)
	bonus2.text = CampaignVariables.replaceText(rows.bonus_2_prefix + " " + str(RuleEngine.evaluate(rows.bonus_2_expression, ["x"], [new_value])) + " " + rows.bonus_2_suffix)

	if new_value > prev[sb]:
		points.value -= new_value - prev[sb]
	elif new_value < prev[sb]:
		points.value += prev[sb] - new_value

	prev[sb] = sb.value

	for key in prev:
		var _max: float = key.value + points.value
		if _max > 15:
			_max = 15
		key.max_value = _max

func _on_attribute_changed_for_defences(_new_value: int) -> void:
	_recalculate_defences()

func _recalculate_defences() -> void:
	for row: Defence in _build_preview_defences():
		defence_labels[row._name].text = str(row.value)

func _build_preview_defences() -> Array[Defence]:
	var preview_target := CreatureData.new()
	preview_target.attributes = _build_preview_attributes()
	var preview_defences: Array[Defence] = []
	for row: Defence in defences:
		var preview_defence := row.duplicate(true) as Defence
		preview_defence.getValue(preview_target)
		preview_defences.append(preview_defence)
	return preview_defences

func _build_preview_attributes() -> Array[Attribute]:
	var preview_attributes: Array[Attribute] = []
	for sb in spinBoxes:
		var attribute_name := sb.tooltip_text
		var source_attribute: Attribute = sb.get_meta(attribute_name.replace(" ", ""))
		if source_attribute == null:
			continue
		var preview_attribute := source_attribute.duplicate(true) as Attribute
		preview_attribute.value = int(sb.value)
		preview_attributes.append(preview_attribute)
	return preview_attributes
