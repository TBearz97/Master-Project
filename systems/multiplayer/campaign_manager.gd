extends FoldableContainer

signal encounter_state_changed(started: bool)
signal authority_role_changed(is_host: bool)

@onready var member_list: VBoxContainer = %Members

var membersByPeerId: Dictionary = {}
var membersCharacters: Dictionary = {}
var encounter_started: bool = false
var is_host_role: bool = false

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
	is_host_role = true
	authority_role_changed.emit(is_host_role)
	%NetworkManager.become_host()

	%JoinCampaign.hide()
	%LeaveCampaign.show()

	var serverPeerId: int = multiplayer.get_unique_id()
	membersByPeerId[serverPeerId] = "GameMaster"
	_broadcast_member_list()

func become_client() -> void:
	is_host_role = false
	authority_role_changed.emit(is_host_role)
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
			_ensure_basic_actions(loaded)
			_ensure_valid_player_vitals(loaded, true)
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
	encounter_started = false
	is_host_role = false
	encounter_state_changed.emit(encounter_started)
	authority_role_changed.emit(is_host_role)

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

func _append_combat_log_local(senderPeerId: int, combat_line: String, tooltip: String = "") -> void:
	var _chat_log: RichTextLabel = get_node("Panel/Lobby/VBoxContainer/TabContainer/CombatLog")
	var _log: RichTextLabel = get_node("Panel/Lobby/VBoxContainer/TabContainer/AllLogs")

	var senderName: String
	if membersByPeerId.has(senderPeerId):
		senderName = str(membersByPeerId[senderPeerId])
	else:
		senderName = "Peer " + str(senderPeerId)

	if senderPeerId == multiplayer.get_unique_id():
		senderName += " (You)"

	var message_text := _escape_bbcode_text(senderName + ": " + combat_line)
	var _tooltip_text := _escape_bbcode_text(tooltip)
	_append_log_line(_chat_log, message_text, _tooltip_text)
	_append_log_line(_log, message_text, _tooltip_text)

func _escape_bbcode_text(text: String) -> String:
	return text.replace("[", "\\[").replace("]", "\\]")

func _append_log_line(log_label: RichTextLabel, message_text: String, _tooltip_text: String) -> void:
	if log_label == null:
		return
	if not _tooltip_text.is_empty():
		log_label.push_hint(_tooltip_text)
	log_label.append_text(message_text)
	if not _tooltip_text.is_empty():
		log_label.pop()
	log_label.append_text("\n")

