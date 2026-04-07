extends Button

func _ready() -> void:
	pressed.connect(_on_pressed)

func _on_pressed() -> void:
	PlayerVariables.data = PlayerData.new()
	PlayerVariables.data.actions = _get_basic_actions()
	PlayerVariables.setAttributePoints(29)
	PlayerVariables.setSkillPoints(12)
	PlayerVariables.setPerkPoints(3)
	PlayerVariables.setMoney(300)
	get_tree().change_scene_to_file("res://Scenes/Character Creator/character_creator.tscn")

func _get_basic_actions() -> Array[Action]:
	var basic_actions: Array[Action] = []
	if CampaignVariables.codex == null:
		return basic_actions
	var action_names: Array = CampaignVariables.codex.Actions.keys()
	action_names.sort()
	for action_name_variant in action_names:
		var action: Action = CampaignVariables.codex.Actions.get(str(action_name_variant), null)
		if action == null or action.category != Action.CATEGORY_BASIC:
			continue
		basic_actions.append(action.duplicate(true) as Action)
	return basic_actions
