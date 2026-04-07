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
		sb.min_value = 1
		if skills.any(func(a): return a._name == skill._name):
			sb.value = skills[skills.find_custom(func(a): return a._name == skill._name)].value
		sb.rounded = true
		sb.step = 1
		prev[sb] = 1
		sb.value_changed.connect(_on_value_changed.bind(sb))
		_on_value_changed(1, sb)

		grid.columns = 2
		grid.add_child(label)
		grid.add_child(sb)

func _rank_cost(from_rank: int, to_rank: int) -> int:
	var cost := 0

	if to_rank > from_rank:
		for i in range(from_rank, to_rank):
			cost += int(RuleEngine.evaluate(
				CampaignVariables.codex.Rules["Skill Cost"].expression,
				["skill"], [i]
			))
	elif to_rank < from_rank:
		for i in range(to_rank, from_rank):
			cost -= int(RuleEngine.evaluate(
				CampaignVariables.codex.Rules["Skill Cost"].expression,
				["skill"], [i]
			))

	return cost


func _on_value_changed(new_value: int, sb: SpinBox) -> void:
	var old_value: int = prev[sb]
	var cost: int = _rank_cost(old_value, new_value)

	# Not enough points: reject the increase
	if cost > 0 and cost > points.value:
		sb.value = old_value
		return

	# Apply cost/refund
	points.value -= cost
	prev[sb] = sb.value

	for key in prev:
		var points_available: float = points.value
		var current_rank: int = int(key.value)
		var max_rank := current_rank + 1

		while true:
			var next_rank := max_rank + 1
			var next_cost := next_rank
			var cap: int = int(RuleEngine.evaluate(
				CampaignVariables.codex.Rules["Skill Cap"].expression,
				["skill"], [max_rank]
			))

			if next_rank > cap:
				break
			if points_available < next_cost:
				break

			points_available -= next_cost
			max_rank += 1

		key.max_value = max_rank

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
