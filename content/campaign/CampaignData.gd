extends Resource
class_name CampaignData

# Campaign Info
@export var campaign_name: String
@export var campaign_description: String

# Players
@export var playersData: Array[PlayerData]

# Session
@export var session_started: bool
@export var session_snapshot: Dictionary
@export var gameEvents: Array[GameEvent]

func _init() -> void:
	campaign_name = ""
	campaign_description = ""
	playersData = []
	session_started = false
	session_snapshot = {}
	gameEvents = []
