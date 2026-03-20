extends FoldableContainer

@onready var member_list: VBoxContainer = %Members

var membersByPeerId: Dictionary = {}
var membersCharacters: Dictionary = {}

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	RuleEngine.diceRolled.connect(broadcast_dice)

func use_enet() -> void:
	%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.ENET
	%NetworkSelector.hide()
	%Lobby.show()

func use_steam() -> void:
	SteamManager.initialize_steam()
	%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM
	%NetworkSelector.hide()
	%Lobby.show()

func become_host() -> void:
	%NetworkManager.become_host()

	%JoinCampaign.hide()
	%LeaveCampaign.show()

	var serverPeerId: int = multiplayer.get_unique_id()
	membersByPeerId[serverPeerId] = "GameMaster"
	_broadcast_member_list()

func become_client() -> void:
	%NetworkManager.join_as_client(%CampaignCodeInput.text)

	%JoinCampaign.hide()
	%LeaveCampaign.show()

func _on_connected_to_server() -> void:
	rpc_id(1, "server_register_player", FileAccess.get_file_as_bytes("user://characters/" + PlayerVariables.getName() + ".res"))

func _on_peer_connected(peerId: int) -> void:
	if not multiplayer.is_server():
		return

	if not membersByPeerId.has(peerId):
		membersByPeerId[peerId] = "Connecting..."
		_broadcast_member_list()

func _on_peer_disconnected(peerId: int) -> void:
	if not multiplayer.is_server():
		return

	if membersByPeerId.has(peerId):
		membersByPeerId.erase(peerId)
		_broadcast_member_list()

@rpc("any_peer", "reliable")
func server_register_player(playerData: PackedByteArray) -> void:
	if not multiplayer.is_server():
		return

	var peerId: int = multiplayer.get_remote_sender_id()

	var tempPath := "user://temp/net_player_" + str(peerId) + ".res"

	var file := FileAccess.open(tempPath, FileAccess.WRITE)
	if file != null:
		file.store_buffer(playerData)
		file.close()

		var loaded: Resource = ResourceLoader.load(tempPath)
		if loaded is PlayerData:
			membersCharacters[peerId] = loaded

	if not membersCharacters.has(peerId):
		push_error("Failed to load player data for peer %s" % peerId)
		return

	membersByPeerId[peerId] = membersCharacters[peerId]._name
	_broadcast_member_list()

func _broadcast_member_list() -> void:
	rpc("client_set_member_list", membersByPeerId)

@rpc("authority", "call_local", "reliable")
func client_set_member_list(server_list: Dictionary) -> void:
	membersByPeerId = server_list.duplicate(true)
	_rebuild_member_list()

func _disconnected() -> void:
	for child in member_list.get_children():
		child.queue_free()

	membersByPeerId.clear()
	membersCharacters.clear()

	%JoinCampaign.show()
	%LeaveCampaign.hide()

func _rebuild_member_list() -> void:
	for child in member_list.get_children():
		child.queue_free()

	var peerIds: Array = membersByPeerId.keys()
	peerIds.sort()

	for peerIdVariant in peerIds:
		var peerId: int = int(peerIdVariant)
		var entry = membersByPeerId[peerId]

		var button := Button.new()
		button.name = str(peerId)

		var displayName = entry
		if multiplayer.get_unique_id() == peerId:
			displayName += " (You)"
		button.text = displayName

		button.pressed.connect(func() -> void:
			if multiplayer.is_server():
				PlayerVariables.data = membersCharacters[peerId]
				PlayerVariables.print_character_info()
		)

		member_list.add_child(button)

func sendMsg() -> void:
	var inputField: LineEdit = get_node("Panel/Lobby/VBoxContainer/SendMessage/ChatInput")
	var messageText: String = inputField.text.strip_edges()
	if messageText.is_empty():
		return

	inputField.text = ""

	if multiplayer.is_server():
		_server_receive_chat(messageText)
	else:
		rpc_id(1, "_server_receive_chat", messageText)

@rpc("any_peer", "reliable")
func _server_receive_chat(messageText: String) -> void:
	if not multiplayer.is_server():
		return

	var senderPeerId: int = multiplayer.get_remote_sender_id()

	if senderPeerId == 0:
		senderPeerId = multiplayer.get_unique_id()

	rpc("_client_append_chat_line", senderPeerId, messageText)

@rpc("authority", "call_local", "reliable")
func _client_append_chat_line(senderPeerId: int, messageText: String) -> void:
	var _chat_log: RichTextLabel = get_node("Panel/Lobby/VBoxContainer/TabContainer/ChatLog")
	var _log: RichTextLabel = get_node("Panel/Lobby/VBoxContainer/TabContainer/AllLogs")

	var senderName: String
	if membersByPeerId.has(senderPeerId):
		senderName = str(membersByPeerId[senderPeerId])
	else:
		senderName = "Peer " + str(senderPeerId)

	if senderPeerId == multiplayer.get_unique_id():
		senderName += " (You)"

	_chat_log.text += senderName + ": " + messageText + "\n"
	_log.text += senderName + ": " + messageText + "\n"

func _add_combat_log(combat_line: String) -> void:
	if multiplayer.is_server():
		_server_receive_combat(combat_line)
	else:
		rpc_id(1, "_server_receive_combat", combat_line)

@rpc("any_peer", "reliable")
func _server_receive_combat(combat_line: String) -> void:
	if not multiplayer.is_server():
		return

	var senderPeerId: int = multiplayer.get_remote_sender_id()

	if senderPeerId == 0:
		senderPeerId = multiplayer.get_unique_id()

	rpc("_client_append_combat_line", senderPeerId, combat_line)

@rpc("authority", "call_local", "reliable")
func _client_append_combat_line(senderPeerId: int, combat_line: String) -> void:
	var _chat_log: RichTextLabel = get_node("Panel/Lobby/VBoxContainer/TabContainer/CombatLog")
	var _log: RichTextLabel = get_node("Panel/Lobby/VBoxContainer/TabContainer/AllLogs")

	var senderName: String
	if membersByPeerId.has(senderPeerId):
		senderName = str(membersByPeerId[senderPeerId])
	else:
		senderName = "Peer " + str(senderPeerId)

	if senderPeerId == multiplayer.get_unique_id():
		senderName += " (You)"

	_chat_log.text += senderName + ": " + combat_line + "\n"
	_log.text += senderName + ": " + combat_line + "\n"

func broadcast_dice(diceRolled: Array) -> void:
	var message := ""
	for dice in diceRolled:
		message += "\nRolled a: " + str(dice)
	_add_combat_log(message)
