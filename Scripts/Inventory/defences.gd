extends VBoxContainer

var DTs : Array[RichTextLabel]

func _ready() -> void:
	_setup()

func _setup() -> void:
	var defencesLabel = DbHelper.prepareLabel(RichTextLabel.new())
	defencesLabel.text = DbHelper.replaceText("Defences")
	add_child(defencesLabel)
	
	var defencesHbox = HBoxContainer.new()
	
	var rows = DbHelper.db_fetch("SELECT * FROM Defence")
	for row in rows:
		var label = DbHelper.prepareLabel(RichTextLabel.new())
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var value = _recalculate_defence(row["attribute1"], row["attribute2"] if row["attribute2"] != null else "")
		label.text = DbHelper.replaceText(row["name"] + ": " + str(value))
		defencesHbox.add_child(label)
	add_child(defencesHbox)
	
	var dtLabel = DbHelper.prepareLabel(RichTextLabel.new())
	dtLabel.text = DbHelper.replaceText("Damage Thresholds")
	add_child(dtLabel)
	
	var dtHbox = HBoxContainer.new()
	
	var physLabel = DbHelper.prepareLabel(RichTextLabel.new())
	physLabel.text = "Physical DT: 0"
	physLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dtHbox.add_child(physLabel)
	DTs.append(physLabel)
	
	var magiLabel = DbHelper.prepareLabel(RichTextLabel.new())
	magiLabel.text = "Magical DT: 0"
	magiLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dtHbox.add_child(magiLabel)
	DTs.append(magiLabel)
	
	var necLabel = DbHelper.prepareLabel(RichTextLabel.new())
	necLabel.text = "Necrotic DT: 0"
	necLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dtHbox.add_child(necLabel)
	DTs.append(necLabel)
	add_child(dtHbox)
	recalculateDTs()

func recalculateDTs () :
	var physicalDT = 0
	var magicalDT = 0
	var necroticDT = 0
	for slot in get_tree().get_nodes_in_group("Armor Slots") :
		var item = slot.equipped
		if item is Armor :
			physicalDT += item.physicalDT
			magicalDT += item.magicalDT
			necroticDT += item.necroticDT
	for lbl in DTs :
		if lbl.text.contains("Physical") :
			lbl.text = "Physical DT: " + str(physicalDT)
		
		if lbl.text.contains("Magical") :
			lbl.text = "Magical DT: " + str(magicalDT)
			
		if lbl.text.contains("Necrotic") :
			lbl.text = "Necrotic DT: " + str(necroticDT)

func _recalculate_defence(attr1 : String, attr2 : String = "") -> int:
		var atts : Array[Attribute] = PlayerVariables.getAttributes()
		var total := 0
		
		for att in atts :
			if att._name == attr1 :
				total += att.value
			if attr2 != null and attr2 != "":
				if att._name == attr2 :
					total += att.value
		return total
