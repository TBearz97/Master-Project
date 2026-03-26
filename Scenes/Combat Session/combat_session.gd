extends Control

const COMBATANT_ENTRY_SCENE := preload("res://Scenes/Combat Session/combatant_entry.tscn")

@onready var combatantList: VBoxContainer = %Combatants
@onready var roundLabel: Label = %RoundLabel
@onready var phaseLabel: Label = %PhaseLabel
@onready var inspectorContent: VBoxContainer = %InspectorContent
@onready var inspectorTitle: Label = %InspectorTitle
@onready var inspectorType: Label = %InspectorType
@onready var inspectorHP: Label = %InspectorHP
@onready var inspectorLevel: Label = %InspectorLevel
@onready var inspectorDetails: RichTextLabel = %InspectorDetails
@onready var inspectorLoadout: Label = %InspectorLoadout
@onready var inspectorSwapLoadout: Button = %InspectorSwapLoadout
@onready var inspectorActionsList: VBoxContainer = %InspectorActionsList
@onready var playerActionsContent: VBoxContainer = %PlayerActionsContent
@onready var playerCombatantName: Label = %PlayerCombatantName
@onready var playerLoadout: Label = %PlayerLoadout
@onready var playerSwapLoadout: Button = %PlayerSwapLoadout
@onready var playerActionsList: VBoxContainer = %PlayerActionsList
@onready var playerActionsHint: Label = %PlayerActionsHint

var npc_picker: ConfirmationDialog
var npc_picker_list: VBoxContainer
var selected_combatant_entry: CombatantEntry = null
var selected_combatant_id: String = ""
var encounter_started: bool = false
# Encounter state is mirrored locally from CampaignManager so this scene can
# render and refresh rows without owning the network RPC layer itself.
var encounter_combatants: Dictionary = {}
var combatant_entries: Dictionary = {}
var next_combatant_id: int = 1
var is_host_role: bool = false
var round_number: int = 1
var current_phase: String = GameEvent.PHASE_PLANNING

func _ready() -> void:
	_setup_npc_picker()
	_clear_inspector()
	%StartEncounter.pressed.connect(_start_encounter)
	%EndEncounter.pressed.connect(_end_encounter)
	%AddPlayers.pressed.connect(_addPlayers)
	%AddNPCs.pressed.connect(_addNPCs)
	playerSwapLoadout.pressed.connect(_swap_local_player_loadout)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.encounter_state_changed.connect(_on_encounter_state_changed)
		campaign_manager.authority_role_changed.connect(_on_authority_role_changed)
		encounter_started = campaign_manager.has_started_encounter()
		is_host_role = campaign_manager.is_host_authority()
	PlayerVariables.combat_loadout_changed.connect(_on_local_combat_loadout_changed)
	_configure_role_view()
	_update_round_ui()
	_apply_encounter_visibility()
	_refresh_player_actions()

func _update_round_ui() -> void:
	roundLabel.text = "Round: %s" % round_number
	phaseLabel.text = "Phase: %s" % current_phase.capitalize()

func _configure_role_view() -> void:
	inspectorContent.visible = is_host_role
	playerActionsContent.visible = not is_host_role
	inspectorSwapLoadout.visible = false

func _apply_encounter_visibility() -> void:
	var is_tab_page := get_parent() is TabContainer
	visible = true if is_tab_page else is_host_role or encounter_started
	%StartEncounter.visible = is_host_role and not encounter_started
	%EndEncounter.visible = is_host_role and encounter_started
	%AddPlayers.visible = is_host_role
	%AddNPCs.visible = is_host_role

func _on_encounter_state_changed(started: bool) -> void:
	encounter_started = started
	_apply_encounter_visibility()

func _on_authority_role_changed(is_host: bool) -> void:
	is_host_role = is_host
	_configure_role_view()
	_apply_encounter_visibility()
	_refresh_player_actions()

