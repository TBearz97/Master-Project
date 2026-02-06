extends Resource
class_name CampaignData

# Campaign Info
@export var campaign_name: String
@export var campaign_description: String

# Players
@export var playersData: Array[PlayerData]

func _init() -> void:
	campaign_name = ""
	campaign_description = ""
	playersData = []