func broadcast_combatant_spawn(combatant_payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	rpc("client_spawn_combatant", combatant_payload)

func submit_local_player_combatant_update(combatant_payload: Dictionary) -> void:
	if multiplayer.is_server():
		_sync_player_from_combatant_payload(multiplayer.get_unique_id(), combatant_payload)
		broadcast_combatant_update(combatant_payload)
	else:
		# Clients never write combatant state directly; they ask the host to vet and
		# rebroadcast the update.
		rpc_id(1, "server_update_player_combatant", combatant_payload)

func broadcast_combatant_update(combatant_payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var combatant_id := str(combatant_payload.get("id", ""))
	if combatant_id.is_empty():
		push_error("Cannot broadcast combatant update without an id.")
		return

	var state_change := combatant_payload.duplicate(true)
	state_change.erase("id")
	state_change["combatant_id"] = combatant_id

	var game_event := GameEvent.new(
		"combatant_updated",
		GameEvent.CONTEXT_COMBAT,
		{},
		[state_change]
	)
	broadcast_game_event(game_event)

func broadcast_combat_reset() -> void:
	if not multiplayer.is_server():
		return
	rpc("client_set_encounter_started", false)
	rpc("client_reset_combat_session")

func broadcast_encounter_started(started: bool) -> void:
	if not multiplayer.is_server():
		return
	rpc("client_set_encounter_started", started)

func broadcast_game_event(game_event: GameEvent) -> void:
	if not multiplayer.is_server() or game_event == null:
		return

	CampaignVariables.appendGameEvent(game_event)
	rpc("client_apply_game_event", game_event.to_dict())

func broadcast_combat_request(combat_request: CombatRequest) -> void:
	if combat_request == null:
		return
	if multiplayer.is_server():
		rpc("client_apply_combat_request", combat_request.to_dict())
	else:
		rpc_id(1, "server_broadcast_combat_request", combat_request.to_dict())

func apply_game_event(game_event: GameEvent) -> void:
	if game_event == null:
		return

	match game_event.context:
		GameEvent.CONTEXT_COMBAT:
			var combat_session := _find_node_by_name(get_tree().root, "CombatSession")
			if combat_session == null:
				push_error("Could not find CombatSession to apply GameEvent.")
				return
			if combat_session.has_method("apply_game_event"):
				combat_session.apply_game_event(game_event)
		GameEvent.CONTEXT_INVENTORY, GameEvent.CONTEXT_SKILL_CHECK, GameEvent.CONTEXT_STATE:
			_apply_non_combat_game_event(game_event)
		_:
			push_error("Unhandled GameEvent context: %s" % game_event.context)

func _apply_non_combat_game_event(game_event: GameEvent) -> void:
	# Non-combat contexts will be applied here as the broader event system is implemented.
	# For now, the authoritative event log is still preserved for review and replay.
	if game_event.context == GameEvent.CONTEXT_SKILL_CHECK and not game_event.results.is_empty():
		var sender_peer_id := 1
		for result in game_event.results:
			if result is Dictionary:
				_append_combat_log_local(sender_peer_id, str(result.get("text", "")), str(result.get("tooltip", "")))
			else:
				_append_combat_log_local(sender_peer_id, str(result))

func apply_combat_request(combat_request: CombatRequest) -> void:
	if combat_request == null:
		return

	var combat_session := _find_node_by_name(get_tree().root, "CombatSession")
	if combat_session == null:
		push_error("Could not find CombatSession to apply CombatRequest.")
		return
	if combat_session.has_method("apply_combat_request"):
		combat_session.apply_combat_request(combat_request)

@rpc("any_peer", "reliable")
func server_broadcast_combat_request(request_data: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	rpc("client_apply_combat_request", request_data)

func has_started_encounter() -> bool:
	return encounter_started

func is_host_authority() -> bool:
	return is_host_role

@rpc("authority", "call_local", "reliable")
func client_set_encounter_started(started: bool) -> void:
	encounter_started = started
	encounter_state_changed.emit(encounter_started)

@rpc("authority", "call_local", "reliable")
func client_apply_game_event(event_data: Dictionary) -> void:
	var game_event := GameEvent.from_dict(event_data)
	apply_game_event(game_event)

@rpc("authority", "call_local", "reliable")
func client_apply_combat_request(request_data: Dictionary) -> void:
	var combat_request := CombatRequest.from_dict(request_data)
	apply_combat_request(combat_request)

@rpc("authority", "call_local", "reliable")
func client_spawn_combatant(combatant_payload: Dictionary) -> void:
	var combat_session := _find_node_by_name(get_tree().root, "CombatSession")
	if combat_session == null:
		push_error("Could not find CombatSession to spawn combatant.")
		return
	combat_session.spawn_combatant_locally(combatant_payload)

@rpc("any_peer", "reliable")
func server_update_player_combatant(combatant_payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return

	var sender_peer_id := multiplayer.get_remote_sender_id()
	if sender_peer_id == 0:
		sender_peer_id = multiplayer.get_unique_id()

	if int(combatant_payload.get("controller_peer_id", -1)) != sender_peer_id:
		push_error("Rejected combatant update for mismatched peer %s" % sender_peer_id)
		return

	_sync_player_from_combatant_payload(sender_peer_id, combatant_payload)

	# Once validated, the host treats this like any other authoritative combatant
	# payload update and pushes it back out to every peer.
	broadcast_combatant_update(combatant_payload)

func _ensure_basic_actions(player_data: PlayerData) -> void:
	if player_data == null or CampaignVariables.codex == null:
		return
	if player_data.actions == null:
		player_data.actions = []
	var existing_names: Array[String] = []
	for action in player_data.actions:
		if action is Action:
			existing_names.append(action._name)
	var action_names: Array = CampaignVariables.codex.Actions.keys()
	action_names.sort()
	for action_name_variant in action_names:
		var action: Action = CampaignVariables.codex.Actions.get(str(action_name_variant), null)
		if action == null or action.category != Action.CATEGORY_BASIC:
			continue
		if existing_names.has(action._name):
			continue
		player_data.actions.append(action.duplicate(true) as Action)

func _sync_player_from_combatant_payload(peer_id: int, combatant_payload: Dictionary) -> void:
	if not membersCharacters.has(peer_id):
		return
	var player_data := membersCharacters[peer_id] as PlayerData
	if player_data == null:
		return
	_ensure_basic_actions(player_data)
	_ensure_valid_player_vitals(player_data)
	if combatant_payload.has("current_hp"):
		player_data.currentHP = int(combatant_payload.get("current_hp", player_data.currentHP))
	if combatant_payload.has("max_hp"):
		player_data.maxHP = int(combatant_payload.get("max_hp", player_data.maxHP))
	if combatant_payload.has("current_vitality"):
		player_data.currentVitality = int(combatant_payload.get("current_vitality", player_data.currentVitality))
	if combatant_payload.has("max_vitality"):
		player_data.maxVitality = int(combatant_payload.get("max_vitality", player_data.maxVitality))
	if combatant_payload.has("temporary_health"):
		player_data.temporaryHealth = int(combatant_payload.get("temporary_health", player_data.temporaryHealth))
	if combatant_payload.has("level"):
		player_data.level = int(combatant_payload.get("level", player_data.level))
	if combatant_payload.has("active_loadout"):
		player_data.set_meta("active_loadout", int(combatant_payload.get("active_loadout", 1)))
	if combatant_payload.has("equipment"):
		player_data.equipment = _build_equipment_from_payload(combatant_payload.get("equipment", {}))
	_ensure_valid_player_vitals(player_data)

func _ensure_valid_player_vitals(player_data: PlayerData, refill_if_uninitialized: bool = false) -> void:
	if player_data == null:
		return
	RuleEngine.normalizeVitals(player_data, refill_if_uninitialized)

func _build_equipment_from_payload(equipment_payload: Variant) -> Equipment:
	var equipment := Equipment.new()
	if not (equipment_payload is Dictionary):
		return equipment
	var data := equipment_payload as Dictionary
	equipment.head = _get_item_from_codex(str(data.get("head", ""))) as Armor
	equipment.torso = _get_item_from_codex(str(data.get("torso", ""))) as Armor
	equipment.leftArm = _get_item_from_codex(str(data.get("leftArm", ""))) as Armor
	equipment.rightArm = _get_item_from_codex(str(data.get("rightArm", ""))) as Armor
	equipment.leftLeg = _get_item_from_codex(str(data.get("leftLeg", ""))) as Armor
	equipment.rightLeg = _get_item_from_codex(str(data.get("rightLeg", ""))) as Armor
	equipment.weapon1Left = _get_item_from_codex(str(data.get("weapon1Left", ""))) as Weapon
	equipment.weapon1Right = _get_item_from_codex(str(data.get("weapon1Right", ""))) as Weapon
	equipment.weapon2Left = _get_item_from_codex(str(data.get("weapon2Left", ""))) as Weapon
	equipment.weapon2Right = _get_item_from_codex(str(data.get("weapon2Right", ""))) as Weapon
	equipment.quickItem1 = _get_item_from_codex(str(data.get("quickItem1", "")))
	equipment.quickItem2 = _get_item_from_codex(str(data.get("quickItem2", "")))
	equipment.quickItem3 = _get_item_from_codex(str(data.get("quickItem3", "")))
	equipment.quickItem4 = _get_item_from_codex(str(data.get("quickItem4", "")))
	return equipment

func _get_item_from_codex(item_name: String) -> Item:
	if item_name.is_empty() or CampaignVariables.codex == null:
		return null
	var template: Item = CampaignVariables.codex.Items.get(item_name, null)
	if template == null:
		return null
	return template.duplicate(true) as Item

@rpc("authority", "call_local", "reliable")
func client_reset_combat_session() -> void:
	var combat_session := _find_node_by_name(get_tree().root, "CombatSession")
	if combat_session == null:
		push_error("Could not find CombatSession to reset combatants.")
		return
	combat_session.reset_combat_session_locally()

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
	_append_combat_log_local(senderPeerId, combat_line)

func broadcast_dice(diceRolled: Array) -> void:
	var message := ""
	for dice in diceRolled:
		message += "\nRolled a: " + str(dice)
	_add_combat_log(message)

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node

	for child in node.get_children():
		var result := _find_node_by_name(child, target_name)
		if result != null:
			return result

	return null
