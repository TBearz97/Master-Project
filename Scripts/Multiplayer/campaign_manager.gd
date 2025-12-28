extends FoldableContainer

@onready var memberList : MenuButton  = %Members

var members = {}

func _ready() -> void:
	memberList.get_popup().add_item("Leave Campaign", 0)
	memberList.get_popup().id_pressed.connect(_on_member_clicked)
	multiplayer.peer_connected.connect(_add_player_to_game)
	multiplayer.peer_disconnected.connect(_del_player)
	multiplayer.server_disconnected.connect(_disconnected)
	members["Don't Use"] = null

func use_enet():
	%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.ENET
	%NetworkSelector.hide()
	%Lobby.show()

func use_steam():
	SteamManager.initialize_steam()
	%NetworkManager.active_network_type = %NetworkManager.MULTIPLAYER_NETWORK_TYPE.STEAM
	%NetworkSelector.hide()
	%Lobby.show()

func become_host():
	%NetworkManager.become_host()
	_add_player_to_game(1)
	
func become_client():
	%NetworkManager.join_as_client(%CampaignCodeInput.text)

@rpc("any_peer", "call_remote", "reliable")
func _msgButtonClicked(_input):
	var _log: RichTextLabel = get_tree().current_scene.get_node("Panel/Lobby/VBoxContainer/ChatLog")
	_log.text = _log.text + _input


func sendMsg():
	var _input: LineEdit = get_tree().current_scene.get_node("Panel/Lobby/VBoxContainer/SendMessage/ChatInput")
	_msgButtonClicked.rpc(_input.text)

func _on_member_clicked(id):
	if id == 0:
		%NetworkManager._disconnect()
	if multiplayer.is_server() and id != 0:
		print("Test: " + str(memberList.get_popup().get_item_metadata(id)))
		multiplayer.multiplayer_peer.disconnect_peer(memberList.get_popup().get_item_metadata(id))

func _add_player_to_game(id: int):
	%JoinCampaign.hide()
	%LeaveCampaign.show()
	members[id] = memberList.item_count
	memberList.get_popup().add_item(str(id), members[id])
	memberList.get_popup().set_item_metadata(members[id], id)
	print("Player %s joined the game!" % id)
	
func _del_player(id: int):
	memberList.get_popup().remove_item(members[id])
	members.erase(id)
	print("Player %s left the game!" % id)

func _disconnected():
	%JoinCampaign.show()
	%LeaveCampaign.hide()