func _start_encounter() -> void:
	if not is_host_role:
		return
	round_number = 1
	current_phase = GameEvent.PHASE_PLANNING
	_update_round_ui()
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		push_error("Combat session could not find CampaignManager in the scene tree.")
		return
	campaign_manager.broadcast_encounter_started(true)

func _end_encounter() -> void:
	if not is_host_role:
		return
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		push_error("Combat session could not find CampaignManager in the scene tree.")
		return
	campaign_manager.broadcast_combat_reset()


func _setup_npc_picker() -> void:
	npc_picker = ConfirmationDialog.new()
	npc_picker.title = "Select NPC"
	npc_picker.size = Vector2i(360, 500)
	npc_picker.exclusive = false
	npc_picker.get_cancel_button().text = "Close"
	add_child(npc_picker)

	npc_picker_list = VBoxContainer.new()
	npc_picker.add_child(npc_picker_list)


func _addPlayers() -> void:
	if not is_host_role:
		return

	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		push_error("Combat session could not find CampaignManager in the scene tree.")
		return

	for peer_id in campaign_manager.membersCharacters.keys():
		var player_data = campaign_manager.membersCharacters[peer_id]
		if player_data is PlayerData:
			_add_combatant_entry(_build_player_payload(player_data, peer_id))
	
func _addNPCs() -> void:
	if not is_host_role:
		return

	for child in npc_picker_list.get_children():
		child.queue_free()

	var npc_names: Array = CampaignVariables.codex.NPCs.keys()
	npc_names.sort()

	for npc_name_variant in npc_names:
		var npc_name := str(npc_name_variant)
		var npc: NPC = CampaignVariables.codex.NPCs.get(npc_name, null)
		if npc == null:
			continue

		var button := Button.new()
		button.text = npc._name
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = npc.short_description
		button.pressed.connect(_on_npc_selected.bind(npc))
		npc_picker_list.add_child(button)

	npc_picker.popup_centered()

func _on_npc_selected(npc: NPC) -> void:
	_add_combatant_entry(_build_npc_payload(npc))
	npc_picker.hide()

func _add_combatant_entry(combatant_payload: Dictionary) -> void:
	if not is_host_role:
		return
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		push_error("Combat session could not find CampaignManager in the scene tree.")
		return
	campaign_manager.broadcast_combatant_spawn(combatant_payload)

func spawn_combatant_locally(combatant_payload: Dictionary) -> void:
	var combatant_id := str(combatant_payload.get("id", ""))
	encounter_combatants[combatant_id] = combatant_payload.duplicate(true)

	# Reuse the existing row when a payload update comes in so selection state and
	# inspector updates survive combatant refreshes.
	if combatant_entries.has(combatant_id):
		var existing_entry: CombatantEntry = combatant_entries[combatant_id]
		if is_instance_valid(existing_entry):
			existing_entry.setup(combatant_payload)
		else:
			combatant_entries.erase(combatant_id)

	if not combatant_entries.has(combatant_id):
		var entry := _build_combatant_entry(combatant_payload)
		combatant_entries[combatant_id] = entry
		combatantList.add_child(entry)

	if selected_combatant_id == combatant_id:
		_show_inspector(combatant_payload)

	_refresh_player_actions()

func update_combatant_locally(combatant_payload: Dictionary) -> void:
	spawn_combatant_locally(combatant_payload)

func apply_game_event(game_event: GameEvent) -> void:
	if game_event == null:
		return

	if game_event.round_number > 0:
		round_number = game_event.round_number
	if not game_event.phase.is_empty():
		current_phase = game_event.phase

	for change_variant in game_event.state_changes:
		if change_variant is Dictionary:
			_apply_combatant_state_change(change_variant)

	if not game_event.results.is_empty():
		var campaign_manager := _find_campaign_manager()
		if campaign_manager != null:
			for result in game_event.results:
				campaign_manager._add_combat_log(str(result))

	_refresh_player_actions()
	_update_round_ui()

