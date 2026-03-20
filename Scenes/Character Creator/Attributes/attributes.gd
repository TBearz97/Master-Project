extends VBoxContainer

@export var grid : GridContainer
@export var points : SpinBox
@export var defBox : HBoxContainer

var attributes = PlayerVariables.getAttributes()
var spinBoxes : Array[SpinBox] = []
var prev = {}

var defence_rows : Dictionary[String, Defence] = CampaignVariables.codex.Defences
var defence_labels : Dictionary = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()
	setupDefences()

func _setup () :
	points.value = PlayerVariables.getAttributePoints()
	var _attributes = CampaignVariables.codex.Attributes
	
	for attribute : Attribute in _attributes.values() :
		#--- Label ---
		var label = CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label.text = CampaignVariables.replaceText(attribute._name)
		
		#--- Bonuses ---
		var bonus1 = CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		var bonus2 = CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		
		#--- SpinBox ---
		var sb = SpinBox.new()
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
		
		#--- Grid Setup
		grid.columns = 4
		grid.add_child(label)
		grid.add_child(sb)
		grid.add_child(bonus1)
		grid.add_child(bonus2)

func setupDefences() -> void:
	# clear old children if any
	for child in defBox.get_children():
		child.queue_free()

	defence_labels.clear()

	# create UI for each defence
	for row : Defence in defence_rows.values():
		var _name : String = row._name

		var label_name := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label_name.text = CampaignVariables.replaceText(_name)

		var label_value := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label_value.text = "0"

		defence_labels[_name] = label_value

		defBox.add_child(label_name)
		defBox.add_child(label_value)

	# connect each attribute SpinBox once
	for att_sb in spinBoxes:
		if not att_sb.value_changed.is_connected(_on_attribute_changed_for_defences):
			att_sb.value_changed.connect(_on_attribute_changed_for_defences)

	_recalculate_defences()


func _save () :
	for sb in spinBoxes :
		var _name = sb.tooltip_text
		if attributes.any(func(a): return a._name == _name):
			attributes[attributes.find_custom(func(a): return a._name == _name)].value = sb.value
		else :
			var att = sb.get_meta(_name.replace(" ", ""))
			att.value = sb.value
			attributes.append(att)
	PlayerVariables.setAttributes(attributes)
	PlayerVariables.setAttributePoints(int(points.value))

# ---- Helpers ----
func _on_value_changed(new_value: int, bonus1 : RichTextLabel, bonus2 : RichTextLabel, rows : Attribute, sb : SpinBox) -> void:
	bonus1.text = CampaignVariables.replaceText(rows.bonus_1_prefix + " " + str(RuleEngine.evaluate(rows.bonus_1_expression, ["x"], [new_value])) + " " + rows.bonus_1_suffix)
	bonus2.text = CampaignVariables.replaceText(rows.bonus_2_prefix + " " + str(RuleEngine.evaluate(rows.bonus_2_expression, ["x"], [new_value])) + " " + rows.bonus_2_suffix)
	
	if new_value > prev[sb] : 
		points.value -= new_value - prev[sb]
	elif new_value < prev[sb] :
		points.value += prev[sb] - new_value
	
	prev[sb] = sb.value
	
	for key in prev :
		var _max = key.value + points.value
		if _max > 15 :
			_max = 15
		key.max_value = _max

func _on_attribute_changed_for_defences(_new_value: int) -> void:
	_recalculate_defences()

func _recalculate_defences() -> void:
	for row : Defence in defence_rows.values():
		var def_name : String = row._name
		var attr1 : String = row.attribute1._name
		var attr2 = row.attribute2._name

		var total := 0

		var sb1 := _find_attribute_spinbox(attr1)
		if sb1 != null:
			total += int(sb1.value)

		if attr2 != null and attr2 != "":
			var sb2 := _find_attribute_spinbox(attr2)
			if sb2 != null:
				total += int(sb2.value)

		defence_labels[def_name].text = str(total)

func _find_attribute_spinbox(attr_name : String) -> SpinBox:
	for sb in spinBoxes:
		if sb.tooltip_text == attr_name:
			return sb
	return null
