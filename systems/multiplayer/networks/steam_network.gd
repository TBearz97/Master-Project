extends Node

var multiplayer_peer: SteamMultiplayerPeer = SteamMultiplayerPeer.new()
var current_lobby_steam_id = 0
var current_campaign_code = ""
const maximum_lobbies_to_request: int = 50

var lobby_data_key_campaign_code = "campaign code"



func  _ready():
	Steam.connect("lobby_created", _on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func become_host():
	print("Starting host!")
	
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, SteamManager.lobby_max_members)

func _on_lobby_created(_connect: int, lobby_steam_id: int) -> void:
	if _connect != 1:
		push_error("Lobby creation failed.")
		return

	current_lobby_steam_id = lobby_steam_id
	current_campaign_code = _generate_campaign_code_from_lobby_identifier(lobby_steam_id)
	get_parent().get_parent().get_node("Panel/Lobby/VBoxContainer/TabContainer/Settings/LeaveCampaign/CampaignCode").text = "Campaign Code: " + current_campaign_code

	Steam.setLobbyData(current_lobby_steam_id, lobby_data_key_campaign_code, current_campaign_code)
	
	var peer = SteamMultiplayerPeer.new()
	peer.create_host()
	multiplayer.multiplayer_peer = peer

#func join_as_client(lobby_id):
	#print("Joining lobby %s" % lobby_id)
	#Steam.joinLobby(lobby_id)

func _on_lobby_joined(lobby_id: int, _permissions: int, _locked: bool, _response: int) -> void:
	print("On lobby joined %s" % lobby_id)
	if Steam.getLobbyOwner(lobby_id) == Steam.getSteamID():
		print("Lobby host already in lobby, bypassing...")
		return
		
	multiplayer_peer.connect_to_lobby(lobby_id)
	multiplayer.multiplayer_peer = multiplayer_peer

func join_as_client(campaign_code: String) -> void:
	var normalized_code: String = campaign_code.strip_edges().to_upper()
	if normalized_code.is_empty():
		emit_signal("campaign_join_failed", "Campaign code is empty.")
		return

	Steam.addRequestLobbyListResultCountFilter(maximum_lobbies_to_request)
	Steam.addRequestLobbyListStringFilter(
		lobby_data_key_campaign_code,
		normalized_code,
		Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.requestLobbyList()


func _on_lobby_match_list(lobby_steam_id_list: Array) -> void:
	if lobby_steam_id_list.is_empty():
		emit_signal("campaign_join_failed", "No campaign found for that code.")
		return

	current_lobby_steam_id = int(lobby_steam_id_list[0])
	Steam.joinLobby(current_lobby_steam_id)

func list_lobbies():
	Steam.addRequestLobbyListDistanceFilter(Steam.LOBBY_DISTANCE_FILTER_WORLDWIDE)
	# NOTE: If you are using the test app id, you will need to apply a filter on your game name
	# Otherwise, it may not show up in the lobby list of your clients
	Steam.addRequestLobbyListStringFilter("name", "BAD", Steam.LOBBY_COMPARISON_EQUAL)
	Steam.requestLobbyList()


func _generate_campaign_code_from_lobby_identifier(lobby_steam_id: int) -> String:
	# Deterministic short code: base-36 of lobby id, keep last 6 characters.
	# Good enough for “getting started”. You can later switch to a random code with collision checks.
	var base36_text: String = _to_base36(lobby_steam_id).to_upper()
	if base36_text.length() >= 6:
		return base36_text.substr(base36_text.length() - 6, 6)
	return base36_text.rpad(6, "0")

func _to_base36(value: int) -> String:
	if value == 0:
		return "0"
	var alphabet: String = "0123456789abcdefghijklmnopqrstuvwxyz"
	var remaining: int = abs(value)
	var result: String = ""
	while remaining > 0:
		var digit: int = remaining % 36
		result = alphabet[digit] + result
		remaining /= 36
	return result
