extends VBoxContainer

@export var grid : GridContainer
@export var points : SpinBox
@export var _max : int

var skills : Dictionary[String, int] = {}
var spinBoxes : Array[SpinBox] = []
var prev = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()

func _setup () :
	points.value = PlayerVariables.skill_points
	var _skills = DbHelper.db_fetch("SELECT * FROM Skill")
	
	for rows in _skills :
		#--- Label ---
		var label = DbHelper.prepareLabel(RichTextLabel.new(), true)
		label.text = DbHelper.replaceText(rows["name"])
		#--- SpinBox ---
		var sb = SpinBox.new()
		spinBoxes.append(sb)
		sb.tooltip_text = rows["name"]
		sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.min_value = 1
		sb.max_value = _max + PlayerVariables.level
		if PlayerVariables.attributes.has(rows["name"]) :
			sb.value = PlayerVariables.attributes[rows["name"]]
		sb.rounded = true
		sb.step = 1
		prev[sb] = 1
		sb.value_changed.connect(_on_value_changed.bind(sb))
		_on_value_changed(1, sb)
		
		#--- Grid Setup
		grid.columns = 2
		grid.add_child(label)
		grid.add_child(sb)


func _on_value_changed(new_value: int, sb : SpinBox) -> void:
	
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
			key.max_value = _max + PlayerVariables.level


func _save () :
	for sb in spinBoxes :
		skills[sb.tooltip_text] = int(sb.value)
	PlayerVariables.skills = skills
	PlayerVariables.skill_points = int(points.value)