func apply_combat_request(combat_request: CombatRequest) -> void:
	if combat_request == null:
		return

	match combat_request.request_type:
		CombatRequest.TYPE_QUEUE_UPDATED, CombatRequest.TYPE_ACTION:
			_apply_combat_request_preview(combat_request)
		CombatRequest.TYPE_MOVEMENT:
			_apply_combat_request_preview(combat_request)

func _apply_combat_request_preview(combat_request: CombatRequest) -> void:
	var combatant_id := combat_request.combatant_id
	if combatant_id.is_empty() or not encounter_combatants.has(combatant_id):
		return

	var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
	payload["pending_request"] = combat_request.payload.get("preview_text", "")
	encounter_combatants[combatant_id] = payload
	if combatant_entries.has(combatant_id):
		var existing_entry: CombatantEntry = combatant_entries[combatant_id]
		if is_instance_valid(existing_entry):
			existing_entry.setup(payload)

	if selected_combatant_id == combatant_id:
		_show_inspector(payload)

func _apply_combatant_state_change(change: Dictionary) -> void:
	var combatant_id := str(change.get("combatant_id", ""))
	if combatant_id.is_empty() or not encounter_combatants.has(combatant_id):
		return

	var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
	payload.erase("pending_request")
	for key in change.keys():
		if key == "combatant_id":
			continue
		payload[key] = change[key]

	update_combatant_locally(payload)

func reset_combat_session_locally() -> void:
	encounter_combatants.clear()
	combatant_entries.clear()
	next_combatant_id = 1
	round_number = 1
	current_phase = GameEvent.PHASE_PLANNING
	_clear_combatants()
	_clear_inspector()
	_clear_player_actions()
	_update_round_ui()
	selected_combatant_entry = null
	selected_combatant_id = ""
	if npc_picker != null:
		npc_picker.hide()

func _build_combatant_entry(combatant_payload: Dictionary) -> CombatantEntry:
	var entry := COMBATANT_ENTRY_SCENE.instantiate() as CombatantEntry
	entry.setup(combatant_payload)
	entry.selected.connect(_on_combatant_selected)
	entry.name = _build_combatant_node_name(combatant_payload)
	return entry

func _build_player_payload(player_data: PlayerData, peer_id: int) -> Dictionary:
	var details := [
		"Peer ID: %s" % peer_id,
		"Attributes: %s" % _format_attribute_values(player_data.attributes),
		"Actions: %s" % _format_player_action_names(player_data),
		"Conditions: %s" % _format_name_list(player_data.conditions),
	]
	return {
		"id": _create_combatant_id("player_%s" % peer_id),
		"name": player_data._name,
		"type": "Player",
		"controller_peer_id": peer_id,
		"active_loadout": 1,
		"action_points": 2,
		"remaining_action_points": 2,
		"queued_actions": [],
		"movement_choice": {},
		"current_hp": player_data.currentHP,
		"max_hp": player_data.maxHP,
		"level": player_data.level,
		"details": "\n".join(details),
		"actions": _get_player_action_entries(player_data, 1),
		"action_names": _get_player_action_names(player_data, 1),
		"peer_id": peer_id,
	}

func _build_npc_payload(npc: NPC) -> Dictionary:
	var details := [
		npc.short_description,
		"Attributes: %s" % _format_attribute_values(npc.data.attributes),
		"Actions: %s" % _format_name_list(npc.data.actions),
		"Conditions: %s" % _format_name_list(npc.data.conditions),
	]
	return {
		"id": _create_combatant_id("npc_%s" % npc._name.to_snake_case()),
		"name": npc._name,
		"type": "NPC",
		"controller_peer_id": 0,
		"active_loadout": 1,
		"action_points": 2,
		"remaining_action_points": 2,
		"queued_actions": [],
		"movement_choice": {},
		"current_hp": npc.data.currentHP,
		"max_hp": npc.data.maxHP,
		"level": npc.data.level,
		"details": "\n".join(details),
		"actions": _get_npc_action_entries(npc, 1),
		"action_names": _get_npc_action_names(npc, 1),
	}

