extends VBoxContainer

@export var grid : GridContainer
@export var points : SpinBox
@export var _max : int

var attributes : Dictionary[String, int] = {}
var spinBoxes : Array[SpinBox] = []
var prev = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()

func _setup () :
	points.value = PlayerVariables.attribute_points
	var _attributes = DbHelper.db_fetch("SELECT * FROM Attribute")
	
	for rows in _attributes :
		#--- Label ---
		var label = DbHelper.prepareLabel(RichTextLabel.new(), true)
		label.text = DbHelper.replaceText(rows["name"])
		
		#--- Bonuses ---
		var bonus1 = DbHelper.prepareLabel(RichTextLabel.new(), true)
		var bonus2 = DbHelper.prepareLabel(RichTextLabel.new(), true)
		
		#--- SpinBox ---
		var sb = SpinBox.new()
		spinBoxes.append(sb)
		sb.tooltip_text = rows["name"]
		sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.min_value = 1
		sb.max_value = _max
		if PlayerVariables.attributes.has(rows["name"]) :
			sb.value = PlayerVariables.attributes[rows["name"]]
		sb.rounded = true
		sb.step = 1
		prev[sb] = 1
		sb.value_changed.connect(_on_value_changed.bind(bonus1, bonus2, rows, sb))
		_on_value_changed(1, bonus1, bonus2, rows, sb)
		
		#--- Grid Setup
		grid.columns = 4
		grid.add_child(label)
		grid.add_child(sb)
		grid.add_child(bonus1)
		grid.add_child(bonus2)

func _save () :
	for sb in spinBoxes :
		attributes[sb.tooltip_text] = int(sb.value)
	PlayerVariables.attributes = attributes
	PlayerVariables.attribute_points = int(points.value)

# ---- Helpers ----
func _on_value_changed(new_value: int, bonus1 : RichTextLabel, bonus2 : RichTextLabel, rows : Dictionary, sb : SpinBox) -> void:
	bonus1.text = DbHelper.replaceText(rows["bonus_1_prefix"] + " " + str(Expressions.evaluate(rows["bonus_1_expression"], ["x"], [new_value])) + " " + rows["bonus_1_suffix"])
	bonus2.text = DbHelper.replaceText(rows["bonus_2_prefix"] + " " + str(Expressions.evaluate(rows["bonus_2_expression"], ["x"], [new_value])) + " " + rows["bonus_2_suffix"])
	
	if new_value > prev[sb] :
		points.value -= 1
	elif new_value < prev[sb] :
		points.value += 1
	
	prev[sb] = new_value
	
	if points.value == 0 :
		for key in prev :
			key.max_value = key.value
	else : 
		for key in prev :
			key.max_value = _max
