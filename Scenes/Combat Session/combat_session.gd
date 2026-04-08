extends Control

const COMBATANT_ENTRY_SCENE := preload("res://Scenes/Combat Session/combatant_entry.tscn")
const ACTION_ENTRY_SCENE := preload("res://Scenes/Combat Session/action_entry.tscn")

@onready var combatantList: VBoxContainer = %Combatants
@onready var roundLabel: Label = %RoundLabel
@onready var phaseLabel: Label = %PhaseLabel
@onready var endMovementPhaseButton: Button = %EndMovementPhase
@onready var endActionPhaseButton: Button = %EndActionPhase
@onready var autoQueueNPCsButton: Button = %AutoQueueNPCs
@onready var queuedActionsList: VBoxContainer = %QueuedActions
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
@onready var actionResolutionWindow: Window = %ActionResolutionWindow
@onready var resolutionTitle: Label = %ResolutionTitle
@onready var resolutionProgress: Label = %ResolutionProgress
@onready var resolutionDetails: RichTextLabel = %ResolutionDetails
@onready var abortActionButton: Button = %AbortAction
@onready var resolveActionButton: Button = %ResolveAction
@onready var resolveAllActionsButton: Button = %ResolveAllActions

var npc_picker: ConfirmationDialog
var npc_picker_list: VBoxContainer
var selected_combatant_entry: CombatantEntry = null
var selected_combatant_id: String = ""
var pending_player_action: Dictionary = {}
var pending_resolution_requests: Array[CombatRequest] = []
var is_reviewing_action_phase: bool = false
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
	endMovementPhaseButton.pressed.connect(_end_movement_phase)
	endActionPhaseButton.pressed.connect(_end_action_phase)
	autoQueueNPCsButton.pressed.connect(_auto_queue_npc_actions)
	playerSwapLoadout.pressed.connect(_swap_local_player_loadout)
	playerSwapLoadout.visible = false
	actionResolutionWindow.close_requested.connect(_on_action_resolution_window_close_requested)
	abortActionButton.pressed.connect(_abort_current_action_resolution)
	resolveActionButton.pressed.connect(_resolve_current_action_resolution)
	resolveAllActionsButton.pressed.connect(_resolve_all_action_resolutions)
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
	_refresh_queued_actions()
	_refresh_player_actions()

func _update_round_ui() -> void:
	roundLabel.text = "Round: %s" % round_number
	var phase_name := "Planning"
	match current_phase:
		GameEvent.PHASE_PLANNING:
			phase_name = "Movement"
		GameEvent.PHASE_EXECUTION:
			phase_name = "Action"
		GameEvent.PHASE_RESOLUTION:
			phase_name = "Resolution"
	phaseLabel.text = "Phase: %s" % phase_name
	_update_phase_buttons()

func _update_phase_buttons() -> void:
	endMovementPhaseButton.visible = is_host_role and encounter_started and current_phase == GameEvent.PHASE_PLANNING and not is_reviewing_action_phase
	endActionPhaseButton.visible = is_host_role and encounter_started and current_phase == GameEvent.PHASE_EXECUTION and not is_reviewing_action_phase
	autoQueueNPCsButton.visible = is_host_role and encounter_started and current_phase == GameEvent.PHASE_EXECUTION and not is_reviewing_action_phase

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
	_update_phase_buttons()

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
	_refresh_queued_actions()
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
			_configure_combatant_entry_interaction(existing_entry, combatant_payload)
		else:
			combatant_entries.erase(combatant_id)

	if not combatant_entries.has(combatant_id):
		var entry := _build_combatant_entry(combatant_payload)
		combatant_entries[combatant_id] = entry
		combatantList.add_child(entry)

	if selected_combatant_id == combatant_id:
		_show_inspector(combatant_payload)

	_refresh_player_actions()
	_refresh_queued_actions()

func update_combatant_locally(combatant_payload: Dictionary) -> void:
	spawn_combatant_locally(combatant_payload)

func apply_game_event(game_event: GameEvent) -> void:
	if game_event == null:
		return

	if game_event.round_number > 0:
		round_number = game_event.round_number
	if not game_event.phase.is_empty():
		current_phase = game_event.phase
		if current_phase != GameEvent.PHASE_EXECUTION:
			pending_player_action = {}

	for change_variant in game_event.state_changes:
		if change_variant is Dictionary:
			_apply_combatant_state_change(change_variant)

	if not game_event.results.is_empty():
		var campaign_manager := _find_campaign_manager()
		if campaign_manager != null:
			var sender_peer_id := 1
			for result in game_event.results:
				if result is Dictionary and result.has("text"):
					campaign_manager._append_combat_log_local(sender_peer_id, str(result.get("text", "")), str(result.get("tooltip", "")))
				else:
					campaign_manager._append_combat_log_local(sender_peer_id, str(result))

	_refresh_player_actions()
	_refresh_queued_actions()
	_update_round_ui()

func apply_combat_request(combat_request: CombatRequest) -> void:
	if combat_request == null:
		return

	match combat_request.request_type:
		CombatRequest.TYPE_QUEUE_UPDATED, CombatRequest.TYPE_ACTION:
			if bool(combat_request.payload.get("instant_resolve", false)):
				if is_host_role:
					_resolve_instant_action_request(combat_request)
			else:
				_apply_combat_request_preview(combat_request)
		CombatRequest.TYPE_MOVEMENT:
			_apply_combat_request_preview(combat_request)

func _resolve_instant_action_request(combat_request: CombatRequest) -> void:
	var source_id := combat_request.combatant_id
	if source_id.is_empty() or not encounter_combatants.has(source_id):
		return

	var source_payload: Dictionary = encounter_combatants[source_id].duplicate(true)
	var action_name := str(combat_request.payload.get("action_name", ""))
	if action_name != "Swap Loadout":
		_apply_combat_request_preview(combat_request)
		return
	var action_ap_cost := int(combat_request.payload.get("ap_cost", 1))

	var next_loadout := _get_next_loadout(int(source_payload.get("active_loadout", 1)))
	var source_update := _rebuild_combatant_payload(source_payload, next_loadout)
	if source_update.is_empty():
		return

	var remaining_ap := int(source_payload.get("remaining_action_points", source_payload.get("action_points", 0)))
	source_update["remaining_action_points"] = max(remaining_ap - action_ap_cost, 0)
	source_update["pending_request"] = ""
	source_update.erase("id")
	source_update["combatant_id"] = source_id

	var state_changes: Array[Dictionary] = [source_update]
	var results: Array[Dictionary] = [{
		"text": "%s shifts stance and changes loadouts." % source_payload.get("name", "Someone"),
		"tooltip": "%s swapped to loadout %s (%s AP)." % [source_payload.get("name", "Someone"), next_loadout, action_ap_cost],
	}]
	var game_event := GameEvent.new(
		"instant_action_resolved",
		GameEvent.CONTEXT_COMBAT,
		combat_request.payload,
		state_changes,
		results,
		round_number,
		current_phase,
		source_id,
		combat_request.target_id
	)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.broadcast_game_event(game_event)