func _create_combatant_id(prefix: String) -> String:
	var combatant_id := "%s_%s" % [prefix, next_combatant_id]
	next_combatant_id += 1
	return combatant_id

func _build_combatant_node_name(combatant_payload: Dictionary) -> String:
	var base_name := "%s_%s" % [str(combatant_payload.get("type", "Combatant")), str(combatant_payload.get("name", "Unnamed"))]
	return base_name.replace("/", "_").replace("\\", "_").replace(":", "")

func _on_combatant_selected(entry: CombatantEntry, combatant_payload: Dictionary) -> void:
	if selected_combatant_entry != null and is_instance_valid(selected_combatant_entry):
		selected_combatant_entry.set_selected(false)

	selected_combatant_entry = entry
	selected_combatant_id = str(combatant_payload.get("id", ""))
	selected_combatant_entry.set_selected(true)
	_show_inspector(combatant_payload)

func _show_inspector(combatant_payload: Dictionary) -> void:
	inspectorTitle.text = str(combatant_payload.get("name", "Combatant Inspector"))
	inspectorType.text = "Type: %s" % combatant_payload.get("type", "NA")
	inspectorHP.text = "HP: %s/%s" % [combatant_payload.get("current_hp", 0), combatant_payload.get("max_hp", 0)]
	inspectorLevel.text = "Level: %s" % combatant_payload.get("level", 0)
	inspectorLoadout.text = "Loadout: %s" % combatant_payload.get("active_loadout", 1)
	var details_text := str(combatant_payload.get("details", "No details available."))
	var queued_actions: Array = combatant_payload.get("queued_actions", [])
	if not queued_actions.is_empty():
		details_text += "\nQueued Actions: %s" % ", ".join(queued_actions)
	var pending_request := str(combatant_payload.get("pending_request", ""))
	if not pending_request.is_empty():
		details_text += "\nPending Request: %s" % pending_request
	inspectorDetails.text = details_text
	_populate_action_list(inspectorActionsList, combatant_payload.get("actions", []), false)

func _clear_inspector() -> void:
	inspectorTitle.text = "Combatant Inspector"
	inspectorType.text = "Type:"
	inspectorHP.text = "HP:"
	inspectorLevel.text = "Level:"
	inspectorLoadout.text = "Loadout: 1"
	inspectorDetails.text = "Click a combatant to inspect them."
	_populate_action_list(inspectorActionsList, [], false)

func _clear_player_actions() -> void:
	playerCombatantName.text = "No combatant selected."
	playerLoadout.text = "Loadout: 1"
	playerSwapLoadout.disabled = true
	playerActionsHint.text = "You are not currently in this encounter."
	_populate_action_list(playerActionsList, [], true)

func _refresh_player_actions() -> void:
	if is_host_role:
		return

	var local_peer_id := multiplayer.get_unique_id()
	var local_payload := _find_local_player_combatant(local_peer_id)
	if local_payload.is_empty():
		_clear_player_actions()
		return

	# Players rebuild their own actions from local PlayerVariables so weapon swaps
	# update immediately instead of waiting for the host snapshot to refresh.
	var runtime_payload := _build_local_player_runtime_payload(local_payload)
	playerCombatantName.text = str(runtime_payload.get("name", "Unknown"))
	playerLoadout.text = "Loadout: %s" % runtime_payload.get("active_loadout", 1)
	playerSwapLoadout.disabled = false
	playerActionsHint.text = "Choose an action when your turn comes up."
	_populate_action_list(playerActionsList, runtime_payload.get("actions", []), true)

func _on_local_combat_loadout_changed() -> void:
	if is_host_role:
		return

	_refresh_player_actions()

	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		return

	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return

	# The player view stays local-first, but we still push the rebuilt payload to
	# the host so the GM and other peers see the updated loadout/actions.
	var runtime_payload := _build_local_player_runtime_payload(local_payload)
	campaign_manager.submit_local_player_combatant_update(runtime_payload)

