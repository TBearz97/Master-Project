extends VBoxContainer

@export var grid: GridContainer
@export var points: SpinBox

var skills: Array[Skill] = PlayerVariables.getSkills()
var spinBoxes: Array[SpinBox] = []
var prev: Dictionary = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()

func _setup() -> void:
	points.value = PlayerVariables.getSkillPoints()
	var _skills := CampaignVariables.codex.Skills

	for skill: Skill in _skills.values():
		var label := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		label.text = CampaignVariables.replaceText(skill._name)
		var sb := SpinBox.new()
		spinBoxes.append(sb)
		sb.tooltip_text = skill._name
		sb.set_meta(sb.tooltip_text.replace(" ", ""), skill)
		sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.min_value = skill.min_rank
		sb.max_value = skill.max_rank
		sb.value = skill.min_rank
		if skills.any(func(a): return a._name == skill._name):
			sb.value = skills[skills.find_custom(func(a): return a._name == skill._name)].value
		sb.rounded = true
		sb.step = 1
		prev[sb] = sb.value
		sb.value_changed.connect(_on_value_changed.bind(sb))
		_on_value_changed(int(sb.value), sb)

		grid.columns = 2
		grid.add_child(label)
		grid.add_child(sb)

func _on_value_changed(new_value: int, sb: SpinBox) -> void:
	if new_value > prev[sb]:
		points.value -= new_value - prev[sb]
	elif new_value < prev[sb]:
		points.value += prev[sb] - new_value

	prev[sb] = sb.value

	for key in prev:
		var pointsAvailable: float = key.value + points.value
		var _max: float = pointsAvailable
		var cap: int = _get_skill_cap()
		var key_skill: Skill = key.get_meta(key.tooltip_text.replace(" ", ""))
		if key_skill != null:
			_max = min(_max, key_skill.max_rank)
		if key.value + points.value > cap:
			_max = cap
		key.max_value = _max

func _save() -> void:
	for sb in spinBoxes:
		var _name := sb.tooltip_text
		if skills.any(func(a): return a._name == _name):
			skills[skills.find_custom(func(a): return a._name == _name)].value = int(sb.value)
		else:
			var sk: Skill = sb.get_meta(_name.replace(" ", ""))
			sk.value = int(sb.value)
			skills.append(sk)
	PlayerVariables.setSkills(skills)
	PlayerVariables.setSkillPoints(int(points.value))

func _get_skill_cap() -> int:
	var skill_cap_rule := CampaignVariables.codex.get_rule("Skill Cap")
	var expression := "min(player_level + 2, 10)"
	if skill_cap_rule != null and not skill_cap_rule.expression.is_empty():
		expression = skill_cap_rule.expression
	return int(RuleEngine.evaluate(expression, ["player_level"], [PlayerVariables.getLevel()]))