func _resolve_queued_action(combat_request: CombatRequest) -> Dictionary:
	var source_id := combat_request.combatant_id
	var target_id := combat_request.target_id
	if source_id.is_empty() or target_id.is_empty():
		return {"state_changes": [], "results": []}
	if not encounter_combatants.has(source_id) or not encounter_combatants.has(target_id):
		return {"state_changes": [], "results": []}

	var source_payload: Dictionary = encounter_combatants[source_id].duplicate(true)
	var target_payload: Dictionary = encounter_combatants[target_id].duplicate(true)
	var source_actor := _get_actor_data_from_payload(source_payload)
	var target_actor := _get_actor_data_from_payload(target_payload)
	if source_actor == null or target_actor == null:
		return {"state_changes": [], "results": []}

	var action_name := str(combat_request.payload.get("action_name", ""))
	var action_source := str(combat_request.payload.get("action_source", "Innate"))
	var action_hand := str(combat_request.payload.get("action_hand", "Innate"))
	var active_loadout := int(source_payload.get("active_loadout", 1))
	var action_entry := _find_action_entry_for_actor(source_actor, active_loadout, action_name, action_source, action_hand)
	if action_entry.is_empty():
		var debug_message := _build_action_resolution_debug_message(source_payload, source_actor, active_loadout, action_name, action_source, action_hand)
		push_error(debug_message)
		return {"state_changes": [], "results": [{"text": debug_message}]}

	var action: Action = action_entry.get("action", null)
	var weapon: Weapon = action_entry.get("weapon", null)
	if action == null:
		return {"state_changes": [], "results": []}

	var action_context := {
		"target_location": int(combat_request.payload.get("target_location", Item.ItemSlots.Torso)),
	}
	var result = action.use(target_actor, source_actor, weapon.damage_profile if weapon != null else null, action_context)
	var action_ap_cost := RuleEngine.getActionAPCost(action, weapon)
	var action_speed := RuleEngine.getActionSpeed(action, weapon)
	if result is Dictionary:
		result["ap_cost"] = action_ap_cost
		result["action_speed"] = action_speed

	var state_changes: Array[Dictionary] = []
	var resolved_loadout := active_loadout
	if result is Dictionary and result.has("active_loadout"):
		resolved_loadout = int(result.get("active_loadout", active_loadout))
	var source_update := _rebuild_combatant_payload(source_payload, resolved_loadout)
	if not source_update.is_empty():
		source_update["pending_request"] = ""
		source_update.erase("id")
		source_update["combatant_id"] = source_id
		state_changes.append(source_update)

	if target_id != source_id:
		var target_update := _rebuild_combatant_payload(target_payload, int(target_payload.get("active_loadout", 1)))
		if not target_update.is_empty():
			target_update.erase("id")
			target_update["combatant_id"] = target_id
			state_changes.append(target_update)

	var results: Array[Dictionary] = []
	if result is Dictionary:
		var narration := _build_action_narration_entries(result as Dictionary)
		results.append(narration)

	return {"state_changes": state_changes, "results": results}

func _end_movement_phase() -> void:
	if not is_host_role or current_phase != GameEvent.PHASE_PLANNING:
		return
	var state_changes: Array[Dictionary] = []
	var results: Array[Dictionary] = [{"text": "Movement phase ended."}]
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		payload.erase("id")
		payload["combatant_id"] = combatant_id
		payload["pending_request"] = ""
		state_changes.append(payload)
	var game_event := GameEvent.new(
		"movement_phase_ended",
		GameEvent.CONTEXT_COMBAT,
		{},
		state_changes,
		results,
		round_number,
		GameEvent.PHASE_EXECUTION
	)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.broadcast_game_event(game_event)

func _end_action_phase() -> void:
	if not is_host_role or current_phase != GameEvent.PHASE_EXECUTION:
		return
	pending_resolution_requests = _get_sorted_queued_requests()
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
		return
	is_reviewing_action_phase = true
	_refresh_action_resolution_window()
	actionResolutionWindow.popup_centered()

func _auto_queue_npc_actions() -> void:
	if not is_host_role or current_phase != GameEvent.PHASE_EXECUTION:
		return

	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return

	var queued_any := false
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		if not encounter_combatants.has(combatant_id):
			continue
		var payload: Dictionary = encounter_combatants[combatant_id]
		if str(payload.get("type", "")) != "NPC":
			continue
		while true:
			payload = encounter_combatants.get(combatant_id, {})
			if payload.is_empty() or int(payload.get("remaining_action_points", payload.get("action_points", 0))) <= 0:
				break
			var queue_payload := _build_npc_queue_payload(combatant_id)
			if queue_payload.is_empty():
				break
			queued_any = true
			campaign_manager.broadcast_combat_request(CombatRequest.new(
				CombatRequest.TYPE_ACTION,
				combatant_id,
				str(queue_payload.get("target_id", "")),
				queue_payload
			))

	if not queued_any:
		var log_manager := _find_campaign_manager()
		if log_manager != null:
			log_manager._add_combat_log("No NPC actions were queued.")

func _build_npc_queue_payload(combatant_id: String) -> Dictionary:
	if not encounter_combatants.has(combatant_id):
		return {}
	var payload: Dictionary = encounter_combatants[combatant_id]
	var npc: NPC = CampaignVariables.codex.NPCs.get(str(payload.get("name", "")), null)
	if npc == null:
		return {}

	var action_entry := _find_npc_attack_entry(npc, int(payload.get("active_loadout", 1)))
	if action_entry.is_empty():
		return {}
	var target_payload := _choose_npc_target_payload()
	if target_payload.is_empty():
		return {}

	var action: Action = action_entry.get("action", null)
	var weapon: Weapon = action_entry.get("weapon", null)
	var action_ap_cost := RuleEngine.getActionAPCost(action, weapon)
	if action_ap_cost <= 0 or action_ap_cost > int(payload.get("remaining_action_points", payload.get("action_points", 0))):
		return {}
	var action_source := "Innate"
	if weapon != null and not weapon._name.is_empty():
		action_source = weapon._name
	var target_name := str(target_payload.get("name", "target"))
	return {
		"action_name": action._name,
		"action_source": action_source,
		"action_hand": str(action_entry.get("hand", "Innate")),
		"target_id": str(target_payload.get("id", "")),
		"target_location": int(Item.ItemSlots.Torso),
		"ap_cost": action_ap_cost,
		"action_speed": RuleEngine.getActionSpeed(action, weapon),
		"preview_text": "%s -> %s (%s)" % [action._name, target_name, "Torso"],
	}

