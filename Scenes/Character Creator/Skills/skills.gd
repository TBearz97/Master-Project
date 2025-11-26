extends VBoxContainer

@export var grid : GridContainer
@export var points : SpinBox

var skills  = PlayerVariables.getSkills()
var spinBoxes : Array[SpinBox] = []
var prev = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()

func _setup () :
	points.value = PlayerVariables.getSkillPoints()
	var _skills = DbHelper.db_fetch("SELECT * FROM Skill")
	
	for rows in _skills :
		var skill = Skill.new(
		rows["name"],
		0,
		rows["short_description"],
		rows["long_description"]
	)
		#--- Label ---
		var label = DbHelper.prepareLabel(RichTextLabel.new(), true)
		label.text = DbHelper.replaceText(rows["name"])
		#--- SpinBox ---
		var sb = SpinBox.new()
		spinBoxes.append(sb)
		sb.tooltip_text = rows["name"]
		sb.set_meta(sb.tooltip_text.replace(" ", ""), skill)
		sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.min_value = 1
		if skills.any(func(a): return a._name == rows["name"]):
			sb.value = skills[skills.find_custom(func(a): return a._name == rows["name"])].value
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
		points.value -= new_value - prev[sb]
	elif new_value < prev[sb] :
		points.value += prev[sb] - new_value
	
	prev[sb] = sb.value
	
	for key in prev :
		var _max = key.value + points.value
		if key.value + points.value > PlayerVariables.getLevel() + 2 :
			_max = PlayerVariables.getLevel() + 2
		elif _max > 10 :
			_max = 10
		key.max_value = _max


func _save () :
	for sb in spinBoxes :
		var _name = sb.tooltip_text
		if skills.any(func(a): return a._name == _name):
			skills[skills.find_custom(func(a): return a._name == _name)].value = sb.value
		else :
			var sk = sb.get_meta(_name.replace(" ", ""))
			sk.value = sb.value
			skills.append(sk)
	PlayerVariables.setSkills(skills)
	PlayerVariables.setSkillPoints(int(points.value)) 
