extends VBoxContainer

func _ready() -> void:
	visibility_changed.connect(save_info)
	%ReturnToMM.pressed.connect(returnMM)
	%ProceedToGS.pressed.connect(proceedGS)

func save_info() -> void:
	CampaignVariables.setCampaignName(%NameInput.text)
	CampaignVariables.setCampaignDescription(%TextEdit.text)


func returnMM() -> void:
	CampaignVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_Menu.tscn")

func proceedGS() -> void:
	CampaignVariables.save()
	get_tree().change_scene_to_file("res://Scenes/Campaign Sheet/CampaignSheet.tscn")