func _find_npc_attack_entry(npc: NPC, loadout: int) -> Dictionary:
	for entry in _get_npc_action_entries(npc, loadout):
		var action_name := str(entry.get("name", ""))
		if action_name in ["Wait", "Guard", "Bolster", "Swap Loadout"]:
			continue
		var resolved_entry := _get_action_resource_for_entry(npc.data, loadout, entry)
		if resolved_entry.is_empty():
			continue
		return resolved_entry
	for entry in _get_npc_action_entries(npc, loadout):
		return _get_action_resource_for_entry(npc.data, loadout, entry)
	return {}

func _choose_npc_target_payload() -> Dictionary:
	if not selected_combatant_id.is_empty() and encounter_combatants.has(selected_combatant_id):
		var selected_payload: Dictionary = encounter_combatants[selected_combatant_id]
		if str(selected_payload.get("type", "")) == "Player" and int(selected_payload.get("current_hp", 0)) > 0:
			return selected_payload

	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var payload: Dictionary = encounter_combatants[str(combatant_id_variant)]
		if str(payload.get("type", "")) == "Player" and int(payload.get("current_hp", 0)) > 0:
			return payload
	return {}

func _get_action_resource_for_entry(actor: CreatureData, loadout: int, action_entry: Dictionary) -> Dictionary:
	var action_name := str(action_entry.get("name", ""))
	var action_source := str(action_entry.get("source", "Innate"))
	var action_hand := str(action_entry.get("hand", "Innate"))
	return _find_action_entry_for_actor(actor, loadout, action_name, action_source, action_hand)

func _format_action_result(result: Dictionary) -> String:
	if result.get("hit", null) == null:
		if result.has("active_loadout"):
			return "%s swapped to loadout %s (%s AP)." % [result.get("source_name", "Someone"), result.get("active_loadout", 1), result.get("ap_cost", 1)]
		if result.has("defence_name"):
			return "%s bolstered %s by %s." % [result.get("source_name", "Someone"), result.get("defence_name", "a defence"), result.get("amount", 0)]
		return str(result)

	if bool(result.get("hit", false)):
		var status_suffix := ""
		if bool(result.get("is_dead", false)):
			status_suffix = " Target is dead."
		elif bool(result.get("is_unconscious", false)):
			status_suffix = " Target is unconscious."
		return "%s used %s on %s's %s: %s vs %s, %s damage after %s DT, %s temp absorbed, HP %s, VIT %s, %s AP, speed %s.%s" % [
			result.get("source_name", "Someone"),
			result.get("action_name", "an action"),
			result.get("target_name", "target"),
			result.get("target_location_name", "body"),
			result.get("to_hit_total", 0),
			result.get("defence_value", 0),
			result.get("total_damage", 0),
			result.get("location_dt", 0),
			result.get("absorbed_by_temporary_health", 0),
			result.get("remaining_hp", 0),
			result.get("remaining_vitality", 0),
			result.get("ap_cost", 0),
			result.get("action_speed", 0),
			status_suffix,
		]
	return "%s used %s on %s's %s but missed: %s vs %s, %s AP, speed %s." % [
		result.get("source_name", "Someone"),
		result.get("action_name", "an action"),
		result.get("target_name", "target"),
		result.get("target_location_name", "body"),
		result.get("to_hit_total", 0),
		result.get("defence_value", 0),
		result.get("ap_cost", 0),
		result.get("action_speed", 0),
	]

func _build_action_flavor_text(result: Dictionary) -> String:
	var source_name := str(result.get("source_name", "Someone"))
	var target_name := str(result.get("target_name", "target"))
	var action_name := str(result.get("action_name", "an action"))
	var location_name := str(result.get("target_location_name", "body"))
	var total_damage := int(result.get("total_damage", 0))
	var location_dt := int(result.get("location_dt", 0))
	if result.get("hit", null) == null:
		if result.has("active_loadout"):
			return "%s shifts stance and changes loadouts." % source_name
		if result.has("defence_name"):
			return "%s steels themselves and prepares for the next exchange." % source_name
		return "%s commits to %s." % [source_name, action_name]
	if not bool(result.get("hit", false)):
		return "%s's %s fails to find an opening on %s." % [source_name, action_name.to_lower(), target_name]
	if bool(result.get("did_crit", false)):
		return "%s lands a vicious %s against %s's %s, drawing a brutal reaction." % [source_name, action_name.to_lower(), target_name, location_name.to_lower()]
	if bool(result.get("is_dead", false)):
		return "%s's %s crushes the last of %s's vitality, leaving them lifeless." % [source_name, action_name.to_lower(), target_name]
	if bool(result.get("is_unconscious", false)):
		return "%s's %s drops %s unconscious." % [source_name, action_name.to_lower(), target_name]
	if total_damage <= 0 and location_dt > 0:
		return "%s's %s strikes %s's %s, but the armor turns the blow aside." % [source_name, action_name.to_lower(), target_name, location_name.to_lower()]
	return "%s's %s slips through and bites into %s's %s." % [source_name, action_name.to_lower(), target_name, location_name.to_lower()]

func _build_action_narration_entries(result: Dictionary) -> Dictionary:
	return {
		"text": _build_action_flavor_text(result),
		"tooltip": _format_action_result(result),
	}

func _build_action_preview(current_request: CombatRequest) -> Dictionary:
	var source_payload: Dictionary = encounter_combatants.get(current_request.combatant_id, {})
	var target_payload: Dictionary = encounter_combatants.get(current_request.target_id, {})
	var source_name := str(source_payload.get("name", current_request.combatant_id))
	var target_name := str(target_payload.get("name", current_request.target_id))
	var action_name := str(current_request.payload.get("action_name", "Pending Action"))
	var location_name := _location_name_from_slot(int(current_request.payload.get("target_location", Item.ItemSlots.Torso)))
	var category := str(current_request.payload.get("category", Action.CATEGORY_ATTACK))
	var preview_result := {
		"source_name": source_name,
		"target_name": target_name,
		"action_name": action_name,
		"target_location_name": location_name,
		"ap_cost": current_request.payload.get("ap_cost", 0),
		"action_speed": current_request.payload.get("action_speed", 0),
	}
	var flavor := "%s prepares to use %s on %s's %s." % [source_name, action_name.to_lower(), target_name, location_name.to_lower()]
	match action_name:
		"Strike", "Slash", "Thrust", "Smash", "Cleave", "Sweep", "Bash", "Crack", "Fire", "Rend":
			flavor = "%s sizes up %s and commits to a %s aimed at the %s." % [source_name, target_name, action_name.to_lower(), location_name.to_lower()]
		"Swap Loadout":
			flavor = "%s shifts stance and reaches for a different loadout." % source_name
		"Guard":
			flavor = "%s braces defensively, ready to weather the next blow." % source_name
		"Bolster":
			flavor = "%s focuses and prepares a measured supporting action." % source_name
		"Wait":
			flavor = "%s pauses, watching the field for the right moment." % source_name
		_:
			if category != Action.CATEGORY_ATTACK:
				flavor = "%s prepares %s." % [source_name, action_name.to_lower()]
	return {
		"flavor": flavor,
		"mechanics": "%s targets %s's %s with %s (%s AP, speed %s)." % [preview_result["source_name"], preview_result["target_name"], preview_result["target_location_name"], preview_result["action_name"], preview_result["ap_cost"], preview_result["action_speed"]],
	}