func _swap_local_player_loadout() -> void:
	if is_host_role:
		return
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		return
	var next_loadout := _get_next_loadout(int(local_payload.get("active_loadout", 1)))
	local_payload["active_loadout"] = next_loadout
	encounter_combatants[str(local_payload.get("id", ""))] = local_payload
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.broadcast_combat_request(CombatRequest.new(
			CombatRequest.TYPE_QUEUE_UPDATED,
			str(local_payload.get("id", "")),
			"",
			{"preview_text": "Swap Loadout -> %s" % next_loadout}
		))
	_on_local_combat_loadout_changed()

func _find_local_player_combatant(local_peer_id: int) -> Dictionary:
	for combatant_id in encounter_combatants.keys():
		var payload: Dictionary = encounter_combatants[combatant_id]
		if int(payload.get("controller_peer_id", 0)) == local_peer_id:
			return payload
	return {}

func _build_local_player_runtime_payload(base_payload: Dictionary) -> Dictionary:
	var payload := base_payload.duplicate(true)
	var player_data := PlayerVariables.data
	var active_loadout := int(payload.get("active_loadout", 1))
	payload["current_hp"] = player_data.currentHP
	payload["max_hp"] = player_data.maxHP
	payload["level"] = player_data.level
	payload["active_loadout"] = active_loadout
	payload["details"] = "\n".join([
		"Peer ID: %s" % multiplayer.get_unique_id(),
		"Attributes: %s" % _format_attribute_values(player_data.attributes),
		"Actions: %s" % _format_player_action_names(player_data, active_loadout),
		"Conditions: %s" % _format_name_list(player_data.conditions),
	])
	payload["actions"] = _get_player_action_entries(player_data, active_loadout)
	payload["action_names"] = _get_player_action_names(player_data, active_loadout)
	return payload

func _rebuild_combatant_payload(base_payload: Dictionary, active_loadout: int) -> Dictionary:
	var payload := base_payload.duplicate(true)
	payload["active_loadout"] = active_loadout
	if str(payload.get("type", "")) == "Player":
		# Player combatants are rebuilt from the host-side copy of that player's
		# registered data so the GM stays authoritative over encounter state.
		var peer_id := int(payload.get("controller_peer_id", 0))
		var campaign_manager := _find_campaign_manager()
		if campaign_manager == null or not campaign_manager.membersCharacters.has(peer_id):
			return {}
		var player_data: PlayerData = campaign_manager.membersCharacters[peer_id]
		payload["current_hp"] = player_data.currentHP
		payload["max_hp"] = player_data.maxHP
		payload["level"] = player_data.level
		payload["details"] = "\n".join([
			"Peer ID: %s" % peer_id,
			"Attributes: %s" % _format_attribute_values(player_data.attributes),
			"Actions: %s" % _format_player_action_names(player_data, active_loadout),
			"Conditions: %s" % _format_name_list(player_data.conditions),
		])
		payload["actions"] = _get_player_action_entries(player_data, active_loadout)
		payload["action_names"] = _get_player_action_names(player_data, active_loadout)
		return payload
	var npc: NPC = CampaignVariables.codex.NPCs.get(str(payload.get("name", "")), null)
	if npc == null:
		return {}
	payload["current_hp"] = npc.data.currentHP
	payload["max_hp"] = npc.data.maxHP
	payload["level"] = npc.data.level
	payload["details"] = "\n".join([
		npc.short_description,
		"Attributes: %s" % _format_attribute_values(npc.data.attributes),
		"Actions: %s" % _format_name_list(npc.data.actions),
		"Conditions: %s" % _format_name_list(npc.data.conditions),
	])
	payload["actions"] = _get_npc_action_entries(npc, active_loadout)
	payload["action_names"] = _get_npc_action_names(npc, active_loadout)
	return payload

func _get_next_loadout(active_loadout: int) -> int:
	return 2 if active_loadout == 1 else 1

