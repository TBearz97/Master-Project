extends FoldableContainer


signal encounter_state_changed(started: bool)
signal authority_role_changed(is_host: bool)
signal member_list_changed()

@onready var member_list: VBoxContainer = %Members
@onready var notification_inbox: VBoxContainer = %Inbox
@onready var log_tabs: TabContainer = $Panel/Lobby/VBoxContainer/TabContainer
@onready var nested_log_tabs: TabContainer = %LogsTabContainer
@onready var all_logs: RichTextLabel = %AllLogs
@onready var chat_log: RichTextLabel = %ChatLog
@onready var combat_log: RichTextLabel = %CombatLog
@onready var skill_check_log: RichTextLabel = %SkillCheckLog

var membersByPeerId: Dictionary = {}
var membersCharacters: Dictionary = {}
var pending_skill_check_requests: Dictionary = {}
var pending_skill_check_offers: Dictionary = {}
var encounter_started: bool = false
var is_host_role: bool = false

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	RuleEngine.diceRolled.connect(broadcast_dice)
	_rebuild_notifications()

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
	member_list_changed.emit()

func _disconnected() -> void:
	for child in member_list.get_children():
		child.queue_free()
	for child in notification_inbox.get_children():
		child.queue_free()

	membersByPeerId.clear()
	membersCharacters.clear()
	pending_skill_check_requests.clear()
	pending_skill_check_offers.clear()
	encounter_started = false
	is_host_role = false
	encounter_state_changed.emit(encounter_started)
	authority_role_changed.emit(is_host_role)
	member_list_changed.emit()

	%JoinCampaign.show()
	%LeaveCampaign.hide()
	_rebuild_notifications()

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
	var senderName: String
	if membersByPeerId.has(senderPeerId):
		senderName = str(membersByPeerId[senderPeerId])
	else:
		senderName = "Peer " + str(senderPeerId)

	if senderPeerId == multiplayer.get_unique_id():
		senderName += " (You)"

	chat_log.text += senderName + ": " + messageText + "\n"
	all_logs.text += senderName + ": " + messageText + "\n"

func _add_combat_log(combat_line: String) -> void:
	if multiplayer.is_server():
		_server_receive_combat(combat_line)
	else:
		rpc_id(1, "_server_receive_combat", combat_line)

func begin_skill_check_request(requested_skill_name: String) -> void:
	var normalized_skill_name := requested_skill_name.strip_edges()
	if normalized_skill_name.is_empty():
		return

	if has_active_gm_connection():
		var payload := {
			"request_id": _generate_skill_check_request_id(),
			"requester_peer_id": multiplayer.get_unique_id(),
			"requester_name": PlayerVariables.getName(),
			"requested_skill": normalized_skill_name,
		}
		rpc_id(1, "server_receive_skill_check_request", payload)
		_append_combat_log_local(multiplayer.get_unique_id(), "Requested a %s skill check from the GM." % normalized_skill_name)
		return

	_show_local_skill_check_window(normalized_skill_name)

func begin_gm_skill_check_for_peer(peer_id: int) -> void:
	if not is_host_role:
		return
	if peer_id <= 0 or peer_id == multiplayer.get_unique_id() or not membersByPeerId.has(peer_id):
		return
	var request_payload := {
		"request_id": _generate_skill_check_request_id(),
		"requester_peer_id": peer_id,
		"requester_name": str(membersByPeerId.get(peer_id, "Player")),
		"requested_skill": "",
		"initiated_by_gm": true,
	}
	pending_skill_check_requests[str(request_payload["request_id"])] = request_payload
	_rebuild_notifications()
	_show_gm_skill_check_window(request_payload)

func get_local_skill_names() -> Array[String]:
	return get_skill_names_for_peer(multiplayer.get_unique_id())

func get_local_skill_value_map() -> Dictionary:
	return get_skill_value_map_for_peer(multiplayer.get_unique_id())