func _refresh_action_resolution_window() -> void:
	if pending_resolution_requests.is_empty():
		resolutionTitle.text = "No Pending Actions"
		resolutionProgress.text = "0 remaining"
		resolutionDetails.text = "All queued actions have been handled."
		return
	var current_request := pending_resolution_requests[0]
	var total_remaining := pending_resolution_requests.size()
	var source_payload: Dictionary = encounter_combatants.get(current_request.combatant_id, {})
	var target_payload: Dictionary = encounter_combatants.get(current_request.target_id, {})
	var preview := _build_action_preview(current_request)
	resolutionTitle.text = "%s -> %s" % [source_payload.get("name", current_request.combatant_id), target_payload.get("name", current_request.target_id)]
	resolutionProgress.text = "%s actions remaining" % total_remaining
	resolutionDetails.text = "[b]Flavor[/b]\n%s\n\n[b]Mechanics[/b]\n%s\n\n[b]Action[/b] %s\n[b]Actor[/b] %s\n[b]Target[/b] %s\n[b]Source[/b] %s (%s)\n[b]Location[/b] %s\n[b]AP[/b] %s\n[b]Speed[/b] %s" % [
		preview.get("flavor", ""),
		preview.get("mechanics", ""),
		current_request.payload.get("action_name", "Pending Action"),
		source_payload.get("name", current_request.combatant_id),
		target_payload.get("name", current_request.target_id),
		current_request.payload.get("action_source", "Innate"),
		current_request.payload.get("action_hand", "Innate"),
		_location_name_from_slot(int(current_request.payload.get("target_location", Item.ItemSlots.Torso))),
		current_request.payload.get("ap_cost", 0),
		current_request.payload.get("action_speed", 0),
	]

func _resolve_current_action_resolution() -> void:
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
		return
	var current_request = pending_resolution_requests.pop_front()
	var resolution := _resolve_queued_action(current_request)
	_broadcast_resolution_event("queued_action_resolved", current_request, resolution)
	_apply_review_queue_state()
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
	else:
		_refresh_action_resolution_window()

func _abort_current_action_resolution() -> void:
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
		return
	var current_request = pending_resolution_requests.pop_front()
	var source_payload: Dictionary = encounter_combatants.get(current_request.combatant_id, {})
	var target_payload: Dictionary = encounter_combatants.get(current_request.target_id, {})
	var preview := _build_action_preview(current_request)
	var results: Array[Dictionary] = [{
		"text": "%s aborted %s targeting %s." % [
			source_payload.get("name", current_request.combatant_id),
			current_request.payload.get("action_name", "an action"),
			target_payload.get("name", current_request.target_id),
		],
		"tooltip": str(preview.get("mechanics", "")),
	}]
	_broadcast_resolution_event("queued_action_aborted", current_request, {"state_changes": [], "results": results})
	_apply_review_queue_state()
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
	else:
		_refresh_action_resolution_window()

func _resolve_all_action_resolutions() -> void:
	while not pending_resolution_requests.is_empty():
		_resolve_current_action_resolution()

func _broadcast_resolution_event(event_name: String, combat_request: CombatRequest, resolution: Dictionary) -> void:
	var state_changes: Array[Dictionary] = []
	for state_change_variant in resolution.get("state_changes", []):
		if state_change_variant is Dictionary:
			state_changes.append(state_change_variant)
	var results: Array[Dictionary] = []
	for result_variant in resolution.get("results", []):
		if result_variant is Dictionary:
			results.append(result_variant)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	var game_event := GameEvent.new(
		event_name,
		GameEvent.CONTEXT_COMBAT,
		combat_request.payload,
		state_changes,
		results,
		round_number,
		current_phase,
		combat_request.combatant_id,
		combat_request.target_id
	)
	campaign_manager.broadcast_game_event(game_event)

func _apply_review_queue_state() -> void:
	var remaining_payloads_by_combatant: Dictionary = {}
	for request in pending_resolution_requests:
		var combatant_id := request.combatant_id
		if not remaining_payloads_by_combatant.has(combatant_id):
			remaining_payloads_by_combatant[combatant_id] = []
		var queued_payload := request.payload.duplicate(true)
		queued_payload["target_id"] = request.target_id
		queued_payload["queued_timestamp"] = request.timestamp
		remaining_payloads_by_combatant[combatant_id].append(queued_payload)
	var state_changes: Array[Dictionary] = []
	for combatant_id in encounter_combatants.keys():
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		var queued_payloads: Array = remaining_payloads_by_combatant.get(combatant_id, [])
		var queued_texts: Array[String] = []
		for queued_payload_variant in queued_payloads:
			if queued_payload_variant is Dictionary:
				queued_texts.append(str((queued_payload_variant as Dictionary).get("preview_text", "Action")))
		payload["queued_action_payloads"] = queued_payloads
		payload["queued_actions"] = queued_texts
		payload["pending_request"] = ""
		payload.erase("id")
		payload["combatant_id"] = str(combatant_id)
		state_changes.append(payload)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	var review_event := GameEvent.new(
		"action_review_progressed",
		GameEvent.CONTEXT_COMBAT,
		{},
		state_changes,
		[],
		round_number,
		current_phase
	)
	campaign_manager.broadcast_game_event(review_event)

func _finalize_action_phase_review() -> void:
	is_reviewing_action_phase = false
	pending_resolution_requests.clear()
	actionResolutionWindow.hide()
	var state_changes: Array[Dictionary] = []
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		if not encounter_combatants.has(combatant_id):
			continue
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		var reset_payload := _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
		if reset_payload.is_empty():
			continue
		reset_payload["remaining_action_points"] = int(reset_payload.get("action_points", 0))
		reset_payload["queued_actions"] = []
		reset_payload["queued_action_payloads"] = []
		reset_payload["pending_request"] = ""
		reset_payload.erase("id")
		reset_payload["combatant_id"] = combatant_id
		state_changes.append(reset_payload)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	var game_event := GameEvent.new(
		"action_phase_ended",
		GameEvent.CONTEXT_COMBAT,
		{},
		state_changes,
		[],
		round_number + 1,
		GameEvent.PHASE_PLANNING
	)
	campaign_manager.broadcast_game_event(game_event)