func _populate_action_list(container: VBoxContainer, actions: Array, use_buttons: bool) -> void:
	for child in container.get_children():
		child.queue_free()

	if actions.is_empty():
		var empty_label := Label.new()
		empty_label.text = "No actions available."
		container.add_child(empty_label)
		return

	for action_data_variant in actions:
		var action_data: Dictionary = action_data_variant
		var action_name := str(action_data.get("name", "Unknown Action"))
		var action_source := str(action_data.get("source", "Unknown Source"))
		var action_hand := str(action_data.get("hand", "Unknown Hand"))
		var action_tooltip := "Source: %s (%s)" % [action_source, action_hand]
		var node: Control
		if use_buttons:
			var button := Button.new()
			button.text = action_name
			button.tooltip_text = action_tooltip
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			node = button
		else:
			var label := Label.new()
			label.text = action_name
			label.tooltip_text = action_tooltip
			node = label
		container.add_child(node)

func _clear_combatants() -> void:
	for child in combatantList.get_children():
		child.queue_free()

func _format_attribute_values(attributes: Array) -> String:
	var parts: Array[String] = []
	for attribute in attributes:
		if attribute is Attribute:
			parts.append("%s %s" % [attribute._name, attribute.value])
	if parts.is_empty():
		return "None"
	return ", ".join(parts)

func _format_player_action_names(player_data: PlayerData, loadout: int = 0) -> String:
	var action_names := _get_player_action_names(player_data, loadout)
	if action_names.is_empty():
		return "None"
	return ", ".join(action_names)

func _get_player_action_names(player_data: PlayerData, loadout: int = 0) -> Array[String]:
	var action_names: Array[String] = []
	for entry in _get_player_action_entries(player_data, loadout):
		action_names.append(entry.get("name", ""))
	return action_names

func _get_player_action_entries(player_data: PlayerData, loadout: int = 0) -> Array[Dictionary]:
	var action_entries: Array[Dictionary] = []
	for entry in player_data.get_available_actions(loadout):
		var action: Action = entry.get("action", null)
		if action == null:
			continue
		var weapon: Weapon = entry.get("weapon", null)
		var source := "Innate"
		var hand := str(entry.get("hand", "Innate"))
		if weapon != null and not weapon._name.is_empty():
			source = weapon._name
		action_entries.append({
			"name": action._name,
			"source": source,
			"hand": hand,
		})
	return action_entries

func _get_npc_action_names(npc: NPC, loadout: int = 0) -> Array[String]:
	var action_names: Array[String] = []
	for entry in _get_npc_action_entries(npc, loadout):
		action_names.append(entry.get("name", ""))
	return action_names

func _get_npc_action_entries(npc: NPC, loadout: int = 0) -> Array[Dictionary]:
	var action_entries: Array[Dictionary] = []
	if npc.data.has_method("get_available_actions"):
		for entry in npc.data.get_available_actions(loadout):
			var action: Action = entry.get("action", null)
			if action == null:
				continue
			var weapon: Weapon = entry.get("weapon", null)
			var source := "Innate"
			var hand := str(entry.get("hand", "Innate"))
			if weapon != null and not weapon._name.is_empty():
				source = weapon._name
			action_entries.append({
				"name": action._name,
				"source": source,
				"hand": hand,
			})
		return action_entries

	for action in npc.data.actions:
		if action is Action:
			action_entries.append({
				"name": action._name,
				"source": "Innate",
				"hand": "Innate",
			})
	return action_entries

func _format_name_list(values: Array) -> String:
	var names: Array[String] = []
	for value in values:
		if value is CodexItem:
			names.append(value._name)
		else:
			names.append(str(value))
	if names.is_empty():
		return "None"
	return ", ".join(names)

func _find_campaign_manager() -> Node:
	return _find_node_by_name(get_tree().root, "CampaignManager")

func _find_node_by_name(node: Node, target_name: String) -> Node:
	if node.name == target_name:
		return node

	for child in node.get_children():
		var result := _find_node_by_name(child, target_name)
		if result != null:
			return result

	return null
