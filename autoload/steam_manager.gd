extends Node

var is_owned: bool = false
var steam_app_id: int = 4660860
var steam_id: int = 0
var steam_username: String = ""

var lobby_id = 0
var lobby_max_members = 10

func _init():
	log_network_message("Steam", "Init Steam")
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

func _process(_delta):
	Steam.run_callbacks()
	
func initialize_steam():
	var initialize_response: Dictionary = Steam.steamInitEx()
	log_network_message("Steam", "Did Steam Initialize?: %s" % initialize_response)
	print("Did Steam Initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		log_network_message("Steam", "Failed to init Steam! Shutting down. %s" % initialize_response)
		print("Failed to init Steam! Shutting down. %s" % initialize_response)
		
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	log_network_message("Steam", "steam_id %s" % steam_id)
	print("steam_id %s" % steam_id)
	
	if is_owned == false:
		log_network_message("Steam", "User does not own game!")
		print("User does not own game!")

func log_network_message(sender_name: String, message_text: String, tooltip: String = "") -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null:
		return
	var campaign_manager := tree.root.find_child("CampaignManager", true, false)
	if campaign_manager != null and campaign_manager.has_method("_append_system_chat_line"):
		campaign_manager.call("_append_system_chat_line", sender_name, message_text, tooltip)
