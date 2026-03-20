extends Control

func _ready() -> void:
	%CampaignName.text = CampaignVariables.getCampaignName()
	%CampaignDescription.text = CampaignVariables.getCampaignDescription()
	%CampaignManager.use_enet()
	%CampaignManager.become_host()