func get_skill_names_for_peer(peer_id: int) -> Array[String]:
	var source_player: PlayerData = PlayerVariables.data
	if membersCharacters.has(peer_id):
		source_player = membersCharacters[peer_id] as PlayerData
	var skill_names: Array[String] = []
	if source_player == null:
		return skill_names
	for skill: Skill in source_player.skills:
		if skill != null and not skill._name.is_empty():
			skill_names.append(skill._name)
	skill_names.sort()
	return skill_names

func get_skill_value_map_for_peer(peer_id: int) -> Dictionary:
	var source_player: PlayerData = PlayerVariables.data
	if membersCharacters.has(peer_id):
		source_player = membersCharacters[peer_id] as PlayerData
	var skill_values := {}
	if source_player == null:
		return skill_values
	for skill: Skill in source_player.skills:
		if skill != null and not skill._name.is_empty():
			skill_values[skill._name] = skill.value
	return skill_values

func get_selectable_player_peers() -> Array[Dictionary]:
	var players: Array[Dictionary] = []
	var peer_ids: Array = membersByPeerId.keys()
	peer_ids.sort()
	for peer_id_variant in peer_ids:
		var peer_id := int(peer_id_variant)
		if peer_id <= 0 or peer_id == multiplayer.get_unique_id():
			continue
		var peer_name := str(membersByPeerId.get(peer_id, "")).strip_edges()
		if peer_name.is_empty() or peer_name == "Connecting..." or peer_name == "GameMaster":
			continue
		players.append({
			"peer_id": peer_id,
			"name": peer_name,
		})
	return players

func has_active_gm_connection() -> bool:
	return not is_host_role and multiplayer.multiplayer_peer != null and not membersByPeerId.is_empty()

func _generate_skill_check_request_id() -> String:
	return "%s_%s" % [multiplayer.get_unique_id(), Time.get_ticks_msec()]

func _append_combat_log_local(senderPeerId: int, combat_line: String, tooltip: String = "") -> void:
	var senderName: String
	if membersByPeerId.has(senderPeerId):
		senderName = str(membersByPeerId[senderPeerId])
	else:
		senderName = "Peer " + str(senderPeerId)

	if senderPeerId == multiplayer.get_unique_id():
		senderName += " (You)"

	var message_text := _escape_bbcode_text(senderName + ": " + combat_line)
	var _tooltip_text := _escape_bbcode_text(tooltip)
	_append_log_line(combat_log, message_text, _tooltip_text)
	_append_log_line(all_logs, message_text, _tooltip_text)

func _append_skill_check_log_local(senderPeerId: int, combat_line: String, tooltip: String = "") -> void:
	var senderName: String
	if membersByPeerId.has(senderPeerId):
		senderName = str(membersByPeerId[senderPeerId])
	else:
		senderName = "Peer " + str(senderPeerId)

	if senderPeerId == multiplayer.get_unique_id():
		senderName += " (You)"

	var message_text := _escape_bbcode_text(senderName + ": " + combat_line)
	var _tooltip_text := _escape_bbcode_text(tooltip)
	_append_log_line(skill_check_log, message_text, _tooltip_text)
	_append_log_line(all_logs, message_text, _tooltip_text)

func _show_local_skill_check_window(requested_skill_name: String) -> void:
	var window := SkillCheckWindow.new()
	add_child(window)
	window.configure_local_setup(get_local_skill_names(), requested_skill_name)
	window.local_check_requested.connect(_resolve_local_skill_check)
	window.popup_centered()

func _show_gm_skill_check_window(request_payload: Dictionary) -> void:
	var window := SkillCheckWindow.new()
	add_child(window)
	window.configure_gm_setup(get_skill_names_for_peer(int(request_payload.get("requester_peer_id", 0))), str(request_payload.get("requester_name", "Player")), str(request_payload.get("requested_skill", "")))
	window.gm_offer_approved.connect(_approve_skill_check_offer.bind(request_payload))
	window.request_cancelled.connect(_rebuild_notifications)
	window.popup_centered()

