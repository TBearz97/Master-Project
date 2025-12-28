extends Node

signal campaign_created(campaign_code: String, lobby_steam_id: int)
signal campaign_joined(lobby_steam_id: int)
signal campaign_join_failed(reason_text: String)
signal chat_message_received(sender_steam_id: int, message_text: String)

const application_test_identifier: int = 4251020
const packet_channel_chat: int = 0
const lobby_data_key_campaign_code: String = "campaign_code"
const maximum_lobbies_to_request: int = 50

var current_lobby_steam_id: int = 0
var current_campaign_code: String = ""

var pending_join_campaign_code: String = ""
var lobby_list_request_in_progress: bool = false

func _ready() -> void:
	
	var initialize_response: Dictionary = Steam.steamInitEx(application_test_identifier)
	if initialize_response.has("status") and int(initialize_response["status"]) != 0:
		push_error("Steam initialization failed: %s" % str(initialize_response))

	Steam.p2p_session_request.connect(_on_p2p_session_request)

	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_match_list.connect(_on_lobby_match_list)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	_read_chat_packets()

func start_campaign(maximum_members: int = 6) -> void:
	current_lobby_steam_id = 0
	current_campaign_code = ""
	
	Steam.createLobby(Steam.LOBBY_TYPE_INVISIBLE, maximum_members)

func join_campaign_by_code(campaign_code: String) -> void:
	var normalized_code: String = campaign_code.strip_edges().to_upper()
	if normalized_code.is_empty():
		emit_signal("campaign_join_failed", "Campaign code is empty.")
		return
	if lobby_list_request_in_progress:
		emit_signal("campaign_join_failed", "Lobby search already in progress.")
		return

	pending_join_campaign_code = normalized_code
	lobby_list_request_in_progress = true

	Steam.addRequestLobbyListResultCountFilter(maximum_lobbies_to_request)
	Steam.addRequestLobbyListStringFilter(
		lobby_data_key_campaign_code,
		pending_join_campaign_code,
		Steam.LOBBY_COMPARISON_EQUAL
	)
	Steam.requestLobbyList()

func send_chat_message(message_text: String) -> void:
	if current_lobby_steam_id == 0:
		return

	var trimmed_text: String = message_text.strip_edges()
	if trimmed_text.is_empty():
		return

	var payload: Dictionary = {
		"type": "chat",
		"text": trimmed_text
	}
	var payload_bytes: PackedByteArray = var_to_bytes(payload)

	var member_count: int = Steam.getNumLobbyMembers(current_lobby_steam_id)
	for member_index in range(member_count):
		var member_steam_id: int = Steam.getLobbyMemberByIndex(current_lobby_steam_id, member_index)
		if member_steam_id == Steam.getSteamID():
			continue
		Steam.sendP2PPacket(member_steam_id, payload_bytes, Steam.P2P_SEND_RELIABLE, packet_channel_chat)

func _on_lobby_created(_connect: int, lobby_steam_id: int) -> void:
	if _connect != 1:
		push_error("Lobby creation failed.")
		return

	current_lobby_steam_id = lobby_steam_id
	current_campaign_code = _generate_campaign_code_from_lobby_identifier(lobby_steam_id)

	Steam.setLobbyData(current_lobby_steam_id, lobby_data_key_campaign_code, current_campaign_code)
	
	var peer = SteamMultiplayerPeer.new()
	peer.create_host()
	multiplayer.multiplayer_peer = peer
	
	emit_signal("campaign_created", current_campaign_code, current_lobby_steam_id)
	emit_signal("campaign_joined", current_lobby_steam_id)

func _on_lobby_joined(lobby_steam_id: int, _permissions: int, _locked: bool, response: int) -> void:
	if response != 1:
		emit_signal("campaign_join_failed", "Join failed with response code: %s" % str(response))
		return
		
	current_lobby_steam_id = lobby_steam_id
	current_campaign_code = Steam.getLobbyData(current_lobby_steam_id, lobby_data_key_campaign_code)
	
	if !multiplayer.is_server() :
		var peer = SteamMultiplayerPeer.new()
		peer.create_client(Steam.getLobbyOwner(lobby_steam_id))
		multiplayer.multiplayer_peer = peer
	
	emit_signal("campaign_joined", current_lobby_steam_id)

func _on_lobby_match_list(lobby_steam_id_list: Array) -> void:
	lobby_list_request_in_progress = false

	if lobby_steam_id_list.is_empty():
		emit_signal("campaign_join_failed", "No campaign found for that code.")
		return

	var lobby_steam_id: int = int(lobby_steam_id_list[0])
	Steam.joinLobby(lobby_steam_id)

func _on_p2p_session_request(remote_steam_id: int) -> void:
	if current_lobby_steam_id == 0:
		return
	if _is_lobby_member(remote_steam_id):
		Steam.acceptP2PSessionWithUser(remote_steam_id)

func _is_lobby_member(steam_id_to_check: int) -> bool:
	var member_count: int = Steam.getNumLobbyMembers(current_lobby_steam_id)
	for member_index in range(member_count):
		if Steam.getLobbyMemberByIndex(current_lobby_steam_id, member_index) == steam_id_to_check:
			return true
	return false

func _read_chat_packets() -> void:
	while true:
		var packet_size: int = Steam.getAvailableP2PPacketSize(packet_channel_chat)
		if packet_size <= 0:
			return

		var packet: Dictionary = Steam.readP2PPacket(packet_size, packet_channel_chat)
		if packet.is_empty():
			return

		var sender_steam_id: int = int(packet["steamIDRemote"])
		var payload: Variant = bytes_to_var(packet["data"])

		if typeof(payload) == TYPE_DICTIONARY and String(payload.get("type", "")) == "chat":
			var message_text: String = String(payload.get("text", ""))
			emit_signal("chat_message_received", sender_steam_id, message_text)

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

@rpc("any_peer", "call_local")
func rpc_test_message():
	var sender_id := multiplayer.get_remote_sender_id()
	print("RPC received from peer ", sender_id, ": ")
	var window = ConfirmationDialog.new()
	window.exclusive = false
	add_child(window)
	window.popup_centered()

func send_rpc_test():
	# Send to everyone including host
	rpc_request_popup.rpc_id(1, "Popup from peer %d" % multiplayer.get_unique_id())


const SERVER_PEER_ID := 1

# Step 1: request to server
@rpc("any_peer", "call_remote", "reliable")
func rpc_request_popup(message_text: String) -> void:
	# Only the server should relay.
	if not multiplayer.is_server():
		return

	var sender_id := multiplayer.get_remote_sender_id()
	print("Server received popup request from ", sender_id)

	# Step 2: server broadcasts to all peers (and itself)
	rpc_show_popup.rpc(message_text, sender_id)

# Step 2: broadcast to everyone (including the broadcaster via call_local)
@rpc("any_peer", "call_local", "reliable")
func rpc_show_popup(message_text: String, sender_id: int) -> void:
	print("Showing popup. Sender was ", sender_id)

	var dialog := AcceptDialog.new()
	dialog.title = "RPC Test"
	dialog.dialog_text = message_text
	dialog.exclusive = false
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

	add_child(dialog)
	dialog.popup_centered()
