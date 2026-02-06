extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%CampaignName.text = CampaignVariables.getCampaignName()
	%CampaignDescription.text = CampaignVariables.getCampaignDescription()
	%CampaignManager.use_enet()
	%CampaignManager.become_host()