func _show_player_choice_window(offer_payload: Dictionary) -> void:
	var window := SkillCheckWindow.new()
	add_child(window)
	window.configure_player_choice(str(offer_payload.get("requester_name", PlayerVariables.getName())), offer_payload.get("options", []), get_local_skill_value_map())
	window.option_chosen.connect(_submit_skill_check_choice.bind(str(offer_payload.get("request_id", ""))))
	window.request_cancelled.connect(_rebuild_notifications)
	window.popup_centered()

func _approve_skill_check_offer(options: Array[Dictionary], request_payload: Dictionary) -> void:
	var request_id := str(request_payload.get("request_id", ""))
	if request_id.is_empty():
		return
	var sanitized_options := _sanitize_skill_check_options(options)
	if sanitized_options.is_empty():
		return
	var offer_payload := {
		"request_id": request_id,
		"requester_peer_id": int(request_payload.get("requester_peer_id", 0)),
		"requester_name": str(request_payload.get("requester_name", "")),
		"requested_skill": str(request_payload.get("requested_skill", "")),
		"options": sanitized_options,
	}
	pending_skill_check_offers[request_id] = offer_payload
	_rebuild_notifications()
	var requester_peer_id := int(offer_payload.get("requester_peer_id", 0))
	if requester_peer_id == multiplayer.get_unique_id():
		client_receive_skill_check_offer(offer_payload)
	else:
		rpc_id(requester_peer_id, "client_receive_skill_check_offer", offer_payload)

func _resolve_local_skill_check(options: Array[Dictionary], selected_skill_name: String) -> void:
	var selected_option := _find_skill_check_option(options, selected_skill_name)
	if selected_option.is_empty():
		return
	var result := RuleEngine.resolveSkillCheck(PlayerVariables.data, selected_skill_name, int(selected_option.get("difficulty", 0)), {"source_name": PlayerVariables.getName()})
	if not bool(result.get("success", false)):
		return
	var game_event := _build_skill_check_game_event({
		"request_id": _generate_skill_check_request_id(),
		"requester_peer_id": multiplayer.get_unique_id(),
		"requester_name": PlayerVariables.getName(),
		"requested_skill": selected_skill_name,
		"options": _sanitize_skill_check_options(options),
	}, result)
	CampaignVariables.appendGameEvent(game_event)
	apply_game_event(game_event)

func _submit_skill_check_choice(selected_skill_name: String, request_id: String) -> void:
	if request_id.is_empty():
		return
	var payload := {
		"request_id": request_id,
		"selected_skill_name": selected_skill_name,
	}
	rpc_id(1, "server_receive_skill_check_choice", payload)

func _sanitize_skill_check_options(options: Array[Dictionary]) -> Array[Dictionary]:
	var sanitized: Array[Dictionary] = []
	var used_skill_names: Array[String] = []
	var found_primary := false
	for option in options:
		var skill_name := str(option.get("skill_name", "")).strip_edges()
		if skill_name.is_empty() or used_skill_names.has(skill_name):
			continue
		var is_primary := bool(option.get("is_primary", false))
		if is_primary and found_primary:
			continue
		found_primary = found_primary or is_primary
		used_skill_names.append(skill_name)
		sanitized.append({
			"skill_name": skill_name,
			"difficulty": maxi(int(option.get("difficulty", 0)), 0),
			"is_primary": is_primary,
		})
	if not found_primary and not sanitized.is_empty():
		sanitized[0]["is_primary"] = true
	return sanitized

func _find_skill_check_option(options: Variant, skill_name: String) -> Dictionary:
	if not (options is Array):
		return {}
	for option in options:
		if option is Dictionary and str(option.get("skill_name", "")) == skill_name:
			return option
	return {}