func _on_action_resolution_window_close_requested() -> void:
	if pending_resolution_requests.is_empty():
		actionResolutionWindow.hide()
		return
	actionResolutionWindow.popup_centered()

func _get_actor_data_from_payload(payload: Dictionary) -> CreatureData:
	if str(payload.get("type", "")) == "Player":
		var campaign_manager := _find_campaign_manager()
		if campaign_manager == null:
			return null
		var peer_id := int(payload.get("controller_peer_id", 0))
		return campaign_manager.membersCharacters.get(peer_id, null)

	var npc: NPC = CampaignVariables.codex.NPCs.get(str(payload.get("name", "")), null)
	if npc == null:
		return null
	return npc.data

func _find_action_entry_for_actor(actor: CreatureData, loadout: int, action_name: String, action_source: String, action_hand: String) -> Dictionary:
	var entries: Array[Dictionary] = []
	if actor is HumanoidData:
		entries = (actor as HumanoidData).get_available_actions(loadout)
	else:
		for actor_action in actor.actions:
			if actor_action is Action:
				entries.append({"action": actor_action, "weapon": null, "hand": "Innate"})

	var name_only_match: Dictionary = {}
	for entry in entries:
		var action: Action = entry.get("action", null)
		if action == null or action._name != action_name:
			continue
		if name_only_match.is_empty():
			name_only_match = entry
		var weapon: Weapon = entry.get("weapon", null)
		var source := "Innate"
		if weapon != null and not weapon._name.is_empty():
			source = weapon._name
		if source != action_source:
			continue
		if str(entry.get("hand", "Innate")) != action_hand:
			continue
		return entry
	return name_only_match

func _build_action_resolution_debug_message(source_payload: Dictionary, actor: CreatureData, loadout: int, action_name: String, action_source: String, action_hand: String) -> String:
	var actor_name := str(source_payload.get("name", "Someone"))
	var available_entries: Array[String] = []
	var equipment_summary := ""
	if actor is HumanoidData:
		var equipment := (actor as HumanoidData).equipment
		equipment_summary = " Equipped: W1R=%s, W1L=%s, W2R=%s, W2L=%s" % [
			_item_name_for_debug(equipment.weapon1Right if equipment != null else null),
			_item_name_for_debug(equipment.weapon1Left if equipment != null else null),
			_item_name_for_debug(equipment.weapon2Right if equipment != null else null),
			_item_name_for_debug(equipment.weapon2Left if equipment != null else null),
		]
	var entries: Array[Dictionary] = []
	if actor is HumanoidData:
		entries = (actor as HumanoidData).get_available_actions(loadout)
	else:
		for actor_action in actor.actions:
			if actor_action is Action:
				entries.append({"action": actor_action, "weapon": null, "hand": "Innate"})
	for entry in entries:
		var action: Action = entry.get("action", null)
		if action == null:
			continue
		var weapon: Weapon = entry.get("weapon", null)
		var source := "Innate"
		if weapon != null and not weapon._name.is_empty():
			source = weapon._name
		available_entries.append("%s [%s / %s]" % [action._name, source, str(entry.get("hand", "Innate"))])
	if available_entries.is_empty():
		available_entries.append("none")
	return "%s could not use %s [%s / %s] on loadout %s.%s Available: %s" % [actor_name, action_name, action_source, action_hand, loadout, equipment_summary, ", ".join(available_entries)]

func _item_name_for_debug(item: Item) -> String:
	if item == null or item._name.is_empty():
		return "none"
	return item._name

