extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var current_campaign_code = "No campaign Code"


var multiplayer_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func become_host():
	print("Starting host!")
	print(get_parent())
	var campaigncodelbl :Label = get_parent().get_parent().get_node("Panel/Lobby/VBoxContainer/TabContainer/Settings/LeaveCampaign/CampaignCode")
	campaigncodelbl.text = "Campaign Code: " + current_campaign_code
	
	multiplayer_peer.create_server(SERVER_PORT)
	multiplayer.multiplayer_peer = multiplayer_peer
	
func join_as_client(_lobby_id):
	
	var error = multiplayer_peer.create_client(SERVER_IP, SERVER_PORT)
	print(error)
	multiplayer.multiplayer_peer = multiplayer_peer