func _build_skill_check_game_event(offer_payload: Dictionary, result: Dictionary) -> GameEvent:
	var requester_peer_id := int(offer_payload.get("requester_peer_id", multiplayer.get_unique_id()))
	var result_payload := result.duplicate(true)
	result_payload["request_id"] = str(offer_payload.get("request_id", ""))
	result_payload["requester_peer_id"] = requester_peer_id
	result_payload["requester_name"] = str(offer_payload.get("requester_name", result.get("source_name", "")))
	result_payload["requested_skill"] = str(offer_payload.get("requested_skill", result.get("skill_name", "")))
	result_payload["options"] = offer_payload.get("options", [])
	return GameEvent.new(
		"skill_check_resolved",
		GameEvent.CONTEXT_SKILL_CHECK,
		result_payload,
		[],
		[{"text": str(result.get("text", "")), "tooltip": str(result.get("tooltip", "")), "requester_peer_id": requester_peer_id}]
	)

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
		var request_id := str(game_event.payload.get("request_id", ""))
		if not request_id.is_empty():
			pending_skill_check_offers.erase(request_id)
			pending_skill_check_requests.erase(request_id)
		_rebuild_notifications()
		var sender_peer_id := int(game_event.payload.get("requester_peer_id", 1))
		for result in game_event.results:
			if result is Dictionary:
				var result_sender := int(result.get("requester_peer_id", sender_peer_id))
				_append_skill_check_log_local(result_sender, str(result.get("text", "")), str(result.get("tooltip", "")))
			else:
				_append_skill_check_log_local(sender_peer_id, str(result))
		_focus_skill_check_log_for_local_request(game_event)

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
func server_receive_skill_check_request(request_payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id := multiplayer.get_remote_sender_id()
	if sender_peer_id == 0:
		sender_peer_id = multiplayer.get_unique_id()
	var normalized_payload := request_payload.duplicate(true)
	normalized_payload["requester_peer_id"] = sender_peer_id
	normalized_payload["requester_name"] = str(membersByPeerId.get(sender_peer_id, normalized_payload.get("requester_name", "Player")))
	var request_id := str(normalized_payload.get("request_id", ""))
	if request_id.is_empty():
		return
	pending_skill_check_requests[request_id] = normalized_payload
	_rebuild_notifications()

@rpc("authority", "call_local", "reliable")
func client_receive_skill_check_offer(offer_payload: Dictionary) -> void:
	var request_id := str(offer_payload.get("request_id", ""))
	if request_id.is_empty():
		return
	pending_skill_check_offers[request_id] = offer_payload.duplicate(true)
	_rebuild_notifications()

@rpc("any_peer", "reliable")
func server_receive_skill_check_choice(choice_payload: Dictionary) -> void:
	if not multiplayer.is_server():
		return
	var sender_peer_id := multiplayer.get_remote_sender_id()
	if sender_peer_id == 0:
		sender_peer_id = multiplayer.get_unique_id()
	var request_id := str(choice_payload.get("request_id", ""))
	if request_id.is_empty() or not pending_skill_check_offers.has(request_id):
		return
	var offer_payload := pending_skill_check_offers[request_id] as Dictionary
	if int(offer_payload.get("requester_peer_id", -1)) != sender_peer_id:
		return
	var selected_skill_name := str(choice_payload.get("selected_skill_name", ""))
	var selected_option := _find_skill_check_option(offer_payload.get("options", []), selected_skill_name)
	if selected_option.is_empty() or not membersCharacters.has(sender_peer_id):
		return
	var player_data := membersCharacters[sender_peer_id] as PlayerData
	if player_data == null:
		return
	var result := RuleEngine.resolveSkillCheck(player_data, selected_skill_name, int(selected_option.get("difficulty", 0)), {
		"source_name": str(offer_payload.get("requester_name", membersByPeerId.get(sender_peer_id, "Player"))),
	})
	if not bool(result.get("success", false)):
		return
	var game_event := _build_skill_check_game_event(offer_payload, result)
	pending_skill_check_requests.erase(request_id)
	pending_skill_check_offers.erase(request_id)
	_rebuild_notifications()
	broadcast_game_event(game_event)

func _rebuild_notifications() -> void:
	if notification_inbox == null:
		return
	for child in notification_inbox.get_children():
		child.queue_free()
	var notification_count := 0

	var gm_request_ids: Array = pending_skill_check_requests.keys()
	gm_request_ids.sort()
	if is_host_role:
		_add_notification_section("Skill Requests")
		if gm_request_ids.is_empty():
			_add_notification_empty_state("No skill requests waiting.")
		for request_id_variant in gm_request_ids:
			var request_id := str(request_id_variant)
			var payload = pending_skill_check_requests.get(request_id, {})
			if payload.is_empty():
				continue
			notification_count += 1
			var button := Button.new()
			button.text = "Review %s: %s" % [str(payload.get("requester_name", "Player")), str(payload.get("requested_skill", "Skill"))]
			button.pressed.connect(_open_gm_notification.bind(request_id))
			notification_inbox.add_child(button)

	var offer_ids: Array = pending_skill_check_offers.keys()
	offer_ids.sort()
	_add_notification_section("Choices Waiting")
	if offer_ids.is_empty():
		_add_notification_empty_state("No skill choices waiting.")
	for request_id_variant in offer_ids:
		var request_id := str(request_id_variant)
		var offer = pending_skill_check_offers.get(request_id, {})
		if offer.is_empty():
			continue
		if is_host_role and int(offer.get("requester_peer_id", -1)) != multiplayer.get_unique_id():
			continue
		notification_count += 1
		var button := Button.new()
		button.text = "Choose skill for %s" % str(offer.get("requester_name", "Player"))
		button.pressed.connect(_open_player_notification.bind(request_id))
		notification_inbox.add_child(button)

	_update_notifications_tab_title(notification_count)
	_update_container_title(notification_count)

func _update_notifications_tab_title(notification_count: int) -> void:
	if log_tabs == null:
		return
	for idx in range(log_tabs.get_tab_count()):
		if log_tabs.get_tab_control(idx) == notification_inbox.get_parent():
			log_tabs.set_tab_title(idx, "Notifications (%s)" % notification_count if notification_count > 0 else "Notifications")
			return

func _update_container_title(notification_count: int) -> void:
	title = "Log (%s)" % notification_count if notification_count > 0 else "Log"

func _focus_skill_check_log_for_local_request(game_event: GameEvent) -> void:
	if game_event == null:
		return
	var requester_peer_id := int(game_event.payload.get("requester_peer_id", -1))
	if requester_peer_id != multiplayer.get_unique_id():
		return
	if log_tabs != null:
		for idx in range(log_tabs.get_tab_count()):
			var tab_control := log_tabs.get_tab_control(idx)
			if tab_control != null and tab_control.name == "Logs":
				log_tabs.current_tab = idx
				break
	if nested_log_tabs != null:
		for idx in range(nested_log_tabs.get_tab_count()):
			var tab_control := nested_log_tabs.get_tab_control(idx)
			if tab_control != null and tab_control.name == "SkillCheckLog":
				nested_log_tabs.current_tab = idx
				break

func _add_notification_section(title_text: String) -> void:
	var label := Label.new()
	label.text = title_text
	notification_inbox.add_child(label)

func _add_notification_empty_state(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	notification_inbox.add_child(label)

func _open_gm_notification(request_id: String) -> void:
	if not pending_skill_check_requests.has(request_id):
		return
	_show_gm_skill_check_window(pending_skill_check_requests[request_id])

func _open_player_notification(request_id: String) -> void:
	if not pending_skill_check_offers.has(request_id):
		return
	_show_player_choice_window(pending_skill_check_offers[request_id])

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