func _on_player_action_pressed(action_data: Dictionary) -> void:
	if is_reviewing_action_phase:
		playerActionsHint.text = "Wait for the GM to finish resolving queued actions."
		return
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		playerActionsHint.text = "You are not currently in this encounter."
		return
	var action_name := str(action_data.get("name", "Unknown Action"))

	var action_source := str(action_data.get("source", "Innate"))
	var action_hand := str(action_data.get("hand", "Innate"))
	var resolved_entry := _find_action_entry_for_actor(PlayerVariables.data, int(local_payload.get("active_loadout", 1)), action_name, action_source, action_hand)
	if resolved_entry.is_empty():
		playerActionsHint.text = "Could not resolve that action."
		return
	var action: Action = resolved_entry.get("action", null)
	var weapon: Weapon = resolved_entry.get("weapon", null)
	var action_ap_cost := RuleEngine.getActionAPCost(action, weapon)
	var action_speed := RuleEngine.getActionSpeed(action, weapon)
	var instant_resolve := action_name == "Swap Loadout"
	if current_phase != GameEvent.PHASE_EXECUTION:
		playerActionsHint.text = "Actions can only be queued during the Action phase."
		return
	if action_ap_cost > int(local_payload.get("remaining_action_points", local_payload.get("action_points", 0))):
		playerActionsHint.text = "Not enough AP for %s." % action_name
		return
	var selected_action_payload := {
		"action_name": action_name,
		"action_source": action_source,
		"action_hand": action_hand,
		"category": action_data.get("category", Action.CATEGORY_ATTACK),
		"target_location": int(Item.ItemSlots.Torso),
		"ap_cost": action_ap_cost,
		"action_speed": action_speed,
		"instant_resolve": instant_resolve,
	}
	if instant_resolve:
		_queue_player_action(selected_action_payload, local_payload)
	elif str(selected_action_payload.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK:
		pending_player_action = selected_action_payload
		selected_combatant_id = str(local_payload.get("id", ""))
		_queue_pending_player_action(local_payload)
	else:
		pending_player_action = selected_action_payload
		selected_combatant_id = ""
		selected_combatant_entry = null
		playerActionsHint.text = "Selected %s (%s AP). Choose a target." % [action_name, action_ap_cost]
		_refresh_combatant_entry_interactions()

func _queue_pending_player_action(target_payload: Dictionary) -> void:
	if pending_player_action.is_empty():
		return
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		pending_player_action = {}
		_refresh_combatant_entry_interactions()
		return
	_queue_player_action(pending_player_action, target_payload)
	pending_player_action = {}
	selected_combatant_id = str(target_payload.get("id", ""))
	_refresh_combatant_entry_interactions()

func _queue_player_action(action_payload: Dictionary, target_payload: Dictionary) -> void:
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		return
	var target_combatant_id := str(target_payload.get("id", local_payload.get("id", "")))
	var preview_text := "%s -> %s (%s)" % [action_payload.get("action_name", "Action"), target_payload.get("name", "target"), "Torso"]
	if bool(action_payload.get("instant_resolve", false)):
		preview_text = "%s -> Loadout %s" % [action_payload.get("action_name", "Action"), _get_next_loadout(int(local_payload.get("active_loadout", 1)))]
		playerActionsHint.text = "%s will resolve immediately (%s AP)." % [action_payload.get("action_name", "Action"), action_payload.get("ap_cost", 0)]
	else:
		playerActionsHint.text = "Queued %s against %s (%s AP)." % [action_payload.get("action_name", "Action"), target_payload.get("name", "target"), action_payload.get("ap_cost", 0)]
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	var payload := action_payload.duplicate(true)
	payload["preview_text"] = preview_text
	campaign_manager.broadcast_combat_request(CombatRequest.new(
		CombatRequest.TYPE_ACTION,
		str(local_payload.get("id", "")),
		target_combatant_id,
		payload
	))

func _apply_combat_request_preview(combat_request: CombatRequest) -> void:
	var combatant_id := combat_request.combatant_id
	if combatant_id.is_empty() or not encounter_combatants.has(combatant_id):
		return

	var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
	payload["pending_request"] = combat_request.payload.get("preview_text", "")
	if combat_request.request_type == CombatRequest.TYPE_ACTION:
		var queued_actions: Array = payload.get("queued_actions", []).duplicate(true)
		var queued_action_payloads: Array = payload.get("queued_action_payloads", []).duplicate(true)
		var remaining_action_points := int(payload.get("remaining_action_points", payload.get("action_points", 0)))
		var action_ap_cost := int(combat_request.payload.get("ap_cost", 1))
		if action_ap_cost <= remaining_action_points:
			queued_actions.append(str(combat_request.payload.get("preview_text", "Action")))
			var queued_payload := combat_request.payload.duplicate(true)
			queued_payload["target_id"] = combat_request.target_id
			queued_payload["queued_timestamp"] = combat_request.timestamp
			queued_action_payloads.append(queued_payload)
			payload["queued_actions"] = queued_actions
			payload["queued_action_payloads"] = queued_action_payloads
			payload["remaining_action_points"] = remaining_action_points - action_ap_cost
	encounter_combatants[combatant_id] = payload
	if combatant_entries.has(combatant_id):
		var existing_entry: CombatantEntry = combatant_entries[combatant_id]
		if is_instance_valid(existing_entry):
			existing_entry.setup(payload)

	if selected_combatant_id == combatant_id:
		_show_inspector(payload)

	_refresh_player_actions()
	_refresh_queued_actions()

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

	_sync_local_player_from_combatant_payload(payload)

	update_combatant_locally(payload)

func _sync_local_player_from_combatant_payload(payload: Dictionary) -> void:
	var controller_peer_id := int(payload.get("controller_peer_id", 0))
	if controller_peer_id == 0 or controller_peer_id != multiplayer.get_unique_id():
		return
	if PlayerVariables.data == null:
		return
	if payload.has("current_hp"):
		PlayerVariables.data.currentHP = int(payload.get("current_hp", PlayerVariables.data.currentHP))
	if payload.has("max_hp"):
		PlayerVariables.data.maxHP = int(payload.get("max_hp", PlayerVariables.data.maxHP))
	if payload.has("current_vitality"):
		PlayerVariables.data.currentVitality = int(payload.get("current_vitality", PlayerVariables.data.currentVitality))
	if payload.has("max_vitality"):
		PlayerVariables.data.maxVitality = int(payload.get("max_vitality", PlayerVariables.data.maxVitality))
	if payload.has("temporary_health"):
		PlayerVariables.data.temporaryHealth = int(payload.get("temporary_health", PlayerVariables.data.temporaryHealth))
	if payload.has("level"):
		PlayerVariables.data.level = int(payload.get("level", PlayerVariables.data.level))
	PlayerVariables.vitals_changed.emit()

func reset_combat_session_locally() -> void:
	encounter_combatants.clear()
	combatant_entries.clear()
	next_combatant_id = 1
	round_number = 1
	current_phase = GameEvent.PHASE_PLANNING
	is_reviewing_action_phase = false
	pending_resolution_requests.clear()
	actionResolutionWindow.hide()
	_clear_combatants()
	_clear_inspector()
	_clear_player_actions()
	_update_round_ui()
	selected_combatant_entry = null
	selected_combatant_id = ""
	if npc_picker != null:
		npc_picker.hide()
	_refresh_queued_actions()

func _build_combatant_entry(combatant_payload: Dictionary) -> CombatantEntry:
	var entry := COMBATANT_ENTRY_SCENE.instantiate() as CombatantEntry
	entry.setup(combatant_payload)
	entry.selected.connect(_on_combatant_selected)
	entry.target_selected.connect(_on_combatant_target_selected)
	entry.name = _build_combatant_node_name(combatant_payload)
	_configure_combatant_entry_interaction(entry, combatant_payload)
	return entry

func _build_player_payload(player_data: PlayerData, peer_id: int) -> Dictionary:
	RuleEngine.normalizeVitals(player_data, true)
	var details := [
		"Peer ID: %s" % peer_id,
		"Attributes: %s" % _format_attribute_values(player_data.attributes),
		"Actions: %s" % _format_player_action_names(player_data),
		"Conditions: %s" % _format_name_list(player_data.conditions),
	]
	var action_points := RuleEngine.getActionPoints(player_data)
	return {
		"id": _create_combatant_id("player_%s" % peer_id),
		"name": player_data._name,
		"type": "Player",
		"controller_peer_id": peer_id,
		"active_loadout": 1,
		"action_points": action_points,
		"remaining_action_points": action_points,
		"queued_actions": [],
		"queued_action_payloads": [],
		"movement_choice": {},
		"current_hp": player_data.currentHP,
		"max_hp": player_data.maxHP,
		"current_vitality": player_data.currentVitality,
		"max_vitality": player_data.maxVitality,
		"temporary_health": player_data.temporaryHealth,
		"level": player_data.level,
		"details": "\n".join(details),
		"equipment": _serialize_equipment(player_data.equipment),
		"actions": _get_player_action_entries(player_data, 1),
		"action_names": _get_player_action_names(player_data, 1),
		"peer_id": peer_id,
	}

func _build_npc_payload(npc: NPC) -> Dictionary:
	RuleEngine.normalizeVitals(npc.data, true)
	var details := [
		npc.short_description,
		"Attributes: %s" % _format_attribute_values(npc.data.attributes),
		"Actions: %s" % _format_name_list(npc.data.actions),
		"Conditions: %s" % _format_name_list(npc.data.conditions),
	]
	var action_points := RuleEngine.getActionPoints(npc.data)
	return {
		"id": _create_combatant_id("npc_%s" % npc._name.to_snake_case()),
		"name": npc._name,
		"type": "NPC",
		"controller_peer_id": 0,
		"active_loadout": 1,
		"action_points": action_points,
		"remaining_action_points": action_points,
		"queued_actions": [],
		"queued_action_payloads": [],
		"movement_choice": {},
		"current_hp": npc.data.currentHP,
		"max_hp": npc.data.maxHP,
		"current_vitality": npc.data.currentVitality,
		"max_vitality": npc.data.maxVitality,
		"temporary_health": npc.data.temporaryHealth,
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
	_refresh_combatant_entry_interactions()

func _on_combatant_target_selected(entry: CombatantEntry, combatant_payload: Dictionary) -> void:
	if pending_player_action.is_empty():
		entry.set_selected(false)
		return
	selected_combatant_entry = entry
	selected_combatant_id = str(combatant_payload.get("id", ""))
	_queue_pending_player_action(combatant_payload)

func _configure_combatant_entry_interaction(entry: CombatantEntry, combatant_payload: Dictionary) -> void:
	if entry == null or not is_instance_valid(entry):
		return
	if is_host_role:
		entry.set_player_target_mode(false, false, selected_combatant_id == str(combatant_payload.get("id", "")))
		return
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	var can_target := false
	var is_targeted := false
	if not pending_player_action.is_empty():
		var combatant_id := str(combatant_payload.get("id", ""))
		var local_id := str(local_payload.get("id", ""))
		var can_target_self := str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK
		if combatant_id != local_id or can_target_self:
			can_target = true
			is_targeted = combatant_id == selected_combatant_id
	entry.set_player_target_mode(true, can_target, is_targeted)

func _refresh_combatant_entry_interactions() -> void:
	for combatant_id in combatant_entries.keys():
		var entry: CombatantEntry = combatant_entries[combatant_id]
		if not is_instance_valid(entry):
			continue
		var payload: Dictionary = encounter_combatants.get(str(combatant_id), {})
		if payload.is_empty():
			continue
		_configure_combatant_entry_interaction(entry, payload)

func _show_inspector(combatant_payload: Dictionary) -> void:
	inspectorTitle.text = str(combatant_payload.get("name", "Combatant Inspector"))
	inspectorType.text = "Type: %s" % combatant_payload.get("type", "NA")
	inspectorHP.text = "HP: %s/%s | VIT: %s/%s | TEMP: %s" % [combatant_payload.get("current_hp", 0), combatant_payload.get("max_hp", 0), combatant_payload.get("current_vitality", 0), combatant_payload.get("max_vitality", 0), combatant_payload.get("temporary_health", 0)]
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
	pending_player_action = {}
	playerCombatantName.text = "No combatant selected."
	playerLoadout.text = "Loadout: 1"
	playerSwapLoadout.disabled = true
	playerActionsHint.text = "You are not currently in this encounter."
	_populate_action_list(playerActionsList, [], true)
	_refresh_combatant_entry_interactions()

func _refresh_player_actions() -> void:
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
	if not pending_player_action.is_empty():
		playerActionsHint.text = "Selected %s (%s AP). Choose a target." % [pending_player_action.get("action_name", "Action"), pending_player_action.get("ap_cost", 0)]
	elif current_phase == GameEvent.PHASE_EXECUTION:
		playerActionsHint.text = "Queue actions now."
	else:
		playerActionsHint.text = "Queue actions during the Action phase."
	_populate_action_list(playerActionsList, runtime_payload.get("actions", []), true)
	_refresh_combatant_entry_interactions()

func _on_local_combat_loadout_changed() -> void:
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
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		return
	var next_loadout := _get_next_loadout(int(local_payload.get("active_loadout", 1)))
	local_payload["active_loadout"] = next_loadout
	local_payload["pending_request"] = ""
	encounter_combatants[str(local_payload.get("id", ""))] = local_payload
	if combatant_entries.has(str(local_payload.get("id", ""))):
		var existing_entry: CombatantEntry = combatant_entries[str(local_payload.get("id", ""))]
		if is_instance_valid(existing_entry):
			existing_entry.setup(local_payload)
	if selected_combatant_id == str(local_payload.get("id", "")):
		_show_inspector(local_payload)
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
	RuleEngine.normalizeVitals(player_data)
	var active_loadout := int(payload.get("active_loadout", 1))
	var action_points := RuleEngine.getActionPoints(player_data)
	payload["current_hp"] = player_data.currentHP
	payload["max_hp"] = player_data.maxHP
	payload["current_vitality"] = player_data.currentVitality
	payload["max_vitality"] = player_data.maxVitality
	payload["temporary_health"] = player_data.temporaryHealth
	payload["level"] = player_data.level
	payload["active_loadout"] = active_loadout
	payload["action_points"] = action_points
	payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", action_points)), action_points)
	payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
	payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
	payload["details"] = "\n".join([
		"Peer ID: %s" % multiplayer.get_unique_id(),
		"Attributes: %s" % _format_attribute_values(player_data.attributes),
		"Actions: %s" % _format_player_action_names(player_data, active_loadout),
		"Conditions: %s" % _format_name_list(player_data.conditions),
	])
	payload["equipment"] = _serialize_equipment(player_data.equipment)
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
		RuleEngine.normalizeVitals(player_data)
		var player_action_points := RuleEngine.getActionPoints(player_data)
		payload["current_hp"] = player_data.currentHP
		payload["max_hp"] = player_data.maxHP
		payload["current_vitality"] = player_data.currentVitality
		payload["max_vitality"] = player_data.maxVitality
		payload["temporary_health"] = player_data.temporaryHealth
		payload["level"] = player_data.level
		payload["action_points"] = player_action_points
		payload["details"] = "\n".join([
			"Peer ID: %s" % peer_id,
			"Attributes: %s" % _format_attribute_values(player_data.attributes),
			"Actions: %s" % _format_player_action_names(player_data, active_loadout),
			"Conditions: %s" % _format_name_list(player_data.conditions),
		])
		payload["equipment"] = _serialize_equipment(player_data.equipment)
		payload["actions"] = _get_player_action_entries(player_data, active_loadout)
		payload["action_names"] = _get_player_action_names(player_data, active_loadout)
		payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", player_action_points)), player_action_points)
		payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
		payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
		return payload
	var npc: NPC = CampaignVariables.codex.NPCs.get(str(payload.get("name", "")), null)
	if npc == null:
		return {}
	RuleEngine.normalizeVitals(npc.data)
	var npc_action_points := RuleEngine.getActionPoints(npc.data)
	payload["current_hp"] = npc.data.currentHP
	payload["max_hp"] = npc.data.maxHP
	payload["current_vitality"] = npc.data.currentVitality
	payload["max_vitality"] = npc.data.maxVitality
	payload["temporary_health"] = npc.data.temporaryHealth
	payload["level"] = npc.data.level
	payload["action_points"] = npc_action_points
	payload["details"] = "\n".join([
		npc.short_description,
		"Attributes: %s" % _format_attribute_values(npc.data.attributes),
		"Actions: %s" % _format_name_list(npc.data.actions),
		"Conditions: %s" % _format_name_list(npc.data.conditions),
	])
	payload["actions"] = _get_npc_action_entries(npc, active_loadout)
	payload["action_names"] = _get_npc_action_names(npc, active_loadout)
	payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", npc_action_points)), npc_action_points)
	payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
	payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
	return payload

func _serialize_equipment(equipment: Equipment) -> Dictionary:
	if equipment == null:
		return {}
	return {
		"head": _item_name_or_empty(equipment.head),
		"torso": _item_name_or_empty(equipment.torso),
		"leftArm": _item_name_or_empty(equipment.leftArm),
		"rightArm": _item_name_or_empty(equipment.rightArm),
		"leftLeg": _item_name_or_empty(equipment.leftLeg),
		"rightLeg": _item_name_or_empty(equipment.rightLeg),
		"weapon1Left": _item_name_or_empty(equipment.weapon1Left),
		"weapon1Right": _item_name_or_empty(equipment.weapon1Right),
		"weapon2Left": _item_name_or_empty(equipment.weapon2Left),
		"weapon2Right": _item_name_or_empty(equipment.weapon2Right),
		"quickItem1": _item_name_or_empty(equipment.quickItem1),
		"quickItem2": _item_name_or_empty(equipment.quickItem2),
		"quickItem3": _item_name_or_empty(equipment.quickItem3),
		"quickItem4": _item_name_or_empty(equipment.quickItem4),
	}

func _item_name_or_empty(item: Item) -> String:
	if item == null:
		return ""
	return item._name

func _refresh_queued_actions() -> void:
	for child in queuedActionsList.get_children():
		child.queue_free()

	var title := Label.new()
	title.text = "Queued Actions"
	queuedActionsList.add_child(title)

	var has_entries := false
	for queued_entry in _get_sorted_queued_action_entries():
		has_entries = true
		var action_entry := ACTION_ENTRY_SCENE.instantiate() as ActionEntry
		action_entry.setup(queued_entry)
		queuedActionsList.add_child(action_entry)

	if not has_entries:
		var empty_label := Label.new()
		empty_label.text = "No queued actions."
		queuedActionsList.add_child(empty_label)

func _location_name_from_slot(target_location: int) -> String:
	match target_location:
		Item.ItemSlots.Head:
			return "Head"
		Item.ItemSlots.RightArm:
			return "Right Arm"
		Item.ItemSlots.LeftArm:
			return "Left Arm"
		Item.ItemSlots.Torso:
			return "Torso"
		Item.ItemSlots.RightLeg:
			return "Right Leg"
		Item.ItemSlots.LeftLeg:
			return "Left Leg"
		_:
			return "Unknown"

func _get_sorted_queued_requests() -> Array[CombatRequest]:
	var sorted_requests: Array[CombatRequest] = []
	for queued_entry in _get_sorted_queued_action_entries():
		var queued_payload := queued_entry.get("queued_payload", {}) as Dictionary
		sorted_requests.append(CombatRequest.new(
			CombatRequest.TYPE_ACTION,
			str(queued_entry.get("combatant_id", "")),
			str(queued_payload.get("target_id", "")),
			queued_payload,
			float(queued_payload.get("queued_timestamp", 0.0))
		))
	return sorted_requests

func _get_sorted_queued_action_entries() -> Array[Dictionary]:
	var queued_entries: Array[Dictionary] = []
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants.get(combatant_id, {})
		var queued_action_payloads: Array = payload.get("queued_action_payloads", [])
		var cumulative_speed := 0
		for queued_action_payload_variant in queued_action_payloads:
			if not (queued_action_payload_variant is Dictionary):
				continue
			var queued_payload := queued_action_payload_variant as Dictionary
			var action_speed := int(queued_payload.get("action_speed", 0))
			cumulative_speed += action_speed
			var target_name := "Target"
			var target_id := str(queued_payload.get("target_id", ""))
			if encounter_combatants.has(target_id):
				target_name = str(encounter_combatants[target_id].get("name", "Target"))
			queued_entries.append({
				"combatant_id": combatant_id,
				"actor_name": str(payload.get("name", "Combatant")),
				"action_name": str(queued_payload.get("action_name", "Action")),
				"target_name": target_name,
				"target_location_name": _location_name_from_slot(int(queued_payload.get("target_location", Item.ItemSlots.Torso))),
				"speed": action_speed,
				"resolve_speed": cumulative_speed,
				"timestamp": float(queued_payload.get("queued_timestamp", 0.0)),
				"queued_payload": queued_payload,
			})
	queued_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var speed_a := int(a.get("resolve_speed", a.get("speed", 0)))
		var speed_b := int(b.get("resolve_speed", b.get("speed", 0)))
		if speed_a != speed_b:
			return speed_a < speed_b
		var timestamp_a := float(a.get("timestamp", 0.0))
		var timestamp_b := float(b.get("timestamp", 0.0))
		if not is_equal_approx(timestamp_a, timestamp_b):
			return timestamp_a < timestamp_b
		return str(a.get("combatant_id", "")) < str(b.get("combatant_id", ""))
	)
	return queued_entries

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
		var action_tooltip := "Source: %s (%s)\nCategory: %s\nAP: %s\nSpeed: %s" % [action_source, action_hand, action_data.get("category", "Unknown"), action_data.get("ap_cost", 0), action_data.get("speed", 0)]
		var node: Control
		if use_buttons:
			var button := Button.new()
			button.text = action_name
			button.tooltip_text = action_tooltip
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.pressed.connect(_on_player_action_pressed.bind(action_data))
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
		var ap_cost := RuleEngine.getActionAPCost(action, weapon)
		var speed := RuleEngine.getActionSpeed(action, weapon)
		action_entries.append({
			"name": action._name,
			"source": source,
			"hand": hand,
			"category": action.category,
			"ap_cost": ap_cost,
			"speed": speed,
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
			var ap_cost := RuleEngine.getActionAPCost(action, weapon)
			var speed := RuleEngine.getActionSpeed(action, weapon)
			action_entries.append({
				"name": action._name,
				"source": source,
				"hand": hand,
				"category": action.category,
				"ap_cost": ap_cost,
				"speed": speed,
			})
		return action_entries

	for action in npc.data.actions:
		if action is Action:
			action_entries.append({
				"name": action._name,
				"source": "Innate",
				"hand": "Innate",
				"category": action.category,
				"ap_cost": RuleEngine.getActionAPCost(action, null),
				"speed": RuleEngine.getActionSpeed(action, null),
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
