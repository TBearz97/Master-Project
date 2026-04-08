extends Node

const SERVER_PORT = 8080
const SERVER_IP = "127.0.0.1"

var current_campaign_code: String = "No campaign Code"
var multiplayer_peer: ENetMultiplayerPeer = ENetMultiplayerPeer.new()

func become_host() -> void:
	print("Starting host!")
	print(get_parent())
	var campaigncodelbl: Label = get_parent().get_parent().get_node("%CampaignCode")
	campaigncodelbl.text = "Campaign Code: " + current_campaign_code

	var error := multiplayer_peer.create_server(SERVER_PORT)
	if error != OK:
		push_error("Failed to create ENet server. Error code: %s" % error)
		return

	multiplayer.multiplayer_peer = multiplayer_peer

func join_as_client(_lobby_id: Variant) -> void:
	var error := multiplayer_peer.create_client(SERVER_IP, SERVER_PORT)
	if error != OK:
		push_error("Failed to create ENet client. Error code: %s" % error)
		return

	multiplayer.multiplayer_peer = multiplayer_peer
