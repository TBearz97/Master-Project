extends VBoxContainer

var DTs: Array[RichTextLabel] = []
var defence_labels: Dictionary = {}

func _ready() -> void:
	if not PlayerVariables.combat_loadout_changed.is_connected(_refresh_defences):
		PlayerVariables.combat_loadout_changed.connect(_refresh_defences)
	if not PlayerVariables.vitals_changed.is_connected(_refresh_defences):
		PlayerVariables.vitals_changed.connect(_refresh_defences)
	_setup()

func _setup() -> void:
	var defencesLabel := CampaignVariables.prepareLabel(RichTextLabel.new())
	defencesLabel.text = CampaignVariables.replaceText("Defences")
	add_child(defencesLabel)

	var defencesHbox := HBoxContainer.new()

	var defences := CampaignVariables.codex.Defences
	for defence: Defence in defences.values():
		var label := CampaignVariables.prepareLabel(RichTextLabel.new())
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.text = CampaignVariables.replaceText(defence._name + ": 0")
		defence_labels[defence._name] = label
		defencesHbox.add_child(label)
	add_child(defencesHbox)

	var dtLabel := CampaignVariables.prepareLabel(RichTextLabel.new())
	dtLabel.text = CampaignVariables.replaceText("Damage Thresholds")
	add_child(dtLabel)

	var dtHbox := HBoxContainer.new()

	var physLabel := CampaignVariables.prepareLabel(RichTextLabel.new())
	physLabel.text = "Physical DT: 0"
	physLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dtHbox.add_child(physLabel)
	DTs.append(physLabel)

	var magiLabel := CampaignVariables.prepareLabel(RichTextLabel.new())
	magiLabel.text = "Magical DT: 0"
	magiLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dtHbox.add_child(magiLabel)
	DTs.append(magiLabel)

	var necLabel := CampaignVariables.prepareLabel(RichTextLabel.new())
	necLabel.text = "Necrotic DT: 0"
	necLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dtHbox.add_child(necLabel)
	DTs.append(necLabel)
	add_child(dtHbox)
	_refresh_defences()
	recalculateDTs()

func _refresh_defences() -> void:
	for defence_name in defence_labels.keys():
		var label := defence_labels[defence_name] as RichTextLabel
		if label == null:
			continue
		var defence_value := RuleEngine.getDefenceValue(PlayerVariables.current(), str(defence_name))
		label.text = CampaignVariables.replaceText("%s: %s" % [defence_name, defence_value])

func recalculateDTs() -> void:
	var physicalDT := 0
	var magicalDT := 0
	var necroticDT := 0
	for slot in get_tree().get_nodes_in_group("Armor Slots"):
		var item = slot.equipped
		if item is Armor:
			physicalDT += item.physicalDT
			magicalDT += item.magicalDT
			necroticDT += item.necroticDT
	for lbl in DTs:
		if lbl.text.contains("Physical"):
			lbl.text = "Physical DT: " + str(physicalDT)

		if lbl.text.contains("Magical"):
			lbl.text = "Magical DT: " + str(magicalDT)

		if lbl.text.contains("Necrotic"):
			lbl.text = "Necrotic DT: " + str(necroticDT)
