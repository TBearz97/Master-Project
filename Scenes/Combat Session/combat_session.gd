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
@onready var playerSummaryPanel: Panel = %PlayerSummaryPanel
@onready var playerSummaryTitle: Label = %PlayerSummaryTitle
@onready var playerSummaryHP: Label = %PlayerSummaryHP
@onready var playerSummaryAP: Label = %PlayerSummaryAP
@onready var playerSummaryConcentration: Label = %PlayerSummaryConcentration
@onready var playerSummaryDefences: Label = %PlayerSummaryDefences
@onready var playerSummaryMana: Label = %PlayerSummaryMana
@onready var playerSummaryConditions: RichTextLabel = %PlayerSummaryConditions
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
@onready var hitLocationLabel: Label = %HitLocationLabel
@onready var hitLocationSelector: OptionButton = %HitLocationSelector
@onready var hitLocationHint: Label = %HitLocationHint
@onready var playerBasicActionsSection: VBoxContainer = %PlayerBasicActionsSection
@onready var playerBasicActionsList: VBoxContainer = %PlayerBasicActionsList
@onready var playerAttacksSection: VBoxContainer = %PlayerAttacksSection
@onready var playerAttacksList: VBoxContainer = %PlayerAttacksList
@onready var playerActionsHint: Label = %PlayerActionsHint
@onready var actionResolutionWindow: Window = %ActionResolutionWindow
@onready var resolutionTitle: Label = %ResolutionTitle
@onready var resolutionProgress: Label = %ResolutionProgress
@onready var resolutionEditPanel: PanelContainer = %ResolutionEditPanel
@onready var resolutionEditForm: GridContainer = %ResolutionEditForm
@onready var resolutionEditFormPanel: PanelContainer = %ResolutionEditFormPanel
@onready var resolutionOutcomeSelector: OptionButton = %ResolutionOutcomeSelector
@onready var resolutionLocationSelector: OptionButton = %ResolutionLocationSelector
@onready var resolutionSkillDifficultyLabel: Label = %ResolutionSkillDifficultyLabel
@onready var resolutionSkillDifficultyInput: SpinBox = %ResolutionSkillDifficultyInput
@onready var resolutionApplyEditsButton: Button = %ResolutionApplyEdits
@onready var resolutionEditDetails: RichTextLabel = %ResolutionEditDetails
@onready var resolutionDetails: RichTextLabel = %ResolutionDetails
@onready var abortActionButton: Button = %AbortAction
@onready var editActionButton: Button = %EditAction
@onready var resolveActionButton: Button = %ResolveAction
@onready var resolveAllActionsButton: Button = %ResolveAllActions
@onready var combatGrid: CombatGrid = %CombatGrid
@onready var gridWidthLabel: Label = %GridWidthLabel
@onready var gridWidthInput: SpinBox = %GridWidth
@onready var gridHeightLabel: Label = %GridHeightLabel
@onready var gridHeightInput: SpinBox = %GridHeight
@onready var resetPlacementsButton: Button = %ResetPlacements
@onready var boardHintLabel: Label = %BoardHint
@onready var statusWindow: AcceptDialog = %StatusWindow
@onready var statusWindowName: Label = %StatusWindowName
@onready var statusWindowState: Label = %StatusWindowState
@onready var statusWindowVitals: Label = %StatusWindowVitals
@onready var statusWindowAP: Label = %StatusWindowAP
@onready var statusWindowConcentration: Label = %StatusWindowConcentration
@onready var statusWindowConditions: RichTextLabel = %StatusWindowConditions
@onready var quickItemPicker: ConfirmationDialog = %QuickItemPicker
@onready var quickItemPickerLabel: Label = %QuickItemPickerLabel
@onready var quickItemSlotSelector: OptionButton = %QuickItemSlotSelector
@onready var skillTestPicker: ConfirmationDialog = %SkillTestPicker
@onready var skillTestPickerLabel: Label = %SkillTestPickerLabel
@onready var skillTestSkillSelector: OptionButton = %SkillTestSkillSelector
@onready var skillTestAPInput: SpinBox = %SkillTestAPInput
@onready var skillTestSpeedInput: SpinBox = %SkillTestSpeedInput
@onready var skillTestDescriptionInput: LineEdit = %SkillTestDescriptionInput
@onready var skillTestNoTargetToggle: CheckBox = %SkillTestNoTargetToggle

var npc_picker: ConfirmationDialog
var npc_picker_list: VBoxContainer
var selected_combatant_entry: CombatantEntry = null
var selected_combatant_id: String = ""
var pending_player_action: Dictionary = {}
var pending_quick_item_action: Dictionary = {}
var pending_skill_test_action: Dictionary = {}
var pending_resolution_requests: Array[CombatRequest] = []
var controlled_host_combatant_id: String = ""
var current_review_request: CombatRequest = null
var current_review_resolution: Dictionary = {}
var is_editing_review_action: bool = false
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
var board_columns: int = 12
var board_rows: int = 12
var pending_gm_placement_id: String = ""

const DISENGAGE_STEP_AP_COST := 3
const TARGET_LOCATION_MODE_RANDOM := "random"
const TARGET_LOCATION_MODE_CALLED := "called"
const CALLED_SHOT_ACCURACY_PENALTY := -4
const REVIEW_BOOLEAN_FIELDS := ["hit", "did_crit", "is_unconscious", "is_dead", "cancelled_actions", "already_stunned"]
const REVIEW_NUMERIC_FIELDS := ["to_hit_total", "defence_value", "damage_roll", "crit_roll", "location_dt", "absorbed_by_temporary_health", "health_damage", "vitality_damage", "total_damage", "remaining_hp", "remaining_vitality", "remaining_concentration", "ap_cost", "action_speed"]
const REVIEW_DAMAGE_FIELDS := ["damage_roll", "crit_roll", "location_dt", "absorbed_by_temporary_health", "health_damage", "vitality_damage", "total_damage"]
const REVIEW_ZERO_ON_MISS_FIELDS := ["raw_damage", "damage_roll", "crit_roll", "location_dt", "absorbed_by_temporary_health", "health_damage", "vitality_damage", "total_damage"]

var review_edit_controls: Dictionary = {}

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
	hitLocationSelector.item_selected.connect(_on_hit_location_selected)
	_populate_hit_location_selector()
	_build_resolution_edit_form()
	actionResolutionWindow.close_requested.connect(_on_action_resolution_window_close_requested)
	abortActionButton.pressed.connect(_abort_current_action_resolution)
	editActionButton.pressed.connect(_toggle_current_review_edit_mode)
	resolveActionButton.pressed.connect(_resolve_current_action_resolution)
	resolveAllActionsButton.pressed.connect(_resolve_all_action_resolutions)
	resolutionApplyEditsButton.pressed.connect(_apply_current_review_edits)
	quickItemPicker.confirmed.connect(_confirm_quick_item_selection)
	quickItemPicker.canceled.connect(_cancel_quick_item_selection)
	quickItemPicker.get_ok_button().text = "Use Item"
	skillTestPicker.confirmed.connect(_confirm_skill_test_selection)
	skillTestPicker.canceled.connect(_cancel_skill_test_selection)
	skillTestPicker.get_ok_button().text = "Queue Skill Test"
	gridWidthInput.value_changed.connect(_on_grid_width_changed)
	gridHeightInput.value_changed.connect(_on_grid_height_changed)
	resetPlacementsButton.pressed.connect(_reset_combatant_grid_positions)
	combatGrid.cell_clicked.connect(_on_grid_cell_clicked)
	combatGrid.token_clicked.connect(_on_grid_token_clicked)
	combatGrid.token_dragged.connect(_on_grid_token_dragged)
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
	_refresh_board_controls()
	_refresh_combat_grid()

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
	playerSummaryPanel.visible = not is_host_role
	playerActionsContent.visible = true
	inspectorSwapLoadout.visible = false
	gridWidthInput.editable = is_host_role and not encounter_started
	gridHeightInput.editable = is_host_role and not encounter_started
	resetPlacementsButton.visible = is_host_role
	if not is_host_role:
		_refresh_player_summary()

func _apply_encounter_visibility() -> void:
	var is_tab_page := get_parent() is TabContainer
	visible = true if is_tab_page else is_host_role or encounter_started
	%StartEncounter.visible = is_host_role and not encounter_started
	%EndEncounter.visible = is_host_role and encounter_started
	%AddPlayers.visible = is_host_role
	%AddNPCs.visible = is_host_role
	_refresh_board_controls()
	_update_phase_buttons()

func _get_controlled_combatant_payload() -> Dictionary:
	if is_host_role:
		if not controlled_host_combatant_id.is_empty() and encounter_combatants.has(controlled_host_combatant_id):
			var selected_payload: Dictionary = encounter_combatants[controlled_host_combatant_id]
			if str(selected_payload.get("type", "")) == "NPC":
				return selected_payload
		return {}
	return _find_local_player_combatant(multiplayer.get_unique_id())

func _get_controlled_actor_from_payload(payload: Dictionary) -> CreatureData:
	if payload.is_empty():
		return null
	if str(payload.get("type", "")) == "Player":
		var controller_peer_id := int(payload.get("controller_peer_id", 0))
		if controller_peer_id == multiplayer.get_unique_id() and PlayerVariables.data != null:
			return PlayerVariables.data
	return _get_actor_data_from_payload(payload)

func _refresh_board_controls() -> void:
	gridWidthLabel.visible = is_host_role
	gridWidthInput.visible = is_host_role
	gridHeightLabel.visible = is_host_role
	gridHeightInput.visible = is_host_role
	resetPlacementsButton.visible = is_host_role
	boardHintLabel.text = _build_board_hint_text()
	gridWidthInput.editable = is_host_role and not encounter_started
	gridHeightInput.editable = is_host_role and not encounter_started
	resetPlacementsButton.disabled = not is_host_role or encounter_started or encounter_combatants.is_empty()
	combatGrid.set_placement_source(pending_gm_placement_id)

func _build_board_hint_text() -> String:
	if is_host_role and not encounter_started:
		return "Drag tokens to place them before combat starts. Middle mouse pans. Wheel zooms."
	if current_phase == GameEvent.PHASE_PLANNING:
		return "Click a destination cell to preview movement. Middle mouse pans. Wheel zooms."
	return "Middle mouse pans. Wheel zooms."

func _on_encounter_state_changed(started: bool) -> void:
	encounter_started = started
	_apply_encounter_visibility()

func _on_authority_role_changed(is_host: bool) -> void:
	is_host_role = is_host
	_configure_role_view()
	_apply_encounter_visibility()
	_refresh_player_actions()
	_refresh_combat_grid()

func _on_grid_width_changed(value: float) -> void:
	_apply_board_dimensions(int(value), board_rows)

func _on_grid_height_changed(value: float) -> void:
	_apply_board_dimensions(board_columns, int(value))

func _apply_board_dimensions(columns: int, rows: int, broadcast_change: bool = true) -> void:
	columns = clampi(columns, 4, 128)
	rows = clampi(rows, 4, 128)
	if columns == board_columns and rows == board_rows:
		_refresh_combat_grid()
		return
	board_columns = columns
	board_rows = rows
	gridWidthInput.set_value_no_signal(board_columns)
	gridHeightInput.set_value_no_signal(board_rows)
	_clear_invalid_grid_positions()
	if broadcast_change and is_host_role:
		_broadcast_all_combatant_positions()
	_refresh_board_controls()
	_refresh_combat_grid()
	if broadcast_change and is_host_role:
		_broadcast_board_config_update()

func _broadcast_board_config_update() -> void:
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	var game_event := GameEvent.new(
		"combat_board_updated",
		GameEvent.CONTEXT_COMBAT,
		{
			"board_columns": board_columns,
			"board_rows": board_rows,
		}
	)
	campaign_manager.broadcast_game_event(game_event)

func _broadcast_all_combatant_positions() -> void:
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	for combatant_id_variant in encounter_combatants.keys():
		var payload: Dictionary = encounter_combatants[str(combatant_id_variant)]
		campaign_manager.broadcast_combatant_update(payload)

func _start_encounter() -> void:
	if not is_host_role:
		return
	if not _all_combatants_have_grid_positions():
		push_error("All combatants must be placed on the grid before starting the encounter.")
		return
	round_number = 1
	current_phase = GameEvent.PHASE_PLANNING
	pending_gm_placement_id = ""
	_assign_obsidian_patches_locations()
	_update_round_ui()
	_refresh_queued_actions()
	_refresh_board_controls()
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		push_error("Combat session could not find CampaignManager in the scene tree.")
		return
	SignalBus.emit_gameplay_event("encounter_started", "combat", {
		"round": round_number,
		"phase": current_phase,
		"metadata": {
			"board_columns": board_columns,
			"board_rows": board_rows,
			"combatant_count": encounter_combatants.size(),
		},
	})
	SignalBus.emit_gameplay_event("round_started", "combat", {
		"round": round_number,
		"phase": current_phase,
	})
	SignalBus.emit_gameplay_event("phase_started", "combat", {
		"round": round_number,
		"phase": current_phase,
	})
	campaign_manager.broadcast_encounter_started(true)

func _end_encounter() -> void:
	if not is_host_role:
		return
	_clear_obsidian_patches_locations()
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		push_error("Combat session could not find CampaignManager in the scene tree.")
		return
	SignalBus.emit_gameplay_event("encounter_ended", "combat", {
		"round": round_number,
		"phase": current_phase,
		"metadata": {
			"combatant_count": encounter_combatants.size(),
		},
	})
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants.get(combatant_id, {}).duplicate(true)
		if payload.is_empty():
			continue
		var actor := _get_actor_data_from_payload(payload)
		if actor == null:
			continue
		actor.normalizeVitals()
		actor.currentHP = clampf(minf(actor.maxHP, actor.currentVitality), 0.0, actor.maxHP)
		var updated_payload := _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
		if updated_payload.is_empty():
			continue
		encounter_combatants[combatant_id] = updated_payload
		campaign_manager.broadcast_combatant_update(updated_payload)
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
	var payload := combatant_payload.duplicate(true)
	if not payload.has("grid_position") or not _is_valid_grid_position(_grid_position_from_payload(payload)):
		payload["grid_position"] = _find_first_open_grid_position([combatant_id])
	encounter_combatants[combatant_id] = payload

	# Reuse the existing row when a payload update comes in so selection state and
	# inspector updates survive combatant refreshes.
	if combatant_entries.has(combatant_id):
		var existing_entry: CombatantEntry = combatant_entries[combatant_id]
		if is_instance_valid(existing_entry):
			existing_entry.setup(payload)
			_configure_combatant_entry_interaction(existing_entry, payload)
		else:
			combatant_entries.erase(combatant_id)

	if not combatant_entries.has(combatant_id):
		var entry := _build_combatant_entry(payload)
		combatant_entries[combatant_id] = entry
		combatantList.add_child(entry)

	if selected_combatant_id == combatant_id:
		_show_inspector(payload)

	_refresh_player_actions()
	_refresh_queued_actions()
	_refresh_board_controls()
	_refresh_combat_grid()

func update_combatant_locally(combatant_payload: Dictionary) -> void:
	spawn_combatant_locally(combatant_payload)

func apply_game_event(game_event: GameEvent) -> void:
	if game_event == null:
		return
	var previous_round := round_number
	var previous_phase := current_phase
	var resolved_movement_paths: Dictionary = {}
	if game_event.payload.has("board_columns") or game_event.payload.has("board_rows"):
		board_columns = clampi(int(game_event.payload.get("board_columns", board_columns)), 4, 128)
		board_rows = clampi(int(game_event.payload.get("board_rows", board_rows)), 4, 128)
		gridWidthInput.set_value_no_signal(board_columns)
		gridHeightInput.set_value_no_signal(board_rows)

	if game_event.round_number > 0:
		round_number = game_event.round_number
	if not game_event.phase.is_empty():
		current_phase = game_event.phase
		if current_phase != GameEvent.PHASE_EXECUTION:
			pending_player_action = {}
	if previous_phase != current_phase:
		if not previous_phase.is_empty():
			SignalBus.emit_gameplay_event("phase_ended", "combat", {
				"round": previous_round,
				"phase": previous_phase,
				"metadata": {
					"next_phase": current_phase,
					"event_type": game_event.event_type,
				},
			})
		SignalBus.emit_gameplay_event("phase_started", "combat", {
			"round": round_number,
			"phase": current_phase,
			"metadata": {
				"previous_phase": previous_phase,
				"event_type": game_event.event_type,
			},
		})
	if previous_round != round_number:
		SignalBus.emit_gameplay_event("round_ended", "combat", {
			"round": previous_round,
			"phase": previous_phase,
			"metadata": {
				"next_round": round_number,
				"event_type": game_event.event_type,
			},
		})
		SignalBus.emit_gameplay_event("round_started", "combat", {
			"round": round_number,
			"phase": current_phase,
			"metadata": {
				"previous_round": previous_round,
				"event_type": game_event.event_type,
			},
		})

	for change_variant in game_event.state_changes:
		if change_variant is Dictionary:
			var movement_path_variant: Variant = change_variant.get("resolved_movement_path", [])
			if movement_path_variant is Array:
				var resolved_path: Array[Vector2i] = []
				for path_point_variant in movement_path_variant:
					var grid_cell: Vector2i = _grid_position_from_payload({"grid_position": path_point_variant})
					if _is_valid_grid_position(grid_cell):
						resolved_path.append(grid_cell)
				if resolved_path.size() > 1:
					resolved_movement_paths[str(change_variant.get("combatant_id", ""))] = resolved_path
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
	_refresh_board_controls()
	_refresh_combat_grid()
	if game_event.event_type == "movement_phase_ended" and not resolved_movement_paths.is_empty():
		combatGrid.play_movement_animation(resolved_movement_paths)
	_update_round_ui()

func apply_combat_request(combat_request: CombatRequest) -> void:
	if combat_request == null:
		return
	SignalBus.emit_gameplay_event("combat_action_requested", "combat", {
		"combatant_id": combat_request.combatant_id,
		"target_id": combat_request.target_id,
		"round": round_number,
		"phase": current_phase,
		"action": {
			"request_type": combat_request.request_type,
			"name": str(combat_request.payload.get("action_name", "")),
			"payload": combat_request.payload.duplicate(true),
		},
		"metadata": {
			"timestamp": combat_request.timestamp,
		},
	})

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
	return _resolve_queued_action_preview(combat_request)

func _cancel_pending_actions_for_queue(queue: Array[CombatRequest], combatant_id: String) -> int:
	var removed_count := 0
	for index in range(queue.size() - 1, -1, -1):
		var request := queue[index]
		if request != null and request.combatant_id == combatant_id:
			queue.remove_at(index)
			removed_count += 1
	return removed_count

func _get_reserved_ap_for_queue(queue: Array[CombatRequest], combatant_id: String) -> int:
	var reserved_ap := 0
	for pending_request in queue:
		if pending_request == null or pending_request.combatant_id != combatant_id:
			continue
		reserved_ap += int(pending_request.payload.get("ap_cost", 0))
	return reserved_ap

func _get_reserved_ap_from_payload(payload: Dictionary) -> int:
	var reserved_ap := 0
	for queued_payload_variant in payload.get("queued_action_payloads", []):
		if not (queued_payload_variant is Dictionary):
			continue
		reserved_ap += int((queued_payload_variant as Dictionary).get("ap_cost", 0))
	return reserved_ap

func _resolve_queued_action_preview(combat_request: CombatRequest) -> Dictionary:
	var source_id := combat_request.combatant_id
	var target_id := combat_request.target_id
	if source_id.is_empty() or target_id.is_empty():
		return {"state_changes": [], "results": []}
	if not encounter_combatants.has(source_id) or not encounter_combatants.has(target_id):
		return {"state_changes": [], "results": []}

	var source_payload: Dictionary = encounter_combatants[source_id].duplicate(true)
	var target_payload: Dictionary = encounter_combatants[target_id].duplicate(true)
	var official_source_actor := _get_actor_data_from_payload(source_payload)
	var official_target_actor := _get_actor_data_from_payload(target_payload)
	var source_actor: CreatureData = null
	var target_actor: CreatureData = null
	if official_source_actor != null:
		source_actor = official_source_actor.duplicate(true) as CreatureData
	if target_id == source_id:
		target_actor = source_actor
	elif official_target_actor != null:
		target_actor = official_target_actor.duplicate(true) as CreatureData
	if source_actor == null or target_actor == null:
		return {"state_changes": [], "results": []}
	SignalBus.emit_gameplay_event("combat_action_resolving", "combat", {
		"combatant_id": source_id,
		"target_id": target_id,
		"round": round_number,
		"phase": current_phase,
		"source": _build_combatant_signal_payload(source_payload, source_actor),
		"target": _build_combatant_signal_payload(target_payload, target_actor),
		"action": {
			"request_type": combat_request.request_type,
			"name": str(combat_request.payload.get("action_name", "")),
			"payload": combat_request.payload.duplicate(true),
		},
		"metadata": {
			"timestamp": combat_request.timestamp,
		},
	})

	var action_name := str(combat_request.payload.get("action_name", ""))
	var action_source := str(combat_request.payload.get("action_source", "Innate"))
	var action_hand := str(combat_request.payload.get("action_hand", "Innate"))
	if action_name == "Stunned":
		var stunned_speed := int(combat_request.payload.get("action_speed", 0))
		_clear_stunned(source_actor)
		var stunned_result := {
			"success": true,
			"source_name": str(source_payload.get("name", source_id)),
			"target_name": str(target_payload.get("name", target_id)),
			"action_name": "Stunned",
			"ap_cost": 0,
			"action_speed": stunned_speed,
		}
		var stunned_source_update := _rebuild_combatant_payload_for_actor(source_payload, source_actor, int(source_payload.get("active_loadout", 1)))
		var stunned_state_changes: Array[Dictionary] = []
		if not stunned_source_update.is_empty():
			stunned_source_update["pending_request"] = ""
			stunned_source_update["conditions"] = _serialize_condition_names(source_actor.conditions)
			stunned_source_update["stunned_round"] = -1
			stunned_source_update["stunned_resolve_speed"] = 0
			stunned_source_update["stunned_spent_ap"] = 0
			stunned_source_update.erase("id")
			stunned_source_update["combatant_id"] = source_id
			stunned_state_changes.append(stunned_source_update)
		var stunned_resolution := {"state_changes": stunned_state_changes, "results": [_build_action_narration_entries(stunned_result)], "resolved_result": stunned_result, "request": CombatRequest.from_dict(combat_request.to_dict()), "source_payload": source_payload, "target_payload": target_payload}
		SignalBus.emit_gameplay_event("combat_action_resolved", "combat", {
			"combatant_id": source_id,
			"target_id": target_id,
			"round": round_number,
			"phase": current_phase,
			"source": _build_combatant_signal_payload(source_payload, source_actor),
			"target": _build_combatant_signal_payload(target_payload, target_actor),
			"action": {
				"request_type": combat_request.request_type,
				"name": action_name,
			},
			"metadata": {
				"resolution": stunned_resolution.duplicate(true),
			},
		})
		return stunned_resolution
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
		"target_location_mode": str(combat_request.payload.get("target_location_mode", TARGET_LOCATION_MODE_RANDOM)),
		"targeting_mode": str(combat_request.payload.get("targeting_mode", "single")),
		"accuracy_bonus": int(combat_request.payload.get("accuracy_bonus", 0)),
		"quick_slot_index": int(combat_request.payload.get("quick_slot_index", -1)),
		"quick_item_name": str(combat_request.payload.get("quick_item_name", "")),
		"skill_name": str(combat_request.payload.get("skill_name", "")),
		"skill_test_description": str(combat_request.payload.get("skill_test_description", "")),
		"skill_difficulty": int(combat_request.payload.get("skill_difficulty", 0)),
		"no_target": bool(combat_request.payload.get("no_target", false)),
		"source_name": str(source_payload.get("name", source_id)),
		"target_name": str(target_payload.get("name", target_id)),
		"forced_outcome": str(combat_request.payload.get("forced_outcome", "")),
		"weapon": weapon,
		"grid_distance": _get_combatant_grid_distance(source_payload, target_payload),
		"source_engaged": _is_adjacent_to_hostile_combatant(source_id, _grid_position_from_payload(source_payload)),
	}
	var result = action.use(target_actor, source_actor, weapon.damage_profile if weapon != null else null, action_context)
	var action_ap_cost := int(combat_request.payload.get("ap_cost", RuleEngine.getActionAPCost(action, weapon)))
	var action_speed := int(combat_request.payload.get("action_speed", RuleEngine.getActionSpeed(action, weapon)))
	if result is Dictionary:
		result["ap_cost"] = action_ap_cost
		result["action_speed"] = action_speed

	var state_changes: Array[Dictionary] = []
	var resolved_loadout := active_loadout
	if result is Dictionary and result.has("active_loadout"):
		resolved_loadout = int(result.get("active_loadout", active_loadout))
	var source_update := _rebuild_combatant_payload_for_actor(source_payload, source_actor, resolved_loadout)
	if not source_update.is_empty():
		source_update["pending_request"] = ""
		source_update.erase("id")
		source_update["combatant_id"] = source_id
		state_changes.append(source_update)

	if target_id != source_id:
		var target_update := _rebuild_combatant_payload_for_actor(target_payload, target_actor, int(target_payload.get("active_loadout", 1)))
		var remaining_preview_queue: Array[CombatRequest] = []
		for pending_request in pending_resolution_requests:
			if pending_request != null and pending_request.combatant_id == combat_request.combatant_id and pending_request.target_id == combat_request.target_id and is_equal_approx(pending_request.timestamp, combat_request.timestamp):
				continue
			remaining_preview_queue.append(pending_request)
		if result is Dictionary and (bool((result as Dictionary).get("is_unconscious", false)) or bool((result as Dictionary).get("is_dead", false))):
			if _has_remaining_turn_actions(target_payload):
				var cancelled_actions := _cancel_pending_actions_for_queue(remaining_preview_queue, target_id)
				if target_update.is_empty():
					target_update = _rebuild_combatant_payload_for_actor(target_payload, target_actor, int(target_payload.get("active_loadout", 1)))
				if not target_update.is_empty():
					target_update["remaining_action_points"] = 0
					target_update["queued_actions"] = []
					target_update["queued_action_payloads"] = []
					target_update["movement_choice"] = {}
					target_update["movement_path"] = []
					target_update["movement_ap_cost"] = 0
					target_update["pending_request"] = ""
					result["cancelled_actions"] = true
					result["cancelled_action_count"] = cancelled_actions
		elif result is Dictionary and str((result as Dictionary).get("condition_name", "")) == "Stunned" and (bool((result as Dictionary).get("condition_applied", false)) or bool((result as Dictionary).get("condition_already_present", false))):
			var already_stunned := bool((result as Dictionary).get("condition_already_present", false)) or _has_pending_stun(target_actor)
			result["already_stunned"] = already_stunned
			if not already_stunned:
				if _has_remaining_turn_actions(target_payload):
					var stunned_cancelled_actions := _cancel_pending_actions_for_queue(remaining_preview_queue, target_id)
					if target_update.is_empty():
						target_update = _rebuild_combatant_payload_for_actor(target_payload, target_actor, int(target_payload.get("active_loadout", 1)))
					if not target_update.is_empty():
						target_update["remaining_action_points"] = 0
						target_update["queued_actions"] = []
						target_update["queued_action_payloads"] = []
						target_update["movement_choice"] = {}
						target_update["movement_path"] = []
						target_update["movement_ap_cost"] = 0
						target_update["pending_request"] = ""
						result["cancelled_actions"] = true
						result["cancelled_action_count"] = stunned_cancelled_actions
				var stunned_resolve_speed := int(combat_request.payload.get("resolve_speed", (result as Dictionary).get("action_speed", 0)))
				var reserved_future_ap := _get_reserved_ap_from_payload(target_payload)
				var effective_remaining_ap := int(target_payload.get("remaining_action_points", 0)) + reserved_future_ap
				var stunned_spent_ap := maxi(_get_round_action_points(target_payload) - effective_remaining_ap, 0)
				_apply_stunned(target_actor, round_number + 1, stunned_resolve_speed, stunned_spent_ap)
				result["stunned_round"] = round_number + 1
				result["stunned_resolve_speed"] = stunned_resolve_speed
				result["stunned_spent_ap"] = stunned_spent_ap
				result["remaining_conditions"] = _serialize_condition_names(target_actor.conditions)
				if target_update.is_empty():
					target_update = _rebuild_combatant_payload_for_actor(target_payload, target_actor, int(target_payload.get("active_loadout", 1)))
				if not target_update.is_empty():
					target_update["stunned_round"] = _get_stunned_round(target_actor)
					target_update["stunned_resolve_speed"] = _get_stunned_resolve_speed(target_actor)
					target_update["stunned_spent_ap"] = stunned_spent_ap
					target_update["conditions"] = _serialize_condition_names(target_actor.conditions)
		if result is Dictionary and not target_update.is_empty() and str((result as Dictionary).get("condition_name", "")) == "Bleed":
			target_update["current_hp"] = target_actor.currentHP
			target_update["current_vitality"] = target_actor.currentVitality
			target_update["conditions"] = _serialize_condition_names(target_actor.conditions)
			target_update["bleed_turns_remaining"] = _get_bleed_turns_remaining(target_actor)
		if not target_update.is_empty():
			target_update.erase("id")
			target_update["combatant_id"] = target_id
			state_changes.append(target_update)

	var results: Array[Dictionary] = []
	if result is Dictionary:
		var narration := _build_action_narration_entries(result as Dictionary)
		results.append(narration)
		if bool((result as Dictionary).get("cancelled_actions", false)):
			var cancel_reason := "loses concentration"
			if str((result as Dictionary).get("condition_name", "")) == "Stunned":
				cancel_reason = "is stunned"
			if bool((result as Dictionary).get("is_dead", false)):
				cancel_reason = "dies"
			elif bool((result as Dictionary).get("is_unconscious", false)):
				cancel_reason = "falls unconscious"
			results.append({
				"text": "%s %s and their remaining actions are cancelled." % [target_payload.get("name", target_id), cancel_reason],
				"tooltip": "%s queued actions were removed." % int((result as Dictionary).get("cancelled_action_count", 0)),
			})
		elif bool((result as Dictionary).get("concentration_broken", false)):
			results.append({
				"text": "%s loses concentration and all stored mana." % target_payload.get("name", target_id),
				"tooltip": "Mana drops to %s." % int((result as Dictionary).get("remaining_mana", 0)),
			})
		if bool((result as Dictionary).get("already_stunned", false)):
			results.append({
				"text": "%s is already stunned." % target_payload.get("name", target_id),
				"tooltip": "Additional stun effects do not stack until the current stun clears.",
			})

	var resolution := {"state_changes": state_changes, "results": results, "resolved_result": result, "request": CombatRequest.from_dict(combat_request.to_dict()), "source_payload": source_payload, "target_payload": target_payload}
	SignalBus.emit_gameplay_event("combat_action_resolved", "combat", {
		"combatant_id": source_id,
		"target_id": target_id,
		"round": round_number,
		"phase": current_phase,
		"source": _build_combatant_signal_payload(source_payload, source_actor),
		"target": _build_combatant_signal_payload(target_payload, target_actor),
		"action": {
			"request_type": combat_request.request_type,
			"name": action_name,
		},
		"metadata": {
			"resolution": resolution.duplicate(true),
		},
	})
	return resolution

func _end_movement_phase() -> void:
	if not is_host_role or current_phase != GameEvent.PHASE_PLANNING:
		return
	_queue_host_npc_movement_previews()
	var resolution := _resolve_movement_phase()
	var state_changes: Array[Dictionary] = []
	for state_change_variant in resolution.get("state_changes", []):
		if state_change_variant is Dictionary:
			state_changes.append(state_change_variant)
	var results: Array[Dictionary] = []
	for result_variant in resolution.get("results", []):
		if result_variant is Dictionary:
			results.append(result_variant)
	if results.is_empty():
		results.append({"text": "Movement phase ended."})
	var game_event := GameEvent.new(
		"movement_phase_ended",
		GameEvent.CONTEXT_COMBAT,
		{
			"board_columns": board_columns,
			"board_rows": board_rows,
		},
		state_changes,
		results,
		round_number,
		GameEvent.PHASE_EXECUTION
	)
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.broadcast_game_event(game_event)

func _queue_host_npc_movement_previews() -> void:
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id]
		if str(payload.get("type", "")) != "NPC":
			continue
		if float(payload.get("current_hp", 0.0)) <= 0.0 or int(payload.get("remaining_action_points", payload.get("action_points", 0))) <= 0:
			continue
		var movement_choice_variant = payload.get("movement_choice", {})
		if movement_choice_variant is Dictionary and not (movement_choice_variant as Dictionary).is_empty():
			continue
		var movement_payload := _build_npc_movement_payload(combatant_id)
		if movement_payload.is_empty():
			continue
		_apply_combat_request_preview(CombatRequest.new(
			CombatRequest.TYPE_MOVEMENT,
			combatant_id,
			combatant_id,
			movement_payload
		))

func _resolve_movement_phase() -> Dictionary:
	var results: Array[Dictionary] = []
	var state_changes: Array[Dictionary] = []
	var resolved_updates: Dictionary = {}
	var movement_entries: Array[Dictionary] = []
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id]
		var movement_choice: Dictionary = {}
		if payload.get("movement_choice", {}) is Dictionary:
			movement_choice = payload.get("movement_choice", {})
		if movement_choice.is_empty():
			continue
		if bool(movement_choice.get("stand_up", false)):
			var update := _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
			if update.is_empty():
				continue
			var actor := _get_actor_data_from_payload(payload)
			if actor != null:
				RuleEngine.removeCondition(actor, "Prone")
				update = _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
			if update.is_empty():
				continue
			update["remaining_action_points"] = max(int(payload.get("remaining_action_points", payload.get("action_points", 0))) + int(payload.get("movement_ap_cost", 0)) - 4, 0)
			update["movement_choice"] = {}
			update["movement_path"] = []
			update["movement_ap_cost"] = 0
			update["pending_request"] = ""
			update.erase("id")
			update["combatant_id"] = combatant_id
			resolved_updates[combatant_id] = update
			results.append({
				"text": "%s stands up." % payload.get("name", "Someone"),
				"tooltip": "Stand Up costs 4 AP and removes Prone.",
			})
			continue
		movement_entries.append({
			"combatant_id": combatant_id,
			"dexterity_score": int(payload.get("dexterity_score", 0)),
			"timestamp": float(movement_choice.get("queued_timestamp", 0.0)),
		})
	movement_entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var timestamp_a := float(a.get("timestamp", 0.0))
		var timestamp_b := float(b.get("timestamp", 0.0))
		if not is_equal_approx(timestamp_a, timestamp_b):
			return timestamp_a < timestamp_b
		return str(a.get("combatant_id", "")) < str(b.get("combatant_id", ""))
	)
	var resolution_data: Dictionary = _resolve_movement_paths_simultaneously(movement_entries)
	var resolved_paths: Dictionary = resolution_data.get("resolved_paths", {})
	var final_positions: Dictionary = resolution_data.get("final_positions", {})
	var spent_action_points: Dictionary = resolution_data.get("spent_action_points", {})

	for movement_entry in movement_entries:
		var combatant_id := str(movement_entry.get("combatant_id", ""))
		if not encounter_combatants.has(combatant_id):
			continue
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		var start: Vector2i = _grid_position_from_payload(payload)
		var preview_cost := int(payload.get("movement_ap_cost", 0))
		var resolved_path: Array[Vector2i] = [start]
		if resolved_paths.has(combatant_id):
			var existing_path_variant: Variant = resolved_paths[combatant_id]
			if existing_path_variant is Array:
				resolved_path = _vector2i_array_from_variant_array(existing_path_variant)
		var final_position: Vector2i = start
		if final_positions.has(combatant_id):
			var final_position_variant: Variant = final_positions[combatant_id]
			if final_position_variant is Vector2i:
				final_position = final_position_variant
		var final_cost: int = int(spent_action_points.get(combatant_id, 0))
		var update := _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
		if update.is_empty():
			continue
		update["remaining_action_points"] = max(int(payload.get("remaining_action_points", payload.get("action_points", 0))) + preview_cost - final_cost, 0)
		update["grid_position"] = final_position
		update["planned_grid_position"] = final_position
		update["movement_choice"] = {}
		update["movement_path"] = []
		update["movement_ap_cost"] = 0
		update["pending_request"] = ""
		update["resolved_movement_path"] = resolved_path.duplicate(true)
		update.erase("id")
		update["combatant_id"] = combatant_id
		resolved_updates[combatant_id] = update
		if final_cost > 0:
			results.append({
				"text": "%s moves to (%s, %s)." % [payload.get("name", "Someone"), final_position.x + 1, final_position.y + 1],
				"tooltip": "Path cost: %s AP." % final_cost,
			})

	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		if resolved_updates.has(combatant_id):
			state_changes.append(resolved_updates[combatant_id])
			continue
		var payload: Dictionary = encounter_combatants[combatant_id]
		var update := _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
		if update.is_empty():
			continue
		var current_position := _grid_position_from_payload(payload)
		update["grid_position"] = current_position
		update["planned_grid_position"] = current_position
		update["movement_choice"] = {}
		update["movement_path"] = []
		update["movement_ap_cost"] = 0
		update["pending_request"] = ""
		update["resolved_movement_path"] = []
		update.erase("id")
		update["combatant_id"] = combatant_id
		state_changes.append(update)

	return {
		"state_changes": state_changes,
		"results": results,
	}

func _resolve_movement_paths_simultaneously(movement_entries: Array[Dictionary]) -> Dictionary:
	var current_positions: Dictionary = {}
	var desired_paths: Dictionary = {}
	var resolved_paths: Dictionary = {}
	var active_movers: Dictionary = {}
	var spent_action_points: Dictionary = {}
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id: String = str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id]
		var grid_position: Vector2i = _grid_position_from_payload(payload)
		if _is_valid_grid_position(grid_position):
			current_positions[combatant_id] = grid_position
	for movement_entry in movement_entries:
		var combatant_id: String = str(movement_entry.get("combatant_id", ""))
		if not encounter_combatants.has(combatant_id):
			continue
		var payload: Dictionary = encounter_combatants[combatant_id]
		var start: Vector2i = _grid_position_from_payload(payload)
		if current_positions.has(combatant_id):
			var start_variant: Variant = current_positions[combatant_id]
			if start_variant is Vector2i:
				start = start_variant
		var desired_path: Array[Vector2i] = _vector2i_array_from_variant_array(payload.get("movement_path", []))
		if desired_path.is_empty() or desired_path[0] != start:
			desired_path.push_front(start)
		desired_paths[combatant_id] = desired_path
		resolved_paths[combatant_id] = [start]
		active_movers[combatant_id] = 1
		spent_action_points[combatant_id] = 0

	while not active_movers.is_empty():
		var occupied_cells: Dictionary = {}
		var proposed_step_costs: Dictionary = {}
		for combatant_id_variant in current_positions.keys():
			var combatant_id: String = str(combatant_id_variant)
			var occupied_cell: Variant = current_positions[combatant_id]
			occupied_cells[occupied_cell] = combatant_id
		var proposals: Dictionary = {}
		var next_cells: Dictionary = {}
		var movers_this_round: Array[String] = []
		for combatant_id_variant in active_movers.keys():
			var combatant_id: String = str(combatant_id_variant)
			var path: Array[Vector2i] = []
			if desired_paths.has(combatant_id):
				var desired_path_variant: Variant = desired_paths[combatant_id]
				if desired_path_variant is Array:
					path = _vector2i_array_from_variant_array(desired_path_variant)
			var next_index: int = int(active_movers[combatant_id])
			if next_index >= path.size():
				active_movers.erase(combatant_id)
				continue
			var next_cell: Vector2i = path[next_index]
			var current_cell: Vector2i = path[next_index - 1]
			next_cells[combatant_id] = next_cell
			proposed_step_costs[combatant_id] = _get_movement_step_cost(combatant_id, current_cell, next_cell, current_positions)
			if not proposals.has(next_cell):
				proposals[next_cell] = []
			(proposals[next_cell] as Array).append(combatant_id)
			movers_this_round.append(combatant_id)
		if movers_this_round.is_empty():
			break

		var blocked_movers: Dictionary = {}
		for target_cell_variant in proposals.keys():
			var target_cell: Vector2i = target_cell_variant
			var claimants: Array = proposals[target_cell]
			if claimants.size() > 1:
				var winner_id: String = _select_contested_move_winner(claimants, movement_entries)
				for claimant_variant in claimants:
					var claimant_id: String = str(claimant_variant)
					if claimant_id != winner_id:
						blocked_movers[claimant_id] = true

		for combatant_id in movers_this_round:
			if blocked_movers.has(combatant_id):
				continue
			var next_cell: Vector2i = next_cells[combatant_id]
			var step_cost: int = int(proposed_step_costs.get(combatant_id, 1))
			var available_ap: int = _get_available_movement_ap(combatant_id)
			var spent_ap: int = int(spent_action_points.get(combatant_id, 0))
			if spent_ap + step_cost > available_ap:
				blocked_movers[combatant_id] = true
				continue
			var occupant_id: String = str(occupied_cells.get(next_cell, ""))
			if occupant_id.is_empty():
				continue
			if occupant_id == combatant_id:
				continue
			if not active_movers.has(occupant_id):
				blocked_movers[combatant_id] = true
				continue
			var occupant_next: Vector2i = Vector2i(-1, -1)
			var occupant_current_variant: Variant = current_positions[occupant_id]
			if occupant_current_variant is Vector2i:
				occupant_next = occupant_current_variant
			if next_cells.has(occupant_id):
				var occupant_next_variant: Variant = next_cells[occupant_id]
				if occupant_next_variant is Vector2i:
					occupant_next = occupant_next_variant
			var mover_current_cell: Vector2i = Vector2i(-1, -1)
			var mover_current_variant: Variant = current_positions[combatant_id]
			if mover_current_variant is Vector2i:
				mover_current_cell = mover_current_variant
			if occupant_next == mover_current_cell:
				blocked_movers[combatant_id] = true
				blocked_movers[occupant_id] = true

		var moved_any: bool = false
		for combatant_id in movers_this_round:
			if blocked_movers.has(combatant_id):
				active_movers.erase(combatant_id)
				continue
			var next_cell: Vector2i = next_cells[combatant_id]
			current_positions[combatant_id] = next_cell
			var resolved_path: Array[Vector2i] = []
			if resolved_paths.has(combatant_id):
				var resolved_path_variant: Variant = resolved_paths[combatant_id]
				if resolved_path_variant is Array:
					resolved_path = _vector2i_array_from_variant_array(resolved_path_variant)
			resolved_path.append(next_cell)
			resolved_paths[combatant_id] = resolved_path
			spent_action_points[combatant_id] = int(spent_action_points.get(combatant_id, 0)) + int(proposed_step_costs.get(combatant_id, 1))
			active_movers[combatant_id] = int(active_movers[combatant_id]) + 1
			moved_any = true
		var contact_locked_ids: Array[String] = []
		for combatant_id in movers_this_round:
			if not active_movers.has(combatant_id):
				continue
			var mover_position_variant: Variant = current_positions.get(combatant_id, null)
			if not (mover_position_variant is Vector2i):
				continue
			if _is_adjacent_to_hostile_in_positions(combatant_id, mover_position_variant, current_positions):
				contact_locked_ids.append(combatant_id)
		for combatant_id in contact_locked_ids:
			active_movers.erase(combatant_id)
		if not moved_any:
			break

	for combatant_id_variant in desired_paths.keys():
		var combatant_id: String = str(combatant_id_variant)
		if not current_positions.has(combatant_id):
			continue
		if not resolved_paths.has(combatant_id):
			resolved_paths[combatant_id] = [current_positions[combatant_id]]
	return {
		"resolved_paths": resolved_paths,
		"final_positions": current_positions,
		"spent_action_points": spent_action_points,
	}

func _get_available_movement_ap(combatant_id: String) -> int:
	if not encounter_combatants.has(combatant_id):
		return 0
	var payload: Dictionary = encounter_combatants[combatant_id]
	return int(payload.get("remaining_action_points", payload.get("action_points", 0))) + int(payload.get("movement_ap_cost", 0))

func _get_path_movement_cost(combatant_id: String, path: Array[Vector2i], positions: Dictionary) -> int:
	if path.size() <= 1:
		return 0
	var total_cost: int = 0
	for step_index in range(path.size() - 1):
		var from_cell: Vector2i = path[step_index]
		var to_cell: Vector2i = path[step_index + 1]
		total_cost += _get_movement_step_cost(combatant_id, from_cell, to_cell, positions)
	return total_cost

func _trim_path_to_available_ap(combatant_id: String, path: Array[Vector2i], positions: Dictionary, available_ap: int) -> Array[Vector2i]:
	if path.is_empty():
		return []
	var limited_path: Array[Vector2i] = [path[0]]
	var spent_ap: int = 0
	for step_index in range(path.size() - 1):
		var from_cell: Vector2i = path[step_index]
		var to_cell: Vector2i = path[step_index + 1]
		var step_cost: int = _get_movement_step_cost(combatant_id, from_cell, to_cell, positions)
		if spent_ap + step_cost > available_ap:
			break
		spent_ap += step_cost
		limited_path.append(to_cell)
	return limited_path

func _get_movement_step_cost(combatant_id: String, from_cell: Vector2i, to_cell: Vector2i, positions: Dictionary) -> int:
	var current_engagers: Array[String] = _get_engaging_enemy_ids(combatant_id, from_cell, positions)
	if current_engagers.is_empty():
		return 1
	var next_engagers: Array[String] = _get_engaging_enemy_ids(combatant_id, to_cell, positions)
	if next_engagers.is_empty():
		return DISENGAGE_STEP_AP_COST
	return 1

func _get_engaging_enemy_ids(combatant_id: String, grid_position: Vector2i, positions: Dictionary) -> Array[String]:
	var engaging_ids: Array[String] = []
	for other_combatant_id_variant in positions.keys():
		var other_combatant_id: String = str(other_combatant_id_variant)
		if other_combatant_id == combatant_id:
			continue
		if not encounter_combatants.has(combatant_id) or not encounter_combatants.has(other_combatant_id):
			continue
		var mover_payload: Dictionary = encounter_combatants[combatant_id]
		var other_payload: Dictionary = encounter_combatants[other_combatant_id]
		if not _are_hostile_combatants(mover_payload, other_payload):
			continue
		if float(other_payload.get("current_hp", 0.0)) <= 0.0:
			continue
		var other_grid_position: Vector2i = Vector2i(-1, -1)
		var other_grid_position_variant: Variant = positions[other_combatant_id]
		if other_grid_position_variant is Vector2i:
			other_grid_position = other_grid_position_variant
		if _are_grid_positions_adjacent(grid_position, other_grid_position):
			engaging_ids.append(other_combatant_id)
	return engaging_ids

func _is_adjacent_to_hostile_in_positions(combatant_id: String, grid_position: Vector2i, positions: Dictionary) -> bool:
	return not _get_engaging_enemy_ids(combatant_id, grid_position, positions).is_empty()

func _are_hostile_combatants(first_payload: Dictionary, second_payload: Dictionary) -> bool:
	var first_team_id: int = clampi(int(first_payload.get("team_id", 0)), 0, 10)
	var second_team_id: int = clampi(int(second_payload.get("team_id", 0)), 0, 10)
	if first_team_id <= 0 or second_team_id <= 0:
		return false
	return first_team_id != second_team_id

func _is_hostile_target(source_combatant_id: String, target_payload: Dictionary) -> bool:
	if not encounter_combatants.has(source_combatant_id):
		return false
	return _are_hostile_combatants(encounter_combatants[source_combatant_id], target_payload)

func _get_combatant_grid_distance(source_payload: Dictionary, target_payload: Dictionary) -> int:
	var source_grid_position: Vector2i = _grid_position_from_payload(source_payload)
	var target_grid_position: Vector2i = _grid_position_from_payload(target_payload)
	if not _is_valid_grid_position(source_grid_position) or not _is_valid_grid_position(target_grid_position):
		return 0
	return RuleEngine.get_grid_attack_distance(source_grid_position, target_grid_position)

func _is_attack_target_reasonable(source_combatant_id: String, target_combatant_id: String, weapon: Weapon) -> bool:
	if not encounter_combatants.has(source_combatant_id) or not encounter_combatants.has(target_combatant_id):
		return false
	var grid_distance: int = _get_combatant_grid_distance(encounter_combatants[source_combatant_id], encounter_combatants[target_combatant_id])
	var source_grid_position: Vector2i = _grid_position_from_payload(encounter_combatants[source_combatant_id])
	var source_engaged: bool = _is_adjacent_to_hostile_combatant(source_combatant_id, source_grid_position)
	var range_evaluation: Dictionary = RuleEngine.evaluate_weapon_range(weapon, grid_distance, source_engaged)
	return bool(range_evaluation.get("legal", true))

func _get_attack_range_preview(source_payload: Dictionary, target_payload: Dictionary, action_payload: Dictionary) -> Dictionary:
	if source_payload.is_empty() or target_payload.is_empty():
		return {}
	if str(action_payload.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK:
		return {}
	var source_actor: CreatureData = _get_source_actor_for_preview(source_payload)
	if source_actor == null:
		return {}
	var active_loadout: int = int(source_payload.get("active_loadout", 1))
	var action_name: String = str(action_payload.get("action_name", ""))
	var action_source: String = str(action_payload.get("action_source", "Innate"))
	var action_hand: String = str(action_payload.get("action_hand", "Innate"))
	var action_entry: Dictionary = _find_action_entry_for_actor(source_actor, active_loadout, action_name, action_source, action_hand)
	if action_entry.is_empty():
		return {}
	var weapon: Weapon = action_entry.get("weapon", null)
	var distance: int = _get_combatant_grid_distance(source_payload, target_payload)
	var source_combatant_id: String = str(source_payload.get("id", ""))
	var source_engaged: bool = false
	if not source_combatant_id.is_empty():
		var source_grid_position: Vector2i = _grid_position_from_payload(source_payload)
		source_engaged = _is_adjacent_to_hostile_combatant(source_combatant_id, source_grid_position)
	var range_evaluation: Dictionary = RuleEngine.evaluate_weapon_range(weapon, distance, source_engaged)
	var state_label: String = _format_range_state_label(str(range_evaluation.get("range_state", "standard")))
	var accuracy_modifier: int = int(range_evaluation.get("accuracy_modifier", 0))
	var legal: bool = bool(range_evaluation.get("legal", true))
	var modifier_text: String = "0"
	if accuracy_modifier > 0:
		modifier_text = "+%s" % accuracy_modifier
	else:
		modifier_text = str(accuracy_modifier)
	var summary: String = "Range %s: %s" % [distance, state_label]
	if bool(range_evaluation.get("engaged_penalty", false)) and str(range_evaluation.get("range_state", "")) != "engaged_penalty":
		summary += ", pressured"
	if accuracy_modifier != 0:
		summary += " (%s accuracy)" % modifier_text
	var short_text: String = "%s %s" % [distance, state_label]
	if bool(range_evaluation.get("engaged_penalty", false)) and str(range_evaluation.get("range_state", "")) != "engaged_penalty":
		short_text += " pressured"
	if accuracy_modifier != 0:
		short_text += " %s" % modifier_text
	return {
		"legal": legal,
		"distance": distance,
		"range_state": str(range_evaluation.get("range_state", "standard")),
		"engaged_penalty": bool(range_evaluation.get("engaged_penalty", false)),
		"accuracy_modifier": accuracy_modifier,
		"summary": summary,
		"short": short_text,
	}

func _get_source_actor_for_preview(source_payload: Dictionary) -> CreatureData:
	var controller_peer_id: int = int(source_payload.get("controller_peer_id", 0))
	if controller_peer_id != 0 and controller_peer_id == multiplayer.get_unique_id() and PlayerVariables.data != null:
		return PlayerVariables.data
	return _get_actor_data_from_payload(source_payload)

func _is_attack_target_selectable(source_payload: Dictionary, target_payload: Dictionary, action_payload: Dictionary) -> bool:
	if source_payload.is_empty() or target_payload.is_empty():
		return false
	var target_id: String = str(target_payload.get("id", ""))
	var source_id: String = str(source_payload.get("id", ""))
	if target_id.is_empty() or source_id.is_empty():
		return false
	if not _are_hostile_combatants(source_payload, target_payload):
		return false
	var range_preview: Dictionary = _get_attack_range_preview(source_payload, target_payload, action_payload)
	if range_preview.is_empty():
		return false
	return bool(range_preview.get("legal", true))

func _format_range_state_label(range_state: String) -> String:
	match range_state:
		"engaged_penalty":
			return "engaged"
		"adjacent":
			return "adjacent"
		"optimal":
			return "optimal"
		"beyond_max_penalty":
			return "beyond 12"
		"standard":
			return "standard"
		"melee":
			return "melee"
		"out_of_melee":
			return "out of melee"
		_:
			return range_state.replace("_", " ")

func _build_current_position_lookup() -> Dictionary:
	var positions: Dictionary = {}
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id: String = str(combatant_id_variant)
		var grid_position: Vector2i = _grid_position_from_payload(encounter_combatants[combatant_id])
		if _is_valid_grid_position(grid_position):
			positions[combatant_id] = grid_position
	return positions

func _build_npc_movement_payload(combatant_id: String) -> Dictionary:
	if not encounter_combatants.has(combatant_id):
		return {}
	var payload: Dictionary = encounter_combatants[combatant_id]
	var start := _grid_position_from_payload(payload)
	if not _is_valid_grid_position(start):
		return {}
	if _is_adjacent_to_hostile_combatant(combatant_id, start):
		return {}
	var available_ap := int(payload.get("remaining_action_points", payload.get("action_points", 0))) + int(payload.get("movement_ap_cost", 0))
	if available_ap <= 0:
		return {}
	var blocked_cells := _get_occupied_grid_cells(combatant_id)
	var current_positions: Dictionary = _build_current_position_lookup()
	var target_path := _find_path_to_nearest_hostile_adjacency(combatant_id, start, blocked_cells)
	if target_path.is_empty() or target_path.size() <= 1:
		return {}
	var limited_path: Array[Vector2i] = _trim_path_to_available_ap(combatant_id, target_path, current_positions, available_ap)
	if limited_path.size() <= 1:
		return {}
	var destination := limited_path[limited_path.size() - 1]
	var ap_cost: int = _get_path_movement_cost(combatant_id, limited_path, current_positions)
	return {
		"destination": destination,
		"path": limited_path,
		"ap_cost": ap_cost,
		"preview_text": "Move -> (%s, %s) [%s AP]" % [destination.x + 1, destination.y + 1, ap_cost],
	}

func _select_contested_move_winner(claimants: Array, movement_entries: Array[Dictionary]) -> String:
	var best_combatant_id: String = ""
	for claimant_variant in claimants:
		var claimant_id: String = str(claimant_variant)
		if best_combatant_id.is_empty() or _does_mover_outrank(claimant_id, best_combatant_id, movement_entries):
			best_combatant_id = claimant_id
	return best_combatant_id

func _does_mover_outrank(candidate_id: String, current_winner_id: String, movement_entries: Array[Dictionary]) -> bool:
	var candidate_priority: Dictionary = _get_movement_priority(candidate_id, movement_entries)
	var winner_priority: Dictionary = _get_movement_priority(current_winner_id, movement_entries)
	var candidate_dexterity: int = int(candidate_priority.get("dexterity_score", 0))
	var winner_dexterity: int = int(winner_priority.get("dexterity_score", 0))
	if candidate_dexterity != winner_dexterity:
		return candidate_dexterity > winner_dexterity
	var candidate_timestamp: float = float(candidate_priority.get("timestamp", 0.0))
	var winner_timestamp: float = float(winner_priority.get("timestamp", 0.0))
	if not is_equal_approx(candidate_timestamp, winner_timestamp):
		return candidate_timestamp < winner_timestamp
	return candidate_id < current_winner_id

func _get_movement_priority(combatant_id: String, movement_entries: Array[Dictionary]) -> Dictionary:
	for movement_entry in movement_entries:
		if str(movement_entry.get("combatant_id", "")) == combatant_id:
			return movement_entry
	return {
		"combatant_id": combatant_id,
		"dexterity_score": 0,
		"timestamp": 0.0,
	}

func _find_path_to_nearest_hostile_adjacency(combatant_id: String, start: Vector2i, blocked_cells: Array[Vector2i]) -> Array[Vector2i]:
	var candidate_ids: Array = encounter_combatants.keys()
	candidate_ids.sort()
	var best_path: Array[Vector2i] = []
	if not encounter_combatants.has(combatant_id):
		return best_path
	var mover_payload: Dictionary = encounter_combatants[combatant_id]
	for target_id_variant in candidate_ids:
		var target_id: String = str(target_id_variant)
		if target_id == combatant_id:
			continue
		var payload: Dictionary = encounter_combatants[target_id]
		if float(payload.get("current_hp", 0.0)) <= 0.0:
			continue
		if not _are_hostile_combatants(mover_payload, payload):
			continue
		var target_position: Vector2i = _grid_position_from_payload(payload)
		for adjacent in _get_adjacent_grid_cells(target_position):
			if combatGrid.get_combatant_id_at_cell(adjacent) != "":
				continue
			var candidate_path := combatGrid.get_reachable_path(start, adjacent, blocked_cells)
			if candidate_path.is_empty():
				continue
			if best_path.is_empty() or candidate_path.size() < best_path.size():
				best_path = candidate_path
	return best_path

func _is_adjacent_to_hostile_combatant(combatant_id: String, grid_position: Vector2i) -> bool:
	if not encounter_combatants.has(combatant_id):
		return false
	var mover_payload: Dictionary = encounter_combatants[combatant_id]
	for other_combatant_id_variant in encounter_combatants.keys():
		var other_combatant_id: String = str(other_combatant_id_variant)
		if other_combatant_id == combatant_id:
			continue
		var payload: Dictionary = encounter_combatants[other_combatant_id]
		if float(payload.get("current_hp", 0.0)) <= 0.0:
			continue
		if not _are_hostile_combatants(mover_payload, payload):
			continue
		var other_grid_position: Vector2i = _grid_position_from_payload(payload)
		if _are_grid_positions_adjacent(grid_position, other_grid_position):
			return true
	return false

func _get_adjacent_grid_cells(cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for offset in [
		Vector2i.LEFT,
		Vector2i.RIGHT,
		Vector2i.UP,
		Vector2i.DOWN,
		Vector2i(-1, -1),
		Vector2i(1, -1),
		Vector2i(-1, 1),
		Vector2i(1, 1),
	]:
		var candidate: Vector2i = cell + offset
		if _is_valid_grid_position(candidate):
			cells.append(candidate)
	return cells

func _are_grid_positions_adjacent(first_position: Vector2i, second_position: Vector2i) -> bool:
	if first_position == second_position:
		return false
	var x_delta: int = absi(first_position.x - second_position.x)
	var y_delta: int = absi(first_position.y - second_position.y)
	return x_delta <= 1 and y_delta <= 1

func _vector2i_array_from_variant_array(values: Array) -> Array[Vector2i]:
	var converted: Array[Vector2i] = []
	for value in values:
		if value is Vector2i:
			converted.append(value)
		elif value is Vector2:
			var vector := value as Vector2
			converted.append(Vector2i(int(vector.x), int(vector.y)))
		elif value is Dictionary:
			converted.append(Vector2i(int(value.get("x", -1)), int(value.get("y", -1))))
	return converted

func _end_action_phase() -> void:
	if not is_host_role or current_phase != GameEvent.PHASE_EXECUTION:
		return
	SignalBus.emit_gameplay_event("phase_ended", "combat", {
		"round": round_number,
		"phase": current_phase,
		"metadata": {
			"reason": "action_review_started",
		},
	})
	pending_resolution_requests = _get_sorted_queued_requests()
	current_review_request = null
	current_review_resolution = {}
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
		return
	is_reviewing_action_phase = true
	_start_current_action_review()
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
	if not RuleEngine.canAct(npc.data):
		return {}

	var action_entry := _find_npc_attack_entry(npc, int(payload.get("active_loadout", 1)))
	if action_entry.is_empty():
		return {}
	var target_payload := _choose_npc_target_payload(combatant_id, action_entry.get("weapon", null))
	if target_payload.is_empty():
		return {}

	var action: Action = action_entry.get("action", null)
	var weapon: Weapon = action_entry.get("weapon", null)
	var action_ap_cost := RuleEngine.getActionAPCost(action, weapon)
	if action_ap_cost <= 0 or action_ap_cost > int(payload.get("remaining_action_points", payload.get("action_points", 0))):
		return {}
	var action_speed := RuleEngine.getActionSpeed(action, weapon)
	var action_source := "Innate"
	if weapon != null and not weapon._name.is_empty():
		action_source = weapon._name
	var target_name := str(target_payload.get("name", "target"))
	var range_preview: Dictionary = _get_attack_range_preview(payload, target_payload, {
		"action_name": action._name,
		"action_source": action_source,
		"action_hand": str(action_entry.get("hand", "Innate")),
	})
	var preview_suffix: String = ""
	if not range_preview.is_empty():
		preview_suffix = " [%s]" % str(range_preview.get("short", ""))
	return {
		"action_name": action._name,
		"action_source": action_source,
		"action_hand": str(action_entry.get("hand", "Innate")),
		"targeting_mode": "single",
		"target_id": str(target_payload.get("id", "")),
		"target_location": int(Item.ItemSlots.Torso),
		"target_location_mode": TARGET_LOCATION_MODE_RANDOM,
		"target_location_label": "Random",
		"called_shot_penalty": 0,
		"accuracy_bonus": 0,
		"ap_cost": action_ap_cost,
		"action_speed": action_speed,
		"preview_text": "%s -> %s (%s)%s" % [action._name, target_name, "Random", preview_suffix],
	}

func _find_npc_attack_entry(npc: NPC, loadout: int) -> Dictionary:
	for entry in _get_npc_action_entries(npc, loadout):
		var resolved_entry := _get_action_resource_for_entry(npc.data, loadout, entry)
		if resolved_entry.is_empty():
			continue
		var action: Action = resolved_entry.get("action", null)
		if action == null or not action.is_attack_action():
			continue
		return resolved_entry
	for entry in _get_npc_action_entries(npc, loadout):
		return _get_action_resource_for_entry(npc.data, loadout, entry)
	return {}

func _choose_npc_target_payload(source_combatant_id: String, weapon: Weapon = null) -> Dictionary:
	if not selected_combatant_id.is_empty() and encounter_combatants.has(selected_combatant_id):
		var selected_payload: Dictionary = encounter_combatants[selected_combatant_id]
		if float(selected_payload.get("current_hp", 0.0)) > 0.0 and _is_hostile_target(source_combatant_id, selected_payload):
			if _is_attack_target_reasonable(source_combatant_id, str(selected_payload.get("id", "")), weapon):
				return selected_payload

	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	var best_payload: Dictionary = {}
	var best_distance: int = 999999
	for combatant_id_variant in combatant_ids:
		var target_payload: Dictionary = encounter_combatants[str(combatant_id_variant)]
		if float(target_payload.get("current_hp", 0.0)) <= 0.0:
			continue
		if not _is_hostile_target(source_combatant_id, target_payload):
			continue
		var target_id: String = str(target_payload.get("id", ""))
		if not _is_attack_target_reasonable(source_combatant_id, target_id, weapon):
			continue
		var grid_distance: int = _get_combatant_grid_distance(encounter_combatants.get(source_combatant_id, {}), target_payload)
		if best_payload.is_empty() or grid_distance < best_distance:
			best_payload = target_payload
			best_distance = grid_distance
	return best_payload

func _get_action_resource_for_entry(actor: CreatureData, loadout: int, action_entry: Dictionary) -> Dictionary:
	var action_name := str(action_entry.get("name", ""))
	var action_source := str(action_entry.get("source", "Innate"))
	var action_hand := str(action_entry.get("hand", "Innate"))
	return _find_action_entry_for_actor(actor, loadout, action_name, action_source, action_hand)

func _format_action_result(result: Dictionary) -> String:
	if result.get("hit", null) == null:
		if str(result.get("action_name", "")) == "Stunned":
			return "%s loses time to Stunned, acting at speed %s before recovering." % [
				result.get("source_name", "Someone"),
				result.get("action_speed", 0),
			]
		if str(result.get("action_name", "")) == "Perform Skill Test":
			var description := str(result.get("skill_test_description", "")).strip_edges()
			var skill_name := str(result.get("skill_name", "Skill"))
			if bool(result.get("contested", false)):
				return "%s tested %s against %s in a contested check%s: %s vs %s, %s." % [
					result.get("source_name", "Someone"),
					skill_name,
					result.get("target_name", "target"),
					" (%s)" % description if not description.is_empty() else "",
					result.get("source_total", 0),
					result.get("target_total", 0),
					"success" if bool(result.get("passed", false)) else "failure",
				]
			return "%s attempted %s%s: %s vs DC %s, %s." % [
				result.get("source_name", "Someone"),
				skill_name,
				" (%s)" % description if not description.is_empty() else "",
				result.get("total", 0),
				result.get("difficulty", 0),
				"success" if bool(result.get("passed", false)) else "failure",
			]
		if str(result.get("reason", "")) == "out_of_range":
			return "%s could not use %s on %s: target is out of melee range at distance %s." % [
				result.get("source_name", "Someone"),
				result.get("action_name", "an action"),
				result.get("target_name", "target"),
				result.get("distance", 0),
			]
		if str(result.get("reason", "")) == "insufficient_mana":
			return "%s tried to use %s on %s, but the attack fizzled for lack of mana (%s needed, %s available)." % [
				result.get("source_name", "Someone"),
				result.get("action_name", "an action"),
				result.get("target_name", "target"),
				result.get("mana_cost", 0),
				result.get("remaining_mana", 0),
			]
		if str(result.get("reason", "")) == "round_limit_reached":
			return "%s cannot use %s again this round." % [
				result.get("source_name", "Someone"),
				result.get("action_name", "that action"),
			]
		if str(result.get("reason", "")) == "target_dead":
			return "%s cannot use %s on %s because they are already dead." % [
				result.get("source_name", "Someone"),
				result.get("action_name", "that action"),
				result.get("target_name", "target"),
			]
		if str(result.get("reason", "")) == "empty_quick_slot":
			return "%s tried to use a quick item, but that slot was empty." % result.get("source_name", "Someone")
		if str(result.get("reason", "")) in ["unsupported_quick_item", "unsupported_consumable", "unsupported_utility"]:
			return "%s tried to use %s, but that quick item is not supported yet." % [
				result.get("source_name", "Someone"),
				result.get("quick_item_name", "that item"),
			]
		if result.has("applied_bonuses") and result.get("applied_bonuses", {}).has("physical"):
			return "%s braces and gains +%s Physical and Magical DT for the round." % [
				result.get("source_name", "Someone"),
				result.get("amount", 0),
			]
		if result.has("defence_names"):
			var defence_suffix := ""
			if bool(result.get("protector_triggered", false)):
				defence_suffix = " Protector adds +1."
			elif bool(result.get("warden_triggered", false)):
				defence_suffix = " Warden adds +1."
			return "%s bolstered all defences on %s by %s for the round.%s" % [
				result.get("source_name", "Someone"),
				result.get("target_name", "target"),
				result.get("amount", 0),
				defence_suffix,
			]
		if result.has("applied_bonuses") and result.has("duration") and not result.has("defence_names"):
			var brace_suffix := " Stonewall adds +1." if bool(result.get("stonewall_triggered", false)) else ""
			return "%s braces for impact, gaining %s DT for the %s.%s" % [
				result.get("source_name", "Someone"),
				result.get("amount", 0),
				result.get("duration", "round"),
				brace_suffix,
			]
		if result.has("healed_amount"):
			if str(result.get("action_name", "")) == "Use Quick Item":
				return "%s used %s, restoring %s HP." % [
					result.get("source_name", "Someone"),
					result.get("quick_item_name", "a quick item"),
					_format_exact_float(result.get("healed_amount", 0.0)),
				]
			var heal_suffix := " Combat Medic increases the healing." if bool(result.get("combat_medic_triggered", false)) else ""
			return "%s used %s on %s, restoring %s HP.%s" % [
				result.get("source_name", "Someone"),
				result.get("action_name", "First Aid"),
				result.get("target_name", "target"),
				_format_exact_float(result.get("healed_amount", 0.0)),
				heal_suffix,
			]
		if str(result.get("resource", "")) == "mana":
			return "%s used %s, restoring %s mana." % [
				result.get("source_name", "Someone"),
				result.get("quick_item_name", "a quick item"),
				int(result.get("restored_amount", 0)),
			]
		if bool(result.get("already_stunned", false)):
			return "%s used %s on %s: effect roll %s + %s vs %s %s, but %s is already stunned." % [
				result.get("source_name", "Someone"),
				result.get("action_name", "an action"),
				result.get("target_name", "target"),
				result.get("condition_roll", 0),
				result.get("potency", 0),
				result.get("condition_defence", "Defence"),
				result.get("condition_defence_value", 0),
				result.get("target_name", "target"),
			]
		if not str(result.get("condition_name", "")).is_empty():
			if str(result.get("condition_name", "")) == "Bleed" and bool(result.get("bleed_immediate_triggered", false)):
				return "%s used %s on %s: effect roll %s + %s vs %s %s, bleed reapplied for %s immediate damage (%s turn(s) remaining)." % [
					result.get("source_name", "Someone"),
					result.get("action_name", "an action"),
					result.get("target_name", "target"),
					result.get("condition_roll", 0),
					result.get("potency", 0),
					result.get("condition_defence", "Defence"),
					result.get("condition_defence_value", 0),
					result.get("bleed_damage", 0),
					result.get("bleed_turns_remaining", 0),
				]
			return "%s used %s on %s: effect roll %s + %s vs %s %s, %s." % [
				result.get("source_name", "Someone"),
				result.get("action_name", "an action"),
				result.get("target_name", "target"),
				result.get("condition_roll", 0),
				result.get("potency", 0),
				result.get("condition_defence", "Defence"),
				result.get("condition_defence_value", 0),
				("applied %s" % result.get("condition_name", "the effect")) if bool(result.get("condition_applied", false)) else ("%s resisted" % result.get("target_name", "target")),
			]
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
		if not str(result.get("condition_name", "")).is_empty():
			if bool(result.get("already_stunned", false)):
				status_suffix += " Already stunned." 
			elif bool(result.get("condition_applied", false)):
				status_suffix += " %s applied (%s + %s vs %s %s)." % [result.get("condition_name", "Effect"), result.get("condition_roll", 0), result.get("potency", 0), result.get("condition_defence", "Defence"), result.get("condition_defence_value", 0)]
			else:
				status_suffix += " %s resisted (%s + %s vs %s %s)." % [result.get("target_name", "Target"), result.get("condition_roll", 0), result.get("potency", 0), result.get("condition_defence", "Defence"), result.get("condition_defence_value", 0)]
		if bool(result.get("damage_immune", false)):
			status_suffix += " Obsidian Patches protected the %s." % result.get("immune_location_name", result.get("target_location_name", "body"))
		if int(result.get("momentum_bonus", 0)) > 0:
			status_suffix += " Momentum grants +%s Accuracy." % int(result.get("momentum_bonus", 0))
		if bool(result.get("center_of_mass_triggered", false)):
			status_suffix += " Center of Mass grants +%s Accuracy and +20%% damage." % int(result.get("center_of_mass_accuracy_bonus", 0))
		if bool(result.get("point_blank_triggered", false)):
			status_suffix += " Point Blank ignores the engaged ranged penalty."
		if bool(result.get("deadeye_triggered", false)):
			status_suffix += " Deadeye grants +%s Accuracy." % int(result.get("deadeye_accuracy_bonus", 0))
		if bool(result.get("finisher_triggered", false)):
			status_suffix += " Finisher grants +20%% damage."
		return "%s used %s on %s's %s: %s vs %s, %s damage after %s DT, %s temp absorbed, HP %s, VIT %s, %s AP, speed %s.%s" % [
			result.get("source_name", "Someone"),
			result.get("action_name", "an action"),
			result.get("target_name", "target"),
			result.get("target_location_name", "body"),
			result.get("to_hit_total", 0),
			result.get("defence_value", 0),
			_format_exact_float(result.get("total_damage", 0.0)),
			_format_exact_float(result.get("location_dt", 0.0)),
			_format_exact_float(result.get("absorbed_by_temporary_health", 0.0)),
			_display_vital(result.get("remaining_hp", 0.0)),
			_display_vital(result.get("remaining_vitality", 0.0)),
			result.get("ap_cost", 0),
			result.get("action_speed", 0),
			status_suffix,
		]
	return "%s used %s on %s's %s but missed: %s vs %s, range %s (%s), %s AP, speed %s." % [
		result.get("source_name", "Someone"),
		result.get("action_name", "an action"),
		result.get("target_name", "target"),
		result.get("target_location_name", "body"),
		result.get("to_hit_total", 0),
		result.get("defence_value", 0),
		result.get("distance", 0),
		_format_range_state_label(str(result.get("range_state", "standard"))),
		result.get("ap_cost", 0),
		result.get("action_speed", 0),
	]

func _build_action_flavor_text(result: Dictionary) -> String:
	var source_name := str(result.get("source_name", "Someone"))
	var target_name := str(result.get("target_name", "target"))
	var action_name := str(result.get("action_name", "an action"))
	var location_name := str(result.get("target_location_name", "body"))
	var total_damage: float = float(result.get("total_damage", 0.0))
	var location_dt: float = float(result.get("location_dt", 0.0))
	if result.get("hit", null) == null:
		if str(result.get("action_name", "")) == "Stunned":
			return "%s reels, wasting precious moments before they can act again." % source_name
		if str(result.get("action_name", "")) == "Perform Skill Test":
			var skill_description := str(result.get("skill_test_description", "")).strip_edges()
			if bool(result.get("contested", false)):
				if bool(result.get("passed", false)):
					return "%s outmaneuvers %s in a contested %s test%s." % [source_name, target_name, str(result.get("skill_name", "skill")).to_lower(), " while %s" % skill_description if not skill_description.is_empty() else ""]
				return "%s holds firm against %s in a contested %s test%s." % [target_name, source_name, str(result.get("skill_name", "skill")).to_lower(), " while %s" % skill_description if not skill_description.is_empty() else ""]
			return "%s attempts %s%s." % [source_name, str(result.get("skill_name", "skill")).to_lower(), " to %s" % skill_description if not skill_description.is_empty() else ""]
		if str(result.get("reason", "")) == "out_of_range":
			return "%s cannot bring %s to bear on %s from this distance." % [source_name, action_name.to_lower(), target_name]
		if str(result.get("reason", "")) == "insufficient_mana":
			return "%s reaches for power to fuel %s, but the technique fizzles before it lands." % [source_name, action_name.to_lower()]
		if str(result.get("reason", "")) == "round_limit_reached":
			return "%s has already used %s this round." % [source_name, action_name.to_lower()]
		if str(result.get("reason", "")) == "target_dead":
			return "%s tries to apply first aid, but it is already too late for %s." % [source_name, target_name]
		if str(result.get("reason", "")) == "empty_quick_slot":
			return "%s reaches for a quick item, but the chosen slot is empty." % source_name
		if str(result.get("reason", "")) in ["unsupported_quick_item", "unsupported_consumable", "unsupported_utility"]:
			return "%s produces %s, but cannot make effective use of it yet." % [source_name, str(result.get("quick_item_name", "the item")).to_lower()]
		if result.has("healed_amount"):
			if str(result.get("action_name", "")) == "Use Quick Item":
				return "%s quickly uses %s and gets immediate relief." % [source_name, str(result.get("quick_item_name", "the item")).to_lower()]
			return "%s patches up %s and restores some of their strength." % [source_name, target_name]
		if str(result.get("resource", "")) == "mana":
			return "%s drinks %s and feels power surge back into them." % [source_name, str(result.get("quick_item_name", "the item")).to_lower()]
		if bool(result.get("already_stunned", false)):
			return "%s rattles %s, but they are already stunned." % [source_name, target_name]
		if not str(result.get("condition_name", "")).is_empty():
			if str(result.get("condition_name", "")) == "Bleed" and bool(result.get("bleed_immediate_triggered", false)):
				return "%s tears the wound open again, making %s bleed immediately." % [source_name, target_name]
			if bool(result.get("condition_applied", false)):
				return "%s's technique takes hold, leaving %s %s." % [source_name, target_name, str(result.get("condition_name", "affected")).to_lower()]
			return "%s tries to inflict %s, but %s resists the effect." % [source_name, str(result.get("condition_name", "the effect")).to_lower(), target_name]
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
	if bool(result.get("damage_immune", false)):
		return "%s's %s hits %s's %s, but the obsidian patch absorbs the blow completely." % [source_name, action_name.to_lower(), target_name, location_name.to_lower()]
	if total_damage <= 0 and location_dt > 0:
		return "%s's %s strikes %s's %s, but the armor turns the blow aside." % [source_name, action_name.to_lower(), target_name, location_name.to_lower()]
	if not str(result.get("condition_name", "")).is_empty() and bool(result.get("condition_applied", false)):
		return "%s's %s slips through and leaves %s %s." % [source_name, action_name.to_lower(), target_name, str(result.get("condition_name", "affected")).to_lower()]
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
	var location_name := str(current_request.payload.get("target_location_label", _location_name_from_slot(int(current_request.payload.get("target_location", Item.ItemSlots.Torso)))))
	if int(current_request.payload.get("called_shot_penalty", 0)) != 0:
		location_name += " (%s)" % int(current_request.payload.get("called_shot_penalty", 0))
	var category := str(current_request.payload.get("category", Action.CATEGORY_ATTACK))
	var range_preview: Dictionary = _get_attack_range_preview(source_payload, target_payload, current_request.payload)
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
		"Brace":
			flavor = "%s sets themselves against the coming impact." % source_name
		"First Aid":
			flavor = "%s prepares to tend %s's wounds." % [source_name, target_name]
		"Use Quick Item":
			flavor = "%s readies %s for immediate use." % [source_name, str(current_request.payload.get("quick_item_name", "a quick item")).to_lower()]
		"Perform Skill Test":
			var skill_description := str(current_request.payload.get("skill_test_description", "")).strip_edges()
			if bool(current_request.payload.get("no_target", false)):
				flavor = "%s prepares a %s test%s." % [source_name, str(current_request.payload.get("skill_name", "skill")).to_lower(), " to %s" % skill_description if not skill_description.is_empty() else ""]
			else:
				flavor = "%s prepares to contest %s with %s%s." % [source_name, target_name, str(current_request.payload.get("skill_name", "skill")).to_lower(), " to %s" % skill_description if not skill_description.is_empty() else ""]
		"Stunned":
			flavor = "%s reels from the blow, losing precious initiative." % source_name
		"Wait":
			flavor = "%s pauses, watching the field for the right moment." % source_name
		_:
			if category != Action.CATEGORY_ATTACK:
				flavor = "%s prepares %s." % [source_name, action_name.to_lower()]
	var mechanics_text := "%s targets %s's %s with %s (%s AP, speed %s)." % [preview_result["source_name"], preview_result["target_name"], preview_result["target_location_name"], preview_result["action_name"], preview_result["ap_cost"], preview_result["action_speed"]]
	if action_name == "Use Quick Item":
		mechanics_text = "%s uses %s on self (%s AP, speed %s)." % [preview_result["source_name"], current_request.payload.get("quick_item_name", "a quick item"), preview_result["ap_cost"], preview_result["action_speed"]]
	elif action_name == "Perform Skill Test":
		if bool(current_request.payload.get("no_target", false)):
			mechanics_text = "%s attempts %s (%s AP, speed %s). GM sets difficulty on review." % [preview_result["source_name"], current_request.payload.get("skill_name", "a skill test"), preview_result["ap_cost"], preview_result["action_speed"]]
		else:
			mechanics_text = "%s contests %s with %s (%s AP, speed %s)." % [preview_result["source_name"], preview_result["target_name"], current_request.payload.get("skill_name", "a skill test"), preview_result["ap_cost"], preview_result["action_speed"]]
	elif action_name == "Stunned":
		mechanics_text = "%s loses the initiative to Stunned (%s AP, speed %s)." % [preview_result["source_name"], preview_result["ap_cost"], preview_result["action_speed"]]
	if not range_preview.is_empty():
		mechanics_text += " %s" % str(range_preview.get("summary", ""))
	return {
		"flavor": flavor,
		"mechanics": mechanics_text,
	}

func _start_current_action_review() -> void:
	current_review_request = null
	current_review_resolution = {}
	is_editing_review_action = false
	if pending_resolution_requests.is_empty():
		_refresh_action_resolution_window()
		return
	current_review_request = pending_resolution_requests[0]
	current_review_resolution = _resolve_queued_action_preview(current_review_request)
	_refresh_action_resolution_window()

func _build_current_review_header() -> String:
	if current_review_request == null or current_review_resolution.is_empty():
		return "No Pending Actions"
	var preview_request: CombatRequest = current_review_resolution.get("request", current_review_request)
	var source_payload: Dictionary = current_review_resolution.get("source_payload", {})
	var target_payload: Dictionary = current_review_resolution.get("target_payload", {})
	if str(preview_request.payload.get("action_name", "")) == "Perform Skill Test" and bool(preview_request.payload.get("no_target", false)):
		return "%s uses %s (No Target)" % [
			source_payload.get("name", preview_request.combatant_id),
			preview_request.payload.get("action_name", "Pending Action"),
		]
	return "%s uses %s on %s" % [
		source_payload.get("name", preview_request.combatant_id),
		preview_request.payload.get("action_name", "Pending Action"),
		target_payload.get("name", preview_request.target_id),
	]

func _build_current_review_details() -> String:
	if current_review_request == null or current_review_resolution.is_empty():
		return "No resolved action to review."
	var resolved_result: Dictionary = current_review_resolution.get("resolved_result", {})
	return _format_action_result(resolved_result)

func _build_current_review_edit_details() -> String:
	if current_review_request == null or current_review_resolution.is_empty():
		return ""
	var resolved_result: Dictionary = current_review_resolution.get("resolved_result", {})
	if _current_review_is_skill_test():
		var description := str(current_review_request.payload.get("skill_test_description", "")).strip_edges()
		var skill_test_lines: Array[String] = [
			"[b]Skill[/b] %s" % str(current_review_request.payload.get("skill_name", "Skill")),
			"[b]AP / Speed[/b] %s / %s" % [current_review_request.payload.get("ap_cost", 0), current_review_request.payload.get("action_speed", 0)],
		]
		if not description.is_empty():
			skill_test_lines.append("[b]Description[/b] %s" % description)
		if _current_review_is_skill_test_no_target():
			skill_test_lines.append("[b]Difficulty[/b] %s" % int(current_review_request.payload.get("skill_difficulty", 10)))
		else:
			skill_test_lines.append("[b]Contested[/b] Yes")
		return "\n".join(skill_test_lines)
	var target_payload: Dictionary = current_review_resolution.get("target_payload", {})
	var status_suffix := "None"
	if bool(resolved_result.get("is_dead", false)):
		status_suffix = "Dead"
	elif bool(resolved_result.get("is_unconscious", false)):
		status_suffix = "Unconscious"
	var lines: Array[String] = [
		"[b]Roll vs Defence[/b] %s vs %s %s" % [resolved_result.get("to_hit_total", 0), resolved_result.get("defence_name", "Defence"), resolved_result.get("defence_value", 0)],
	]
	if bool(resolved_result.get("hit", false)):
		lines.append("[b]Damage after DT[/b] %s" % _format_exact_float(resolved_result.get("total_damage", 0.0)))
		lines.append("[b]Temp absorbed[/b] %s" % _format_exact_float(resolved_result.get("absorbed_by_temporary_health", 0.0)))
		lines.append("[b]HP / VIT result[/b] %s -> %s | %s -> %s" % [
			_display_vital(target_payload.get("current_hp", 0.0)),
			_display_vital(resolved_result.get("remaining_hp", 0.0)),
			_display_vital(target_payload.get("current_vitality", 0.0)),
			_display_vital(resolved_result.get("remaining_vitality", 0.0)),
		])
	lines.append("[b]AP[/b] %s" % resolved_result.get("ap_cost", 0))
	lines.append("[b]Speed[/b] %s" % resolved_result.get("action_speed", 0))
	lines.append("[b]Status[/b] %s" % status_suffix)
	return "\n".join(lines)

func _normalize_review_resolved_result(resolved_result: Dictionary) -> Dictionary:
	var normalized := resolved_result.duplicate(true)
	var target_payload: Dictionary = current_review_resolution.get("target_payload", {})
	if not bool(normalized.get("hit", false)):
		normalized["did_crit"] = false
		for field_name in REVIEW_ZERO_ON_MISS_FIELDS:
			normalized[field_name] = 0.0
		normalized["remaining_hp"] = float(target_payload.get("current_hp", normalized.get("remaining_hp", 0.0)))
		normalized["remaining_vitality"] = float(target_payload.get("current_vitality", normalized.get("remaining_vitality", 0.0)))
		normalized["remaining_temporary_health"] = float(target_payload.get("temporary_health", normalized.get("remaining_temporary_health", 0.0)))
		normalized["remaining_concentration"] = int(target_payload.get("current_concentration", normalized.get("remaining_concentration", 0)))
		normalized["remaining_mana"] = int(target_payload.get("current_mana", normalized.get("remaining_mana", 0)))
		normalized["cancelled_actions"] = false
		normalized["cancelled_action_count"] = 0
		normalized["already_stunned"] = false
		normalized["stunned_round"] = -1
		normalized["stunned_resolve_speed"] = 0
		normalized["stunned_spent_ap"] = 0
		normalized["bleed_turns_remaining"] = int(target_payload.get("bleed_turns_remaining", 0))
		normalized["condition_applied"] = false
		normalized["condition_name"] = ""
		normalized["remaining_conditions"] = target_payload.get("conditions", []).duplicate(true)
	elif normalized.get("remaining_conditions", null) is Array:
		normalized["remaining_conditions"] = _serialize_condition_names(normalized.get("remaining_conditions", []))
	else:
		normalized["remaining_conditions"] = target_payload.get("conditions", []).duplicate(true)
	if float(normalized.get("remaining_vitality", 0.0)) <= 0.0:
		normalized["is_dead"] = true
		normalized["is_unconscious"] = false
	elif float(normalized.get("remaining_hp", 0.0)) <= 0.0:
		normalized["is_unconscious"] = true
		normalized["is_dead"] = false
	else:
		normalized["is_unconscious"] = false
		normalized["is_dead"] = false
	if bool(normalized.get("is_dead", false)):
		normalized["is_unconscious"] = false
	return normalized

func _get_review_state_change_by_combatant(state_changes: Array, combatant_id: String) -> Dictionary:
	for state_change in state_changes:
		if state_change is Dictionary and str((state_change as Dictionary).get("combatant_id", "")) == combatant_id:
			return (state_change as Dictionary)
	return {}

func _rebuild_review_resolution_from_resolved_result(resolved_result: Dictionary) -> Dictionary:
	if current_review_request == null or current_review_resolution.is_empty():
		return current_review_resolution
	var rebuilt := current_review_resolution.duplicate(true)
	var normalized_result := _normalize_review_resolved_result(resolved_result)
	rebuilt["resolved_result"] = normalized_result
	var target_payload: Dictionary = rebuilt.get("target_payload", {}).duplicate(true)
	var source_change := _get_review_state_change_by_combatant(rebuilt.get("state_changes", []), current_review_request.combatant_id).duplicate(true)
	if not source_change.is_empty():
		source_change["pending_request"] = ""
	var target_change: Dictionary = {}
	if current_review_request.target_id != current_review_request.combatant_id:
		target_change = _get_review_state_change_by_combatant(rebuilt.get("state_changes", []), current_review_request.target_id).duplicate(true)
		if target_change.is_empty():
			target_change = target_payload.duplicate(true)
			target_change.erase("id")
			target_change["combatant_id"] = current_review_request.target_id
		target_change["current_hp"] = float(normalized_result.get("remaining_hp", target_change.get("current_hp", 0.0)))
		target_change["current_vitality"] = float(normalized_result.get("remaining_vitality", target_change.get("current_vitality", 0.0)))
		target_change["temporary_health"] = float(normalized_result.get("remaining_temporary_health", target_change.get("temporary_health", 0.0)))
		target_change["current_concentration"] = int(normalized_result.get("remaining_concentration", target_change.get("current_concentration", 0)))
		target_change["current_mana"] = int(normalized_result.get("remaining_mana", target_change.get("current_mana", 0)))
		if bool(normalized_result.get("cancelled_actions", false)):
			target_change["remaining_action_points"] = 0
			target_change["queued_actions"] = []
			target_change["queued_action_payloads"] = []
			target_change["movement_choice"] = {}
			target_change["movement_path"] = []
			target_change["movement_ap_cost"] = 0
			target_change["pending_request"] = ""
		else:
			target_change["remaining_action_points"] = target_payload.get("remaining_action_points", target_change.get("remaining_action_points", 0))
			target_change["queued_actions"] = target_payload.get("queued_actions", []).duplicate(true)
			target_change["queued_action_payloads"] = target_payload.get("queued_action_payloads", []).duplicate(true)
			target_change["movement_choice"] = target_payload.get("movement_choice", {}).duplicate(true)
			target_change["movement_path"] = target_payload.get("movement_path", []).duplicate(true)
			target_change["movement_ap_cost"] = int(target_payload.get("movement_ap_cost", 0))
			target_change["pending_request"] = target_payload.get("pending_request", "")
		target_change["conditions"] = normalized_result.get("remaining_conditions", target_payload.get("conditions", [])).duplicate(true)
		target_change["stunned_round"] = int(normalized_result.get("stunned_round", target_payload.get("stunned_round", -1)))
		target_change["stunned_resolve_speed"] = int(normalized_result.get("stunned_resolve_speed", target_payload.get("stunned_resolve_speed", 0)))
		target_change["stunned_spent_ap"] = int(normalized_result.get("stunned_spent_ap", target_payload.get("stunned_spent_ap", 0)))
		target_change["bleed_turns_remaining"] = int(normalized_result.get("bleed_turns_remaining", target_payload.get("bleed_turns_remaining", 0)))
	var rebuilt_state_changes: Array[Dictionary] = []
	if not source_change.is_empty():
		rebuilt_state_changes.append(source_change)
	if not target_change.is_empty():
		rebuilt_state_changes.append(target_change)
	rebuilt["state_changes"] = rebuilt_state_changes
	var rebuilt_results: Array[Dictionary] = []
	rebuilt_results.append(_build_action_narration_entries(normalized_result))
	if bool(normalized_result.get("cancelled_actions", false)):
		var cancel_reason := "loses concentration"
		if bool(normalized_result.get("is_dead", false)):
			cancel_reason = "dies"
		elif bool(normalized_result.get("is_unconscious", false)):
			cancel_reason = "falls unconscious"
		elif str(normalized_result.get("condition_name", "")) == "Stunned":
			cancel_reason = "is stunned"
		rebuilt_results.append({
			"text": "%s %s and their remaining actions are cancelled." % [target_payload.get("name", current_review_request.target_id), cancel_reason],
			"tooltip": "%s queued actions were removed." % int(normalized_result.get("cancelled_action_count", 0)),
		})
	elif bool(normalized_result.get("concentration_broken", false)):
		rebuilt_results.append({
			"text": "%s loses concentration and all stored mana." % target_payload.get("name", current_review_request.target_id),
			"tooltip": "Mana drops to %s." % int(normalized_result.get("remaining_mana", 0)),
		})
	if bool(normalized_result.get("already_stunned", false)):
		rebuilt_results.append({
			"text": "%s is already stunned." % target_payload.get("name", current_review_request.target_id),
			"tooltip": "Additional stun effects do not stack until the current stun clears.",
		})
	rebuilt["results"] = rebuilt_results
	return rebuilt

func _set_review_edit_mode(active: bool) -> void:
	is_editing_review_action = active
	resolutionEditPanel.visible = active
	editActionButton.text = "Close Edit" if active else "Edit"
	if active:
		_set_review_edit_form_values(current_review_resolution.get("resolved_result", {}))
		if _current_review_is_skill_test_no_target():
			resolutionSkillDifficultyInput.set_value_no_signal(float(current_review_request.payload.get("skill_difficulty", 10)))
	resolutionEditFormPanel.visible = active and not _current_review_is_skill_test_no_target()

func _toggle_current_review_edit_mode() -> void:
	_set_review_edit_mode(not is_editing_review_action)
	_refresh_action_resolution_window()

func _current_review_is_skill_test() -> bool:
	return current_review_request != null and str(current_review_request.payload.get("action_name", "")) == "Perform Skill Test"

func _current_review_is_skill_test_no_target() -> bool:
	return _current_review_is_skill_test() and bool(current_review_request.payload.get("no_target", false))

func _refresh_action_resolution_window() -> void:
	if pending_resolution_requests.is_empty() or current_review_request == null:
		resolutionTitle.text = "No Pending Actions"
		resolutionProgress.text = "0 remaining"
		abortActionButton.disabled = true
		editActionButton.disabled = true
		resolveActionButton.disabled = true
		resolveAllActionsButton.disabled = true
		resolutionEditPanel.visible = false
		resolutionEditFormPanel.visible = false
		resolutionOutcomeSelector.disabled = true
		resolutionLocationSelector.disabled = true
		resolutionSkillDifficultyLabel.visible = false
		resolutionSkillDifficultyInput.visible = false
		resolutionSkillDifficultyInput.editable = false
		resolutionApplyEditsButton.disabled = true
		resolutionEditDetails.text = ""
		resolutionDetails.text = "All queued actions have been handled."
		return
	abortActionButton.disabled = false
	editActionButton.disabled = false
	resolveActionButton.disabled = false
	resolveAllActionsButton.disabled = false
	resolutionTitle.text = _build_current_review_header()
	resolutionProgress.text = "Reviewing 1 of %s pending actions" % pending_resolution_requests.size()
	var is_attack := str(current_review_request.payload.get("category", Action.CATEGORY_ATTACK)) == Action.CATEGORY_ATTACK
	var is_skill_test_no_target := _current_review_is_skill_test_no_target()
	editActionButton.disabled = not (is_attack or is_skill_test_no_target)
	resolutionOutcomeSelector.disabled = true
	resolutionLocationSelector.disabled = true
	resolutionSkillDifficultyLabel.visible = is_editing_review_action and is_skill_test_no_target
	resolutionSkillDifficultyInput.visible = is_editing_review_action and is_skill_test_no_target
	resolutionSkillDifficultyInput.editable = is_editing_review_action and is_skill_test_no_target
	resolutionApplyEditsButton.disabled = not (is_attack or is_skill_test_no_target)
	_set_review_edit_mode(is_editing_review_action and (is_attack or is_skill_test_no_target))
	resolutionDetails.text = _build_current_review_details()
	resolutionEditDetails.text = _build_current_review_edit_details() if resolutionEditPanel.visible else ""

func _resolve_current_action_resolution() -> void:
	if pending_resolution_requests.is_empty() or current_review_request == null:
		_finalize_action_phase_review()
		return
	_commit_current_review_form_to_resolution()
	pending_resolution_requests.pop_front()
	var approved_request: CombatRequest = current_review_resolution.get("request", current_review_request)
	_apply_approved_review_queue_changes()
	_broadcast_resolution_event("queued_action_resolved", approved_request, current_review_resolution)
	_apply_review_queue_state()
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
	else:
		_start_current_action_review()

func _abort_current_action_resolution() -> void:
	if pending_resolution_requests.is_empty() or current_review_request == null:
		_finalize_action_phase_review()
		return
	pending_resolution_requests.pop_front()
	var rejected_request: CombatRequest = current_review_resolution.get("request", current_review_request)
	var preview := _build_action_preview(rejected_request)
	var results: Array[Dictionary] = [{
		"text": "%s rejected %s targeting %s." % [
			current_review_resolution.get("source_payload", {}).get("name", rejected_request.combatant_id),
			rejected_request.payload.get("action_name", "an action"),
			current_review_resolution.get("target_payload", {}).get("name", rejected_request.target_id),
		],
		"tooltip": str(preview.get("mechanics", "")),
	}]
	_broadcast_resolution_event("queued_action_aborted", rejected_request, {"state_changes": [], "results": results})
	_apply_review_queue_state()
	if pending_resolution_requests.is_empty():
		_finalize_action_phase_review()
	else:
		_start_current_action_review()

func _resolve_all_action_resolutions() -> void:
	while not pending_resolution_requests.is_empty():
		_resolve_current_action_resolution()

func _apply_current_review_edits() -> void:
	if current_review_request == null or current_review_resolution.is_empty():
		return
	_commit_current_review_form_to_resolution()
	_set_review_edit_mode(true)
	_refresh_action_resolution_window()

func _apply_approved_review_queue_changes() -> void:
	var resolved_result: Dictionary = current_review_resolution.get("resolved_result", {})
	if not bool(resolved_result.get("cancelled_actions", false)):
		return
	if current_review_request == null:
		return
	_cancel_pending_actions_for_combatant(current_review_request.target_id)

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
		var queued_payloads: Array = remaining_payloads_by_combatant.get(combatant_id, [])
		var queued_texts: Array[String] = []
		for queued_payload_variant in queued_payloads:
			if queued_payload_variant is Dictionary:
				queued_texts.append(str((queued_payload_variant as Dictionary).get("preview_text", "Action")))
		var state_change := {
			"combatant_id": str(combatant_id),
			"queued_action_payloads": queued_payloads,
			"queued_actions": queued_texts,
			"pending_request": "",
		}
		state_changes.append(state_change)
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
	current_review_request = null
	current_review_resolution = {}
	actionResolutionWindow.hide()
	var state_changes: Array[Dictionary] = []
	var results: Array[Dictionary] = []
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		if not encounter_combatants.has(combatant_id):
			continue
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		var actor := _get_actor_data_from_payload(payload)
		if actor != null:
			if actor.hasCondition("Bleed"):
				var bleed_result := RuleEngine.triggerBleedTick(actor)
				var bleed_turns_remaining := maxi(RuleEngine.getBleedTurnsRemaining(actor) - 1, 0)
				RuleEngine.setBleedTurnsRemaining(actor, bleed_turns_remaining)
				if bleed_turns_remaining <= 0:
					RuleEngine.clearBleed(actor)
				if int(bleed_result.get("bleed_damage", 0)) > 0:
					results.append({
						"text": "%s bleeds for %s damage." % [payload.get("name", "Someone"), int(bleed_result.get("bleed_damage", 0))],
					"tooltip": "Bleed deals 20%% of missing HP at end of turn. %s turn(s) remaining." % RuleEngine.getBleedTurnsRemaining(actor),
					})
				if not actor.hasCondition("Bleed"):
					results.append({
						"text": "%s stops bleeding." % payload.get("name", "Someone"),
						"tooltip": "Bleed duration expired.",
					})
			if actor.hasCondition("Stunned") and _get_stunned_round(actor) == round_number:
				_clear_stunned(actor)
			actor.set_meta("momentum_streak_hits", 0)
			RuleEngine.clearRoundBonuses(actor)
			RuleEngine.restoreConcentration(actor)
			if RuleEngine.canAct(actor):
				RuleEngine.generateMana(actor)
		var reset_payload := _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))
		if reset_payload.is_empty():
			continue
		var next_round_ap := int(reset_payload.get("action_points", 0))
		if actor != null and int(reset_payload.get("stunned_round", -1)) == round_number + 1:
			next_round_ap = maxi(next_round_ap - _get_stunned_spent_ap(actor), 0)
		reset_payload["round_action_points"] = next_round_ap
		reset_payload["remaining_action_points"] = next_round_ap
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
		results,
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

func _action_targets_ally(action_name: String) -> bool:
	return action_name == "Guard"

func _action_targets_self_or_ally(action_name: String) -> bool:
	return action_name == "First Aid"

func _action_allows_any_target(action_name: String) -> bool:
	return action_name == "Perform Skill Test"

func _get_actor_skill_names(actor: CreatureData) -> Array[String]:
	var names: Array[String] = []
	if actor is HumanoidData:
		for skill in (actor as HumanoidData).skills:
			if skill == null or skill._name.is_empty():
				continue
			names.append(skill._name)
	names.sort()
	return names

func _get_quick_slot_item(equipment: Equipment, slot_index: int) -> Item:
	if equipment == null:
		return null
	match slot_index:
		0:
			return equipment.quickItem1
		1:
			return equipment.quickItem2
		2:
			return equipment.quickItem3
		3:
			return equipment.quickItem4
		_:
			return null

func _open_quick_item_picker(action_payload: Dictionary, _controlled_payload: Dictionary) -> void:
	pending_quick_item_action = action_payload.duplicate(true)
	quickItemSlotSelector.clear()
	quickItemPickerLabel.text = "Choose a quick slot."
	var humanoid_data := _get_controlled_actor_from_payload(_get_controlled_combatant_payload()) as HumanoidData
	if humanoid_data == null or humanoid_data.equipment == null:
		playerActionsHint.text = "You have no quick items equipped."
		pending_quick_item_action = {}
		return
	var has_any_item := false
	for slot_index in range(4):
		var slot_item := _get_quick_slot_item(humanoid_data.equipment, slot_index)
		var slot_label := "%s - %s" % [slot_index + 1, slot_item._name if slot_item != null and not slot_item._name.is_empty() else "Empty"]
		quickItemSlotSelector.add_item(slot_label)
		quickItemSlotSelector.set_item_metadata(slot_index, slot_index)
		var item_available := slot_item != null and not slot_item._name.is_empty()
		quickItemSlotSelector.set_item_disabled(slot_index, not item_available)
		if item_available and not has_any_item:
			has_any_item = true
			quickItemSlotSelector.select(slot_index)
	if not has_any_item:
		playerActionsHint.text = "All quick item slots are empty."
		pending_quick_item_action = {}
		return
	quickItemPicker.popup_centered()

func _open_skill_test_picker(action_payload: Dictionary) -> void:
	pending_skill_test_action = action_payload.duplicate(true)
	skillTestPickerLabel.text = "Set the skill test details."
	skillTestSkillSelector.clear()
	var skill_names := _get_actor_skill_names(_get_controlled_actor_from_payload(_get_controlled_combatant_payload()))
	for skill_name in skill_names:
		skillTestSkillSelector.add_item(skill_name)
	if skill_names.is_empty():
		playerActionsHint.text = "You have no skills available for a skill test."
		pending_skill_test_action = {}
		return
	skillTestSkillSelector.select(0)
	skillTestAPInput.value = max(float(action_payload.get("ap_cost", 1)), 1.0)
	skillTestSpeedInput.value = max(float(action_payload.get("action_speed", 20)), 1.0)
	skillTestDescriptionInput.text = ""
	skillTestNoTargetToggle.button_pressed = true
	skillTestPicker.popup_centered()

func _confirm_quick_item_selection() -> void:
	if pending_quick_item_action.is_empty():
		return
	var controlled_payload := _get_controlled_combatant_payload()
	if controlled_payload.is_empty():
		pending_quick_item_action = {}
		return
	var selected_index := quickItemSlotSelector.get_selected()
	if selected_index < 0:
		playerActionsHint.text = "Choose a quick slot first."
		quickItemPicker.popup_centered()
		return
	var slot_index_variant = quickItemSlotSelector.get_item_metadata(selected_index)
	var slot_index := int(slot_index_variant)
	var humanoid_data := _get_controlled_actor_from_payload(controlled_payload) as HumanoidData
	var slot_item := _get_quick_slot_item(humanoid_data.equipment if humanoid_data != null else null, slot_index)
	if slot_item == null or slot_item._name.is_empty():
		playerActionsHint.text = "That quick slot is empty."
		quickItemPicker.popup_centered()
		return
	var action_payload := pending_quick_item_action.duplicate(true)
	action_payload["quick_slot_index"] = slot_index
	action_payload["quick_item_name"] = slot_item._name
	pending_quick_item_action = {}
	selected_combatant_id = str(controlled_payload.get("id", ""))
	_queue_player_action(action_payload, controlled_payload)

func _cancel_quick_item_selection() -> void:
	pending_quick_item_action = {}

func _confirm_skill_test_selection() -> void:
	if pending_skill_test_action.is_empty():
		return
	var controlled_payload := _get_controlled_combatant_payload()
	if controlled_payload.is_empty():
		pending_skill_test_action = {}
		return
	var selected_index := skillTestSkillSelector.get_selected()
	if selected_index < 0:
		playerActionsHint.text = "Choose a skill first."
		skillTestPicker.popup_centered()
		return
	var skill_name := skillTestSkillSelector.get_item_text(selected_index)
	if skill_name.strip_edges().is_empty():
		playerActionsHint.text = "Choose a skill first."
		skillTestPicker.popup_centered()
		return
	var action_payload := pending_skill_test_action.duplicate(true)
	action_payload["skill_name"] = skill_name
	action_payload["skill_test_description"] = skillTestDescriptionInput.text.strip_edges()
	action_payload["ap_cost"] = int(skillTestAPInput.value)
	action_payload["action_speed"] = int(skillTestSpeedInput.value)
	action_payload["no_target"] = skillTestNoTargetToggle.button_pressed
	action_payload["skill_difficulty"] = int(action_payload.get("skill_difficulty", 10))
	if int(action_payload.get("ap_cost", 1)) > int(controlled_payload.get("remaining_action_points", controlled_payload.get("action_points", 0))):
		playerActionsHint.text = "Not enough AP for Perform Skill Test."
		skillTestPicker.popup_centered()
		return
	pending_skill_test_action = {}
	if bool(action_payload.get("no_target", false)):
		selected_combatant_id = str(controlled_payload.get("id", ""))
		_queue_player_action(action_payload, controlled_payload)
		return
	pending_player_action = action_payload
	selected_combatant_id = ""
	selected_combatant_entry = null
	playerActionsHint.text = "Selected Perform Skill Test (%s AP). Choose any target or yourself." % action_payload.get("ap_cost", 1)
	_refresh_combatant_entry_interactions()
	_refresh_combat_grid()

func _cancel_skill_test_selection() -> void:
	pending_skill_test_action = {}

func _has_queued_action_named(payload: Dictionary, action_name: String) -> bool:
	for queued_payload_variant in payload.get("queued_action_payloads", []):
		if queued_payload_variant is Dictionary and str((queued_payload_variant as Dictionary).get("action_name", "")) == action_name:
			return true
	return false

func _is_guard_target_selectable(local_payload: Dictionary, target_payload: Dictionary) -> bool:
	if local_payload.is_empty() or target_payload.is_empty():
		return false
	var local_id := str(local_payload.get("id", ""))
	var target_id := str(target_payload.get("id", ""))
	if target_id.is_empty() or target_id == local_id:
		return false
	if float(target_payload.get("current_hp", 0.0)) <= 0.0:
		return false
	return not _are_hostile_combatants(local_payload, target_payload)

func _is_support_target_selectable(local_payload: Dictionary, target_payload: Dictionary) -> bool:
	if local_payload.is_empty() or target_payload.is_empty():
		return false
	if float(target_payload.get("current_vitality", 0.0)) <= 0.0:
		return false
	return not _are_hostile_combatants(local_payload, target_payload)

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

func _get_action_entries_for_actor(actor: CreatureData, loadout: int) -> Array[Dictionary]:
	if actor == null:
		return []
	if actor is HumanoidData:
		return (actor as HumanoidData).get_available_actions(loadout)
	var entries: Array[Dictionary] = []
	for actor_action in actor.actions:
		if actor_action is Action:
			entries.append({"action": actor_action, "weapon": null, "hand": "Innate"})
	return entries

func _get_action_names_for_actor(actor: CreatureData, loadout: int) -> Array[String]:
	var names: Array[String] = []
	for entry in _get_action_entries_for_actor(actor, loadout):
		var action: Action = entry.get("action", null)
		if action == null:
			continue
		names.append(action._name)
	return names

func _split_action_entries(action_entries: Array) -> Dictionary:
	var basic_actions: Array = []
	var attacks: Array = []
	for action_entry_variant in action_entries:
		if not (action_entry_variant is Dictionary):
			continue
		var action_entry := action_entry_variant as Dictionary
		if bool(action_entry.get("is_attack", false)):
			attacks.append(action_entry)
		else:
			basic_actions.append(action_entry)
	return {
		"actions": basic_actions,
		"attacks": attacks,
	}

func _get_serialized_action_entries_for_actor(actor: CreatureData, loadout: int) -> Array[Dictionary]:
	var action_entries: Array[Dictionary] = []
	for entry in _get_action_entries_for_actor(actor, loadout):
		var action: Action = entry.get("action", null)
		if action == null:
			continue
		var weapon: Weapon = entry.get("weapon", null)
		var source := "Innate"
		if weapon != null and not weapon._name.is_empty():
			source = weapon._name
		action_entries.append({
			"name": action._name,
			"source": source,
			"hand": str(entry.get("hand", "Innate")),
			"category": action.category,
			"is_attack": action.is_attack_action(),
			"ap_cost": RuleEngine.getActionAPCost(action, weapon),
			"mana_cost": (action as Attack).mana_cost if action is Attack else 0,
			"speed": RuleEngine.getActionSpeed(action, weapon),
		})
	return action_entries

func _rebuild_combatant_payload_for_actor(base_payload: Dictionary, actor: CreatureData, active_loadout: int) -> Dictionary:
	if actor == null:
		return {}
	var payload := base_payload.duplicate(true)
	payload["active_loadout"] = active_loadout
	actor.normalizeVitals()
	var action_points := actor.getActionPoints()
	payload["current_hp"] = actor.currentHP
	payload["max_hp"] = actor.maxHP
	payload["current_vitality"] = actor.currentVitality
	payload["max_vitality"] = actor.maxVitality
	payload["temporary_health"] = actor.temporaryHealth
	payload["current_concentration"] = actor.currentConcentration
	payload["max_concentration"] = actor.maxConcentration
	payload["current_mana"] = actor.currentMana
	payload["level"] = actor.level
	payload["action_points"] = action_points
	payload["round_action_points"] = int(base_payload.get("round_action_points", action_points))
	payload["details"] = "\n".join([
		"Attributes: %s" % _format_attribute_values(actor.attributes),
		"Actions: %s" % _format_name_list(_get_action_names_for_actor(actor, active_loadout)),
		"Concentration: %s/%s" % [actor.currentConcentration, actor.maxConcentration],
		"Mana: %s" % actor.currentMana,
		"Conditions: %s" % _format_name_list(actor.conditions),
	])
	payload["conditions"] = _serialize_condition_names(actor.conditions)
	payload["stunned_round"] = _get_stunned_round(actor)
	payload["stunned_resolve_speed"] = _get_stunned_resolve_speed(actor)
	payload["stunned_spent_ap"] = _get_stunned_spent_ap(actor)
	payload["bleed_turns_remaining"] = _get_bleed_turns_remaining(actor)
	payload["obsidian_patches_location"] = _get_obsidian_patches_location(actor)
	payload["obsidian_patches_location_name"] = _get_obsidian_patches_location_name(actor)
	payload["dexterity_score"] = _get_attribute_score(actor.attributes, "Dexterity")
	if actor is HumanoidData:
		payload["equipment"] = _serialize_equipment((actor as HumanoidData).equipment)
	payload["actions"] = _get_serialized_action_entries_for_actor(actor, active_loadout)
	payload["action_names"] = _get_action_names_for_actor(actor, active_loadout)
	payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", payload.get("round_action_points", action_points))), int(payload.get("round_action_points", action_points)))
	payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
	payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
	payload["movement_choice"] = base_payload.get("movement_choice", {}).duplicate(true)
	payload["movement_path"] = base_payload.get("movement_path", []).duplicate(true)
	payload["movement_ap_cost"] = int(base_payload.get("movement_ap_cost", 0))
	payload["team_id"] = clampi(int(base_payload.get("team_id", 1)), 1, 10)
	payload["grid_position"] = base_payload.get("grid_position", Vector2i(-1, -1))
	payload["planned_grid_position"] = base_payload.get("planned_grid_position", payload["grid_position"])
	return payload

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

func _serialize_condition_names(conditions: Array) -> Array[String]:
	var condition_names: Array[String] = []
	for condition_variant in conditions:
		if condition_variant is Condition:
			var condition := condition_variant as Condition
			if condition != null and not condition._name.is_empty():
				condition_names.append(condition._name)
	return condition_names

func _get_stunned_round(actor: CreatureData) -> int:
	if actor == null:
		return -1
	return int(actor.get_meta("stunned_round", -1))

func _get_stunned_resolve_speed(actor: CreatureData) -> int:
	if actor == null:
		return 0
	return int(actor.get_meta("stunned_resolve_speed", 0))

func _get_stunned_spent_ap(actor: CreatureData) -> int:
	if actor == null:
		return 0
	return int(actor.get_meta("stunned_spent_ap", 0))

func _get_bleed_turns_remaining(actor: CreatureData) -> int:
	if actor == null:
		return 0
	return RuleEngine.getBleedTurnsRemaining(actor)

func _get_obsidian_patches_location(actor: CreatureData) -> int:
	if actor == null:
		return -1
	return int(actor.get_meta("obsidian_patches_location", -1))

func _get_obsidian_patches_location_name(actor: CreatureData) -> String:
	var protected_location := _get_obsidian_patches_location(actor)
	if protected_location < 0:
		return ""
	return RuleEngine._location_to_string(protected_location as Item.ItemSlots)

func _assign_obsidian_patches_locations() -> void:
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants.get(combatant_id, {}).duplicate(true)
		if payload.is_empty():
			continue
		var actor := _get_actor_data_from_payload(payload)
		if actor == null:
			continue
		if _actor_has_perk(actor, "Obsidian Patches"):
			actor.set_meta("obsidian_patches_location", int(RuleEngine.roll_random_target_location()))
		else:
			actor.remove_meta("obsidian_patches_location")
		encounter_combatants[combatant_id] = _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))

func _clear_obsidian_patches_locations() -> void:
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants.get(combatant_id, {}).duplicate(true)
		if payload.is_empty():
			continue
		var actor := _get_actor_data_from_payload(payload)
		if actor != null:
			actor.remove_meta("obsidian_patches_location")
		encounter_combatants[combatant_id] = _rebuild_combatant_payload(payload, int(payload.get("active_loadout", 1)))

func _actor_has_perk(actor: CreatureData, perk_name: String) -> bool:
	if actor == null:
		return false
	for perk: Perk in actor.perks:
		if perk != null and perk._name == perk_name:
			return true
	if actor is HumanoidData:
		var humanoid := actor as HumanoidData
		for perk: Perk in [humanoid.race.perk, humanoid.homeland.perk, humanoid.background.perk]:
			if perk != null and perk._name == perk_name:
				return true
	return false

func _is_stunned_active(actor: CreatureData) -> bool:
	return actor != null and actor.hasCondition("Stunned") and _get_stunned_round(actor) == round_number

func _has_pending_stun(actor: CreatureData) -> bool:
	return actor != null and _get_stunned_round(actor) > 0 and actor.hasCondition("Stunned")

func _clear_stunned(actor: CreatureData) -> void:
	if actor == null:
		return
	RuleEngine.removeCondition(actor, "Stunned")
	actor.remove_meta("stunned_round")
	actor.remove_meta("stunned_resolve_speed")
	actor.remove_meta("stunned_spent_ap")

func _apply_stunned(actor: CreatureData, stunned_round: int, stunned_resolve_speed: int, stunned_spent_ap: int = 0) -> bool:
	if actor == null:
		return false
	if _has_pending_stun(actor):
		return false
	var added := RuleEngine.addCondition(actor, "Stunned")
	actor.set_meta("stunned_round", stunned_round)
	actor.set_meta("stunned_resolve_speed", stunned_resolve_speed)
	actor.set_meta("stunned_spent_ap", stunned_spent_ap)
	return added or actor.hasCondition("Stunned")

func _has_remaining_turn_actions(payload: Dictionary) -> bool:
	if not payload.get("queued_action_payloads", []).is_empty():
		return true
	return int(payload.get("remaining_action_points", payload.get("action_points", 0))) > 0

func _cancel_pending_actions_for_combatant(combatant_id: String) -> int:
	var removed_count := 0
	var remaining_requests: Array[CombatRequest] = []
	for request in pending_resolution_requests:
		if request.combatant_id == combatant_id:
			removed_count += 1
			continue
		remaining_requests.append(request)
	pending_resolution_requests = remaining_requests
	return removed_count

func _get_combatant_status_text(combatant_payload: Dictionary) -> String:
	var pending_request := str(combatant_payload.get("pending_request", ""))
	var queued_actions: Array = combatant_payload.get("queued_actions", [])
	var conditions: Array = combatant_payload.get("conditions", [])
	var current_hp: float = float(combatant_payload.get("current_hp", 0.0))
	var current_vitality: float = float(combatant_payload.get("current_vitality", 0.0))
	if not pending_request.is_empty():
		return "Pending"
	if current_vitality <= 0.0:
		return "Dead"
	if current_hp <= 0.0:
		return "Unconscious"
	if conditions.has("Stunned"):
		return "Stunned"
	if conditions.has("Prone"):
		return "Prone"
	if not queued_actions.is_empty():
		return "%s queued" % queued_actions.size()
	return "Ready"

func _format_condition_names(conditions: Array) -> String:
	var names: Array[String] = []
	for condition_variant in conditions:
		var condition_name := str(condition_variant)
		if condition_variant is Condition:
			condition_name = (condition_variant as Condition)._name
		if condition_name.is_empty():
			continue
		names.append(condition_name)
	if names.is_empty():
		return "None"
	return ", ".join(names)

func _format_condition_details(conditions: Array) -> String:
	var lines: Array[String] = []
	for condition_variant in conditions:
		var condition_name := str(condition_variant)
		if condition_variant is Condition:
			condition_name = (condition_variant as Condition)._name
		if condition_name.is_empty():
			continue
		match condition_name:
			"Stunned":
				lines.append("- Stunned: remaining actions are cancelled and next round loses time until the stored resolve speed.")
			"Prone":
				lines.append("- Prone: Deflection -5, Reflex -5, cannot move next movement phase, must spend 4 AP to stand up.")
			"Bleed":
				lines.append("- Bleed: takes 20% of missing HP as direct damage at end of turn for 3 turns. Reapplying triggers it immediately without refreshing duration.")
			_:
				lines.append("- %s" % condition_name)
	if lines.is_empty():
		return "None"
	return "\n".join(lines)

func _refresh_player_summary() -> void:
	if is_host_role:
		return
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		playerSummaryTitle.text = "Character Summary"
		playerSummaryHP.text = "HP / Vit: --"
		playerSummaryAP.text = "AP: --"
		playerSummaryConcentration.text = "Concentration: --"
		playerSummaryDefences.text = "Defences: --"
		playerSummaryMana.text = "Mana: --"
		playerSummaryConditions.text = "Conditions: None"
		return
	var runtime_payload := _build_local_player_runtime_payload(local_payload)
	playerSummaryTitle.text = str(runtime_payload.get("name", "Character Summary"))
	playerSummaryHP.text = "HP / Vit: %s/%s | %s/%s" % [
		_display_vital(runtime_payload.get("current_hp", 0.0)),
		_display_vital(runtime_payload.get("max_hp", 0.0)),
		_display_vital(runtime_payload.get("current_vitality", 0.0)),
		_display_vital(runtime_payload.get("max_vitality", 0.0)),
	]
	playerSummaryAP.text = "AP: %s/%s" % [runtime_payload.get("remaining_action_points", 0), runtime_payload.get("round_action_points", runtime_payload.get("action_points", 0))]
	playerSummaryConcentration.text = "Concentration: %s/%s" % [runtime_payload.get("current_concentration", 0), runtime_payload.get("max_concentration", 0)]
	playerSummaryDefences.text = "Defences: Defl %s | End %s | Reflex %s | Mind %s" % [
		RuleEngine.getDefenceValue(PlayerVariables.data, "Deflection"),
		RuleEngine.getDefenceValue(PlayerVariables.data, "Endurance"),
		RuleEngine.getDefenceValue(PlayerVariables.data, "Reflex"),
		RuleEngine.getDefenceValue(PlayerVariables.data, "Mind"),
	]
	playerSummaryMana.text = "Mana: %s" % runtime_payload.get("current_mana", 0)
	playerSummaryConditions.text = "Conditions: %s" % _format_condition_names(runtime_payload.get("conditions", []))

func _show_status_popup(combatant_payload: Dictionary) -> void:
	var condition_names := _format_condition_names(combatant_payload.get("conditions", []))
	var condition_details := _format_condition_details(combatant_payload.get("conditions", []))
	statusWindow.title = "%s Status" % str(combatant_payload.get("name", "Combatant"))
	statusWindowName.text = str(combatant_payload.get("name", "Combatant"))
	statusWindowState.text = "Status: %s" % _get_combatant_status_text(combatant_payload)
	statusWindowVitals.text = "HP / Vit: %s/%s | %s/%s" % [
		_display_vital(combatant_payload.get("current_hp", 0.0)),
		_display_vital(combatant_payload.get("max_hp", 0.0)),
		_display_vital(combatant_payload.get("current_vitality", 0.0)),
		_display_vital(combatant_payload.get("max_vitality", 0.0)),
	]
	statusWindowAP.text = "AP: %s/%s" % [combatant_payload.get("remaining_action_points", 0), combatant_payload.get("round_action_points", combatant_payload.get("action_points", 0))]
	statusWindowConcentration.text = "Concentration: %s/%s" % [combatant_payload.get("current_concentration", 0), combatant_payload.get("max_concentration", 0)]
	statusWindowConditions.text = "Conditions: %s" % condition_names
	if condition_details != "None":
		statusWindowConditions.text += "\n%s" % condition_details
	statusWindow.popup_centered()

func _on_player_action_pressed(action_data: Dictionary) -> void:
	if is_reviewing_action_phase:
		playerActionsHint.text = "Wait for the GM to finish resolving queued actions."
		return
	var controlled_payload := _get_controlled_combatant_payload()
	if controlled_payload.is_empty():
		playerActionsHint.text = "Select an NPC to control." if is_host_role else "You are not currently in this encounter."
		return
	var action_name := str(action_data.get("name", "Unknown Action"))

	var action_source := str(action_data.get("source", "Innate"))
	var action_hand := str(action_data.get("hand", "Innate"))
	var controlled_actor := _get_controlled_actor_from_payload(controlled_payload)
	var resolved_entry := _find_action_entry_for_actor(controlled_actor, int(controlled_payload.get("active_loadout", 1)), action_name, action_source, action_hand)
	if resolved_entry.is_empty():
		playerActionsHint.text = "Could not resolve that action."
		return
	var action: Action = resolved_entry.get("action", null)
	var weapon: Weapon = resolved_entry.get("weapon", null)
	if not RuleEngine.canAct(controlled_actor):
		playerActionsHint.text = "You cannot act while unconscious or dead."
		return
	var action_ap_cost := RuleEngine.getActionAPCost(action, weapon)
	var action_speed := int(action_data.get("speed", RuleEngine.getActionSpeed(action, weapon)))
	var instant_resolve := action_name == "Swap Loadout"
	if current_phase != GameEvent.PHASE_EXECUTION:
		playerActionsHint.text = "Actions can only be queued during the Action phase."
		return
	if action_ap_cost > int(controlled_payload.get("remaining_action_points", controlled_payload.get("action_points", 0))):
		playerActionsHint.text = "Not enough AP for %s." % action_name
		return
	if action_name in ["Bolster", "Guard", "Brace"] and _has_queued_action_named(controlled_payload, action_name):
		playerActionsHint.text = "You can only queue %s once per round." % action_name
		return
	var selected_action_payload := {
		"action_name": action_name,
		"action_source": action_source,
		"action_hand": action_hand,
		"targeting_mode": "single",
		"category": action_data.get("category", Action.CATEGORY_ATTACK),
		"target_location": int(Item.ItemSlots.Torso),
		"target_location_mode": TARGET_LOCATION_MODE_RANDOM,
		"target_location_label": "Random",
		"called_shot_penalty": 0,
		"accuracy_bonus": 0,
		"ap_cost": action_ap_cost,
		"action_speed": action_speed,
		"instant_resolve": instant_resolve,
	}
	if action_name == "Use Quick Item":
		_open_quick_item_picker(selected_action_payload, controlled_payload)
		return
	if action_name == "Perform Skill Test":
		_open_skill_test_picker(selected_action_payload)
		return
	if str(selected_action_payload.get("category", Action.CATEGORY_ATTACK)) == Action.CATEGORY_ATTACK:
		var target_location_payload: Dictionary = _get_selected_target_location_payload()
		selected_action_payload["target_location"] = int(target_location_payload.get("location", Item.ItemSlots.Torso))
		selected_action_payload["target_location_mode"] = str(target_location_payload.get("mode", TARGET_LOCATION_MODE_RANDOM))
		selected_action_payload["target_location_label"] = str(target_location_payload.get("name", "Random"))
		selected_action_payload["called_shot_penalty"] = int(target_location_payload.get("accuracy_bonus", 0))
		selected_action_payload["accuracy_bonus"] = int(target_location_payload.get("accuracy_bonus", 0))
	if instant_resolve:
		_queue_player_action(selected_action_payload, controlled_payload)
	elif _action_targets_ally(action_name):
		pending_player_action = selected_action_payload
		selected_combatant_id = ""
		selected_combatant_entry = null
		playerActionsHint.text = "Selected %s (%s AP). Choose an ally." % [action_name, action_ap_cost]
		_refresh_combatant_entry_interactions()
		_refresh_combat_grid()
	elif _action_targets_self_or_ally(action_name):
		pending_player_action = selected_action_payload
		selected_combatant_id = ""
		selected_combatant_entry = null
		playerActionsHint.text = "Selected %s (%s AP). Choose yourself or an ally." % [action_name, action_ap_cost]
		_refresh_combatant_entry_interactions()
		_refresh_combat_grid()
	elif str(selected_action_payload.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK:
		pending_player_action = selected_action_payload
		selected_combatant_id = str(controlled_payload.get("id", ""))
		_queue_pending_player_action(controlled_payload)
	else:
		pending_player_action = selected_action_payload
		selected_combatant_id = ""
		selected_combatant_entry = null
		playerActionsHint.text = "Selected %s (%s AP). %s Choose a target." % [action_name, action_ap_cost, _get_hit_location_selection_summary()]
		_refresh_combatant_entry_interactions()
		_refresh_combat_grid()

func _queue_pending_player_action(target_payload: Dictionary) -> void:
	if pending_player_action.is_empty():
		return
	var controlled_payload := _get_controlled_combatant_payload()
	if controlled_payload.is_empty():
		pending_player_action = {}
		_refresh_combatant_entry_interactions()
		return
	_queue_player_action(pending_player_action, target_payload)
	pending_player_action = {}
	selected_combatant_id = str(target_payload.get("id", ""))
	_refresh_combatant_entry_interactions()
	_refresh_combat_grid()

func _queue_player_action(action_payload: Dictionary, target_payload: Dictionary) -> void:
	var controlled_payload := _get_controlled_combatant_payload()
	if controlled_payload.is_empty():
		return
	var queued_action_name := str(action_payload.get("action_name", ""))
	if queued_action_name in ["Bolster", "Guard", "Brace"] and _has_queued_action_named(controlled_payload, queued_action_name):
		playerActionsHint.text = "You can only queue %s once per round." % queued_action_name
		return
	var target_combatant_id := str(target_payload.get("id", controlled_payload.get("id", "")))
	var range_preview: Dictionary = _get_attack_range_preview(controlled_payload, target_payload, action_payload)
	if str(action_payload.get("category", Action.CATEGORY_ATTACK)) == Action.CATEGORY_ATTACK and not bool(range_preview.get("legal", true)):
		playerActionsHint.text = "That target is out of range for %s." % str(action_payload.get("action_name", "this attack"))
		return
	var range_suffix: String = ""
	if not range_preview.is_empty():
		range_suffix = " [%s]" % str(range_preview.get("short", ""))
	var location_label: String = str(action_payload.get("target_location_label", "Random"))
	var preview_location_text: String = location_label
	if int(action_payload.get("called_shot_penalty", 0)) != 0:
		preview_location_text += ", %s" % int(action_payload.get("called_shot_penalty", 0))
	var preview_text := "%s -> %s (%s)%s" % [action_payload.get("action_name", "Action"), target_payload.get("name", "target"), preview_location_text, range_suffix]
	if str(action_payload.get("action_name", "")) == "Use Quick Item":
		preview_text = "%s -> Self (%s)" % [action_payload.get("action_name", "Action"), action_payload.get("quick_item_name", "Unknown Item")]
	elif str(action_payload.get("action_name", "")) == "Perform Skill Test":
		var description := str(action_payload.get("skill_test_description", "")).strip_edges()
		var skill_name := str(action_payload.get("skill_name", "Skill"))
		if bool(action_payload.get("no_target", false)):
			preview_text = "Perform Skill Test -> No Target (%s: %s)" % [skill_name, description if not description.is_empty() else "No description"]
		else:
			preview_text = "Perform Skill Test -> %s (%s: %s)" % [target_payload.get("name", "target"), skill_name, description if not description.is_empty() else "No description"]
	if bool(action_payload.get("instant_resolve", false)):
		preview_text = "%s -> Loadout %s" % [action_payload.get("action_name", "Action"), _get_next_loadout(int(controlled_payload.get("active_loadout", 1)))]
		playerActionsHint.text = "%s will resolve immediately (%s AP)." % [action_payload.get("action_name", "Action"), action_payload.get("ap_cost", 0)]
	else:
		var range_summary: String = ""
		if not range_preview.is_empty():
			range_summary = " %s" % str(range_preview.get("summary", ""))
		if str(action_payload.get("action_name", "")) == "Use Quick Item":
			playerActionsHint.text = "Queued %s on self using %s (%s AP)." % [action_payload.get("action_name", "Action"), action_payload.get("quick_item_name", "Unknown Item"), action_payload.get("ap_cost", 0)]
		elif str(action_payload.get("action_name", "")) == "Perform Skill Test":
			if bool(action_payload.get("no_target", false)):
				playerActionsHint.text = "Queued Perform Skill Test (%s, %s AP, speed %s)." % [action_payload.get("skill_name", "Skill"), action_payload.get("ap_cost", 0), action_payload.get("action_speed", 0)]
			else:
				playerActionsHint.text = "Queued Perform Skill Test against %s (%s, %s AP, speed %s)." % [target_payload.get("name", "target"), action_payload.get("skill_name", "Skill"), action_payload.get("ap_cost", 0), action_payload.get("action_speed", 0)]
		else:
			playerActionsHint.text = "Queued %s against %s at %s (%s AP).%s" % [action_payload.get("action_name", "Action"), target_payload.get("name", "target"), location_label, action_payload.get("ap_cost", 0), range_summary]
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	var payload := action_payload.duplicate(true)
	if not range_preview.is_empty():
		payload["grid_distance"] = int(range_preview.get("distance", 0))
		payload["range_state"] = str(range_preview.get("range_state", "standard"))
		payload["range_accuracy_modifier"] = int(range_preview.get("accuracy_modifier", 0))
		payload["range_summary"] = str(range_preview.get("summary", ""))
		payload["range_short"] = str(range_preview.get("short", ""))
	payload["preview_text"] = preview_text
	campaign_manager.broadcast_combat_request(CombatRequest.new(
		CombatRequest.TYPE_ACTION,
		str(controlled_payload.get("id", "")),
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
			queued_action_payloads = _recalculate_queued_action_resolve_speeds(payload, queued_action_payloads)
			payload["queued_actions"] = queued_actions
			payload["queued_action_payloads"] = queued_action_payloads
			payload["remaining_action_points"] = remaining_action_points - action_ap_cost
	elif combat_request.request_type == CombatRequest.TYPE_MOVEMENT:
		var previous_move_cost := int(payload.get("movement_ap_cost", 0))
		var restored_ap := int(payload.get("remaining_action_points", payload.get("action_points", 0))) + previous_move_cost
		var movement_ap_cost := int(combat_request.payload.get("ap_cost", 0))
		var movement_choice := combat_request.payload.duplicate(true)
		movement_choice["queued_timestamp"] = combat_request.timestamp
		payload["movement_choice"] = movement_choice
		payload["movement_path"] = combat_request.payload.get("path", []).duplicate(true)
		payload["movement_ap_cost"] = movement_ap_cost
		payload["planned_grid_position"] = combat_request.payload.get("destination", payload.get("grid_position", Vector2i(-1, -1)))
		payload["remaining_action_points"] = max(restored_ap - movement_ap_cost, 0)
	encounter_combatants[combatant_id] = payload
	if combatant_entries.has(combatant_id):
		var existing_entry: CombatantEntry = combatant_entries[combatant_id]
		if is_instance_valid(existing_entry):
			existing_entry.setup(payload)

	if selected_combatant_id == combatant_id:
		_show_inspector(payload)

	_refresh_player_actions()
	_refresh_queued_actions()
	_refresh_combat_grid()
	SignalBus.emit_gameplay_event("combat_action_previewed", "combat", {
		"combatant_id": combat_request.combatant_id,
		"target_id": combat_request.target_id,
		"round": round_number,
		"phase": current_phase,
		"source": _build_combatant_signal_payload(payload, _get_actor_data_from_payload(payload)),
		"action": {
			"request_type": combat_request.request_type,
			"name": str(combat_request.payload.get("action_name", "")),
			"payload": combat_request.payload.duplicate(true),
		},
		"metadata": {
			"timestamp": combat_request.timestamp,
		},
	})

func _build_combatant_signal_payload(payload: Dictionary, actor: CreatureData = null) -> Dictionary:
	return {
		"id": str(payload.get("id", payload.get("combatant_id", ""))),
		"name": str(payload.get("name", "")),
		"type": str(payload.get("type", "")),
		"controller_peer_id": int(payload.get("controller_peer_id", 0)),
		"current_hp": float(payload.get("current_hp", actor.currentHP if actor != null else 0.0)),
		"current_vitality": float(payload.get("current_vitality", actor.currentVitality if actor != null else 0.0)),
		"actor": actor,
	}

func _recalculate_queued_action_resolve_speeds(combatant_payload: Dictionary, queued_action_payloads: Array) -> Array:
	var updated_payloads: Array = []
	var cumulative_speed := 0
	if int(combatant_payload.get("stunned_round", -1)) == round_number and int(combatant_payload.get("stunned_resolve_speed", 0)) > 0:
		cumulative_speed = int(combatant_payload.get("stunned_resolve_speed", 0))
	for queued_payload_variant in queued_action_payloads:
		if not (queued_payload_variant is Dictionary):
			continue
		var queued_payload := (queued_payload_variant as Dictionary).duplicate(true)
		cumulative_speed += int(queued_payload.get("action_speed", 0))
		queued_payload["resolve_speed"] = cumulative_speed
		updated_payloads.append(queued_payload)
	return updated_payloads

func _apply_combatant_state_change(change: Dictionary) -> void:
	var combatant_id := str(change.get("combatant_id", ""))
	if combatant_id.is_empty() or not encounter_combatants.has(combatant_id):
		return

	var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
	payload.erase("pending_request")
	for key in change.keys():
		if key == "combatant_id" or key == "resolved_movement_path":
			continue
		payload[key] = change[key]

	_sync_actor_runtime_from_payload(payload)

	_sync_local_player_from_combatant_payload(payload)

	update_combatant_locally(payload)

func _sync_actor_runtime_from_payload(payload: Dictionary) -> void:
	var actor := _get_actor_data_from_payload(payload)
	if actor == null:
		return
	if payload.has("current_hp"):
		actor.currentHP = float(payload.get("current_hp", actor.currentHP))
	if payload.has("max_hp"):
		actor.maxHP = float(payload.get("max_hp", actor.maxHP))
	if payload.has("current_vitality"):
		actor.currentVitality = float(payload.get("current_vitality", actor.currentVitality))
	if payload.has("max_vitality"):
		actor.maxVitality = float(payload.get("max_vitality", actor.maxVitality))
	if payload.has("temporary_health"):
		actor.temporaryHealth = float(payload.get("temporary_health", actor.temporaryHealth))
	if payload.has("current_concentration"):
		actor.currentConcentration = int(payload.get("current_concentration", actor.currentConcentration))
	if payload.has("max_concentration"):
		actor.maxConcentration = int(payload.get("max_concentration", actor.maxConcentration))
	if payload.has("current_mana"):
		actor.currentMana = int(payload.get("current_mana", actor.currentMana))
	if payload.has("conditions"):
		var runtime_conditions: Array[Condition] = []
		for condition_name_variant in payload.get("conditions", []):
			var condition_name := str(condition_name_variant)
			if condition_name.is_empty():
				continue
			var condition: Condition = CampaignVariables.codex.Conditions.get(condition_name, null) if CampaignVariables.codex != null else null
			if condition != null:
				runtime_conditions.append(condition.duplicate(true) as Condition)
			else:
				runtime_conditions.append(Condition.new(condition_name))
		actor.conditions = runtime_conditions
	if payload.has("stunned_round"):
		var stunned_round := int(payload.get("stunned_round", -1))
		if stunned_round > 0:
			actor.set_meta("stunned_round", stunned_round)
		else:
			actor.remove_meta("stunned_round")
	if payload.has("stunned_resolve_speed"):
		var stunned_resolve_speed := int(payload.get("stunned_resolve_speed", 0))
		if stunned_resolve_speed > 0:
			actor.set_meta("stunned_resolve_speed", stunned_resolve_speed)
		else:
			actor.remove_meta("stunned_resolve_speed")
	if payload.has("stunned_spent_ap"):
		var stunned_spent_ap := int(payload.get("stunned_spent_ap", 0))
		if stunned_spent_ap > 0:
			actor.set_meta("stunned_spent_ap", stunned_spent_ap)
		else:
			actor.remove_meta("stunned_spent_ap")
	if payload.has("bleed_turns_remaining"):
		RuleEngine.setBleedTurnsRemaining(actor, int(payload.get("bleed_turns_remaining", 0)))
	if payload.has("obsidian_patches_location"):
		var protected_location := int(payload.get("obsidian_patches_location", -1))
		if protected_location >= 0:
			actor.set_meta("obsidian_patches_location", protected_location)
		else:
			actor.remove_meta("obsidian_patches_location")
	if payload.has("active_loadout"):
		actor.set_meta("active_loadout", int(payload.get("active_loadout", 1)))

func _sync_local_player_from_combatant_payload(payload: Dictionary) -> void:
	var controller_peer_id := int(payload.get("controller_peer_id", 0))
	if controller_peer_id == 0 or controller_peer_id != multiplayer.get_unique_id():
		return
	if PlayerVariables.current() == null:
		return
	PlayerVariables.apply_combatant_payload(payload)

func reset_combat_session_locally() -> void:
	encounter_combatants.clear()
	combatant_entries.clear()
	if PlayerVariables.current() != null:
		PlayerVariables.current().remove_meta("obsidian_patches_location")
	next_combatant_id = 1
	round_number = 1
	current_phase = GameEvent.PHASE_PLANNING
	board_columns = 12
	board_rows = 12
	pending_gm_placement_id = ""
	is_reviewing_action_phase = false
	pending_resolution_requests.clear()
	current_review_request = null
	current_review_resolution = {}
	actionResolutionWindow.hide()
	_clear_combatants()
	_clear_inspector()
	_clear_player_actions()
	_update_round_ui()
	selected_combatant_entry = null
	selected_combatant_id = ""
	controlled_host_combatant_id = ""
	if npc_picker != null:
		npc_picker.hide()
	_refresh_queued_actions()
	gridWidthInput.set_value_no_signal(board_columns)
	gridHeightInput.set_value_no_signal(board_rows)
	_refresh_board_controls()
	combatGrid.clear_preview_path()
	_refresh_combat_grid()

func apply_combat_snapshot(snapshot: Dictionary) -> void:
	reset_combat_session_locally()
	board_columns = clampi(int(snapshot.get("board_columns", 12)), 4, 128)
	board_rows = clampi(int(snapshot.get("board_rows", 12)), 4, 128)
	round_number = max(int(snapshot.get("round_number", 1)), 1)
	current_phase = str(snapshot.get("current_phase", GameEvent.PHASE_PLANNING))
	gridWidthInput.set_value_no_signal(board_columns)
	gridHeightInput.set_value_no_signal(board_rows)
	var combatants_variant: Variant = snapshot.get("combatants", [])
	if combatants_variant is Array:
		for combatant_payload_variant in combatants_variant:
			if combatant_payload_variant is Dictionary:
				spawn_combatant_locally(combatant_payload_variant)
	_refresh_board_controls()
	_update_round_ui()
	_refresh_player_actions()
	_refresh_queued_actions()
	_refresh_combat_grid()

func _refresh_combat_grid() -> void:
	_refresh_host_npc_movement_previews()
	combatGrid.setup(board_columns, board_rows, encounter_combatants)
	combatGrid.set_selected_combatant(selected_combatant_id)
	combatGrid.set_placement_source(pending_gm_placement_id)
	if not pending_player_action.is_empty() or current_phase != GameEvent.PHASE_PLANNING:
		combatGrid.clear_preview_path()

func _refresh_host_npc_movement_previews() -> void:
	if not is_host_role or not encounter_started or current_phase != GameEvent.PHASE_PLANNING:
		_clear_host_npc_movement_previews()
		return
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	for combatant_id_variant in combatant_ids:
		var combatant_id: String = str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		if str(payload.get("type", "")) != "NPC":
			continue
		if combatant_id == controlled_host_combatant_id:
			continue
		var movement_payload: Dictionary = _build_npc_movement_payload(combatant_id)
		if movement_payload.is_empty():
			payload["movement_choice"] = {}
			payload["movement_path"] = []
			payload["movement_ap_cost"] = 0
			payload["planned_grid_position"] = payload.get("grid_position", Vector2i(-1, -1))
			payload["pending_request"] = ""
			payload["remaining_action_points"] = _get_round_action_points(payload)
			encounter_combatants[combatant_id] = payload
			continue
		var preview_cost: int = int(movement_payload.get("ap_cost", 0))
		payload["movement_choice"] = movement_payload.duplicate(true)
		payload["movement_path"] = movement_payload.get("path", []).duplicate(true)
		payload["movement_ap_cost"] = preview_cost
		payload["planned_grid_position"] = movement_payload.get("destination", payload.get("grid_position", Vector2i(-1, -1)))
		payload["pending_request"] = movement_payload.get("preview_text", "")
		payload["remaining_action_points"] = max(_get_round_action_points(payload) - preview_cost, 0)
		encounter_combatants[combatant_id] = payload

func _clear_host_npc_movement_previews() -> void:
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id: String = str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id]
		if str(payload.get("type", "")) != "NPC":
			continue
		if not payload.get("movement_path", []).is_empty() or int(payload.get("movement_ap_cost", 0)) > 0:
			var updated_payload: Dictionary = payload.duplicate(true)
			updated_payload["movement_choice"] = {}
			updated_payload["movement_path"] = []
			updated_payload["movement_ap_cost"] = 0
			updated_payload["planned_grid_position"] = payload.get("grid_position", Vector2i(-1, -1))
			updated_payload["pending_request"] = ""
			updated_payload["remaining_action_points"] = _get_round_action_points(updated_payload)
			encounter_combatants[combatant_id] = updated_payload

func _on_grid_token_clicked(combatant_id: String, _cell: Vector2i) -> void:
	if combatant_id.is_empty() or not encounter_combatants.has(combatant_id):
		return
	var payload: Dictionary = encounter_combatants[combatant_id]
	_select_combatant_payload(payload)
	if current_phase == GameEvent.PHASE_EXECUTION and not pending_player_action.is_empty():
		var controlled_payload := _get_controlled_combatant_payload()
		var local_id := str(controlled_payload.get("id", ""))
		var pending_action_name := str(pending_player_action.get("action_name", ""))
		var can_target_self := str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK and not _action_targets_ally(pending_action_name)
		if not controlled_payload.is_empty() and (combatant_id != local_id or can_target_self):
			selected_combatant_id = combatant_id
			_queue_pending_player_action(payload)
			return
	if is_host_role and not encounter_started:
		pending_gm_placement_id = combatant_id
		_refresh_board_controls()
		_refresh_combat_grid()
		return
	if current_phase == GameEvent.PHASE_PLANNING and _can_issue_movement_for_combatant(combatant_id):
		if is_host_role and str(payload.get("type", "")) == "NPC":
			controlled_host_combatant_id = combatant_id
		var actor := _get_controlled_actor_from_payload(payload)
		if actor != null and actor.hasCondition("Prone") and combatant_id == _get_active_movement_combatant_id():
			_queue_stand_up_for_combatant(combatant_id)
			return
		pending_gm_placement_id = combatant_id
		_refresh_board_controls()
		_refresh_combat_grid()

func _on_grid_token_dragged(combatant_id: String, cell: Vector2i) -> void:
	if not _is_valid_grid_position(cell):
		return
	if is_host_role and not encounter_started:
		_move_combatant_pre_encounter(combatant_id, cell)

func _on_grid_cell_clicked(cell: Vector2i) -> void:
	if not _is_valid_grid_position(cell):
		return
	if is_host_role and not encounter_started and not pending_gm_placement_id.is_empty():
		_move_combatant_pre_encounter(pending_gm_placement_id, cell)
		return
	if current_phase != GameEvent.PHASE_PLANNING:
		return
	var moving_combatant_id: String = _get_active_movement_combatant_id()
	if moving_combatant_id.is_empty():
		return
	_queue_movement_for_combatant(moving_combatant_id, cell)

func _select_combatant_payload(combatant_payload: Dictionary) -> void:
	var combatant_id := str(combatant_payload.get("id", ""))
	selected_combatant_id = combatant_id
	if combatant_entries.has(combatant_id):
		var entry: CombatantEntry = combatant_entries[combatant_id]
		if is_instance_valid(entry):
			if selected_combatant_entry != null and is_instance_valid(selected_combatant_entry) and selected_combatant_entry != entry:
				selected_combatant_entry.set_selected(false)
			selected_combatant_entry = entry
			selected_combatant_entry.set_selected(true)
	_show_inspector(combatant_payload)
	_refresh_player_actions()
	_refresh_combatant_entry_interactions()
	_refresh_combat_grid()

func _move_combatant_pre_encounter(combatant_id: String, destination: Vector2i) -> void:
	if not encounter_combatants.has(combatant_id):
		return
	var occupied_id := combatGrid.get_combatant_id_at_cell(destination)
	if not occupied_id.is_empty() and occupied_id != combatant_id:
		return
	var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
	payload["grid_position"] = destination
	payload["planned_grid_position"] = destination
	payload["movement_choice"] = {}
	payload["movement_path"] = []
	payload["movement_ap_cost"] = 0
	payload["pending_request"] = ""
	encounter_combatants[combatant_id] = payload
	pending_gm_placement_id = ""
	_refresh_board_controls()
	_refresh_combat_grid()
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.broadcast_combatant_update(payload)

func _queue_movement_for_combatant(combatant_id: String, destination: Vector2i) -> void:
	if not encounter_combatants.has(combatant_id):
		return
	var local_payload: Dictionary = encounter_combatants[combatant_id]
	if not _can_issue_movement_for_combatant(combatant_id):
		playerActionsHint.text = "You cannot move that token."
		return
	var actor := _get_controlled_actor_from_payload(local_payload)
	if actor != null and actor.hasCondition("Prone"):
		playerActionsHint.text = "You are prone and cannot move. Click your token to stand up for 4 AP."
		combatGrid.clear_preview_path()
		return
	var start := _grid_position_from_payload(local_payload)
	if not _is_valid_grid_position(start):
		playerActionsHint.text = "Your token is not on the grid."
		return
	var blocked_cells := _get_occupied_grid_cells(combatant_id)
	var available_ap: int = _get_available_movement_ap(combatant_id)
	var path := combatGrid.get_reachable_path(start, destination, blocked_cells, available_ap)
	if path.is_empty():
		playerActionsHint.text = "No path to that square."
		combatGrid.clear_preview_path()
		return
	var current_positions: Dictionary = _build_current_position_lookup()
	var limited_path: Array[Vector2i] = _trim_path_to_available_ap(combatant_id, path, current_positions, available_ap)
	if limited_path.is_empty() or limited_path[limited_path.size() - 1] != destination:
		var required_ap: int = _get_path_movement_cost(combatant_id, path, current_positions)
		playerActionsHint.text = "That move costs %s AP." % required_ap
		combatGrid.clear_preview_path()
		return
	var ap_cost: int = _get_path_movement_cost(combatant_id, limited_path, current_positions)
	combatGrid.set_preview_path(limited_path, destination)
	playerActionsHint.text = "Planned move to (%s, %s) for %s AP." % [destination.x + 1, destination.y + 1, ap_cost]
	var preview_text := "Move -> (%s, %s) [%s AP]" % [destination.x + 1, destination.y + 1, ap_cost]
	var payload := {
		"destination": destination,
		"path": limited_path,
		"ap_cost": ap_cost,
		"preview_text": preview_text,
	}
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	campaign_manager.broadcast_combat_request(CombatRequest.new(
		CombatRequest.TYPE_MOVEMENT,
		combatant_id,
		combatant_id,
		payload
	))

func _get_active_movement_combatant_id() -> String:
	if not pending_gm_placement_id.is_empty() and _can_issue_movement_for_combatant(pending_gm_placement_id):
		return pending_gm_placement_id
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		playerActionsHint.text = "You are not currently in this encounter."
		return ""
	return str(local_payload.get("id", ""))

func _queue_stand_up_for_combatant(combatant_id: String) -> void:
	if not encounter_combatants.has(combatant_id):
		return
	var payload: Dictionary = encounter_combatants[combatant_id]
	if int(payload.get("remaining_action_points", 0)) < 4:
		playerActionsHint.text = "You need 4 AP to stand up."
		return
	var start := _grid_position_from_payload(payload)
	var preview_text := "Stand Up [4 AP]"
	var request_payload := {
		"destination": start,
		"path": [start],
		"ap_cost": 4,
		"preview_text": preview_text,
		"stand_up": true,
	}
	var campaign_manager := _find_campaign_manager()
	if campaign_manager == null:
		return
	campaign_manager.broadcast_combat_request(CombatRequest.new(
		CombatRequest.TYPE_MOVEMENT,
		combatant_id,
		combatant_id,
		request_payload
	))

func _can_issue_movement_for_combatant(combatant_id: String) -> bool:
	if combatant_id.is_empty() or not encounter_combatants.has(combatant_id):
		return false
	var payload: Dictionary = encounter_combatants[combatant_id]
	var controller_peer_id: int = int(payload.get("controller_peer_id", 0))
	var actor: CreatureData = null
	if controller_peer_id == multiplayer.get_unique_id() and PlayerVariables.data != null:
		actor = PlayerVariables.data
	else:
		actor = _get_actor_data_from_payload(payload)
	if actor == null or not RuleEngine.canAct(actor):
		return false
	if is_host_role and str(payload.get("type", "")) == "NPC":
		return true
	if controller_peer_id == 0:
		return false
	return controller_peer_id == multiplayer.get_unique_id()

func _populate_hit_location_selector() -> void:
	hitLocationSelector.clear()
	hitLocationSelector.add_item("Random")
	hitLocationSelector.add_item("Head")
	hitLocationSelector.add_item("Right Arm")
	hitLocationSelector.add_item("Left Arm")
	hitLocationSelector.add_item("Torso")
	hitLocationSelector.add_item("Right Leg")
	hitLocationSelector.add_item("Left Leg")
	hitLocationSelector.select(0)

func _build_resolution_edit_form() -> void:
	for child in resolutionEditForm.get_children():
		child.queue_free()
	review_edit_controls.clear()
	for field_name in REVIEW_BOOLEAN_FIELDS:
		var label := Label.new()
		label.text = field_name.replace("_", " ").capitalize()
		resolutionEditForm.add_child(label)
		var checkbox := CheckBox.new()
		checkbox.text = ""
		checkbox.toggled.connect(_on_review_edit_form_value_changed)
		resolutionEditForm.add_child(checkbox)
		review_edit_controls[field_name] = checkbox
	for field_name in REVIEW_NUMERIC_FIELDS:
		var label := Label.new()
		label.text = field_name.replace("_", " ").capitalize()
		resolutionEditForm.add_child(label)
		var spinbox := SpinBox.new()
		spinbox.min_value = -9999
		spinbox.max_value = 9999
		spinbox.step = 0.1
		spinbox.allow_greater = true
		spinbox.allow_lesser = true
		spinbox.value_changed.connect(_on_review_edit_form_value_changed)
		resolutionEditForm.add_child(spinbox)
		review_edit_controls[field_name] = spinbox

func _set_review_edit_form_values(resolved_result: Dictionary) -> void:
	for field_name in REVIEW_BOOLEAN_FIELDS:
		var checkbox := review_edit_controls.get(field_name, null) as CheckBox
		if checkbox != null:
			checkbox.set_pressed_no_signal(bool(resolved_result.get(field_name, false)))
	for field_name in REVIEW_NUMERIC_FIELDS:
		var spinbox := review_edit_controls.get(field_name, null) as SpinBox
		if spinbox != null:
			spinbox.set_value_no_signal(float(resolved_result.get(field_name, 0.0)))
	_update_review_edit_form_disabled_state()

func _read_review_edit_form_values() -> Dictionary:
	var values: Dictionary = {}
	for field_name in REVIEW_BOOLEAN_FIELDS:
		var checkbox := review_edit_controls.get(field_name, null) as CheckBox
		if checkbox != null:
			values[field_name] = checkbox.button_pressed
	for field_name in REVIEW_NUMERIC_FIELDS:
		var spinbox := review_edit_controls.get(field_name, null) as SpinBox
		if spinbox != null:
			values[field_name] = spinbox.value
	return values

func _update_review_edit_form_disabled_state() -> void:
	var hit_checkbox := review_edit_controls.get("hit", null) as CheckBox
	var did_hit := hit_checkbox == null or hit_checkbox.button_pressed
	for field_name in REVIEW_DAMAGE_FIELDS:
		var control = review_edit_controls.get(field_name, null)
		if control is SpinBox:
			(control as SpinBox).editable = did_hit
			(control as SpinBox).modulate = Color.WHITE if did_hit else Color(0.7, 0.7, 0.7, 1.0)

func _on_review_edit_form_value_changed(_value: Variant = null) -> void:
	_update_review_edit_form_disabled_state()

func _commit_current_review_form_to_resolution() -> void:
	if current_review_request == null or current_review_resolution.is_empty() or not is_editing_review_action:
		return
	if _current_review_is_skill_test_no_target():
		var updated_request := current_review_request.to_dict()
		var updated_payload: Dictionary = updated_request.get("payload", {}).duplicate(true)
		updated_payload["skill_difficulty"] = int(resolutionSkillDifficultyInput.value)
		updated_request["payload"] = updated_payload
		current_review_request = CombatRequest.from_dict(updated_request)
		current_review_resolution = _resolve_queued_action_preview(current_review_request)
		return
	var edited_result = current_review_resolution.get("resolved_result", {}).duplicate(true)
	var form_values := _read_review_edit_form_values()
	for key in form_values.keys():
		edited_result[key] = form_values[key]
	current_review_resolution = _rebuild_review_resolution_from_resolved_result(edited_result)

func _on_hit_location_selected(_index: int) -> void:
	if pending_player_action.is_empty():
		return
	if str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK:
		return
	var selection_text: String = _get_hit_location_selection_summary()
	playerActionsHint.text = "Selected %s (%s AP). %s Choose a target." % [pending_player_action.get("action_name", "Action"), pending_player_action.get("ap_cost", 0), selection_text]

func _get_selected_target_location_payload() -> Dictionary:
	match hitLocationSelector.selected:
		1:
			return {"mode": TARGET_LOCATION_MODE_CALLED, "location": int(Item.ItemSlots.Head), "name": "Head", "accuracy_bonus": CALLED_SHOT_ACCURACY_PENALTY}
		2:
			return {"mode": TARGET_LOCATION_MODE_CALLED, "location": int(Item.ItemSlots.RightArm), "name": "Right Arm", "accuracy_bonus": CALLED_SHOT_ACCURACY_PENALTY}
		3:
			return {"mode": TARGET_LOCATION_MODE_CALLED, "location": int(Item.ItemSlots.LeftArm), "name": "Left Arm", "accuracy_bonus": CALLED_SHOT_ACCURACY_PENALTY}
		4:
			return {"mode": TARGET_LOCATION_MODE_CALLED, "location": int(Item.ItemSlots.Torso), "name": "Torso", "accuracy_bonus": CALLED_SHOT_ACCURACY_PENALTY}
		5:
			return {"mode": TARGET_LOCATION_MODE_CALLED, "location": int(Item.ItemSlots.RightLeg), "name": "Right Leg", "accuracy_bonus": CALLED_SHOT_ACCURACY_PENALTY}
		6:
			return {"mode": TARGET_LOCATION_MODE_CALLED, "location": int(Item.ItemSlots.LeftLeg), "name": "Left Leg", "accuracy_bonus": CALLED_SHOT_ACCURACY_PENALTY}
		_:
			return {"mode": TARGET_LOCATION_MODE_RANDOM, "location": int(Item.ItemSlots.Torso), "name": "Random", "accuracy_bonus": 0}

func _get_hit_location_selection_summary() -> String:
	var selection: Dictionary = _get_selected_target_location_payload()
	if str(selection.get("mode", TARGET_LOCATION_MODE_RANDOM)) == TARGET_LOCATION_MODE_RANDOM:
		return "Random hit location."
	return "Called shot: %s (%s accuracy)." % [selection.get("name", "Torso"), selection.get("accuracy_bonus", 0)]

func _grid_position_from_payload(payload: Dictionary) -> Vector2i:
	var value = payload.get("grid_position", Vector2i(-1, -1))
	if value is Vector2i:
		return value
	if value is Vector2:
		var vector := value as Vector2
		return Vector2i(int(vector.x), int(vector.y))
	if value is Dictionary:
		return Vector2i(int(value.get("x", -1)), int(value.get("y", -1)))
	return Vector2i(-1, -1)

func _is_valid_grid_position(_position: Vector2i) -> bool:
	return _position.x >= 0 and _position.y >= 0 and _position.x < board_columns and _position.y < board_rows

func _all_combatants_have_grid_positions() -> bool:
	var occupied: Dictionary = {}
	for combatant_id_variant in encounter_combatants.keys():
		var payload: Dictionary = encounter_combatants[str(combatant_id_variant)]
		var grid_position: Vector2i = _grid_position_from_payload(payload)
		if not _is_valid_grid_position(grid_position) or occupied.has(grid_position):
			return false
		occupied[grid_position] = true
	return true

func _find_first_open_grid_position(excluded_ids: Array[String] = [], occupied_positions: Dictionary = {}) -> Vector2i:
	for row in range(board_rows):
		for column in range(board_columns):
			var candidate := Vector2i(column, row)
			if occupied_positions.has(candidate):
				continue
			if not occupied_positions.is_empty():
				return candidate
			var occupied := false
			for combatant_id_variant in encounter_combatants.keys():
				var combatant_id := str(combatant_id_variant)
				if combatant_id in excluded_ids:
					continue
				var payload: Dictionary = encounter_combatants[combatant_id]
				if _grid_position_from_payload(payload) == candidate:
					occupied = true
					break
			if not occupied:
				return candidate
	return Vector2i(-1, -1)

func _get_occupied_grid_cells(excluded_combatant_id: String = "") -> Array[Vector2i]:
	var occupied: Array[Vector2i] = []
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		if combatant_id == excluded_combatant_id:
			continue
		var payload: Dictionary = encounter_combatants[combatant_id]
		var _position := _grid_position_from_payload(payload)
		if _is_valid_grid_position(_position):
			occupied.append(_position)
	return occupied

func _clear_invalid_grid_positions() -> void:
	var assigned_positions: Dictionary = {}
	for combatant_id_variant in encounter_combatants.keys():
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		var current_position := _grid_position_from_payload(payload)
		if _is_valid_grid_position(current_position) and not assigned_positions.has(current_position):
			assigned_positions[current_position] = combatant_id
			continue
		var new_position := _find_first_open_grid_position(assigned_positions.values(), assigned_positions)
		payload["grid_position"] = new_position
		payload["planned_grid_position"] = new_position
		encounter_combatants[combatant_id] = payload
		assigned_positions[new_position] = combatant_id

func _reset_combatant_grid_positions() -> void:
	if not is_host_role or encounter_started:
		return
	var combatant_ids: Array = encounter_combatants.keys()
	combatant_ids.sort()
	var campaign_manager := _find_campaign_manager()
	var assigned_ids: Array[String] = []
	var assigned_positions: Dictionary = {}
	for combatant_id_variant in combatant_ids:
		var combatant_id := str(combatant_id_variant)
		var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
		payload["grid_position"] = _find_first_open_grid_position(assigned_ids, assigned_positions)
		payload["planned_grid_position"] = payload["grid_position"]
		payload["movement_choice"] = {}
		payload["movement_path"] = []
		payload["movement_ap_cost"] = 0
		payload["pending_request"] = ""
		encounter_combatants[combatant_id] = payload
		assigned_ids.append(combatant_id)
		assigned_positions[payload["grid_position"]] = combatant_id
		if campaign_manager != null:
			campaign_manager.broadcast_combatant_update(payload)
	_refresh_board_controls()
	_refresh_combat_grid()

func _build_combatant_entry(combatant_payload: Dictionary) -> CombatantEntry:
	var entry := COMBATANT_ENTRY_SCENE.instantiate() as CombatantEntry
	entry.setup(combatant_payload)
	entry.selected.connect(_on_combatant_selected)
	entry.status_selected.connect(_on_combatant_status_selected)
	entry.target_selected.connect(_on_combatant_target_selected)
	entry.team_changed.connect(_on_combatant_team_changed)
	entry.set_team_selector_visible(is_host_role)
	entry.name = _build_combatant_node_name(combatant_payload)
	_configure_combatant_entry_interaction(entry, combatant_payload)
	return entry

func _build_player_payload(player_data: PlayerData, peer_id: int) -> Dictionary:
	player_data.normalizeVitals(true)
	var details := [
		"Peer ID: %s" % peer_id,
		"Attributes: %s" % _format_attribute_values(player_data.attributes),
		"Actions: %s" % _format_player_action_names(player_data),
		"Mana: %s" % player_data.currentMana,
		"Conditions: %s" % _format_name_list(player_data.conditions),
	]
	var action_points := player_data.getActionPoints()
	var grid_position := _find_first_open_grid_position()
	return {
		"id": _create_combatant_id("player_%s" % peer_id),
		"name": player_data._name,
		"type": "Player",
		"team_id": 1,
		"dexterity_score": _get_attribute_score(player_data.attributes, "Dexterity"),
		"controller_peer_id": peer_id,
		"active_loadout": 1,
		"action_points": action_points,
		"round_action_points": action_points,
		"remaining_action_points": action_points,
		"queued_actions": [],
		"queued_action_payloads": [],
		"movement_choice": {},
		"movement_path": [],
		"movement_ap_cost": 0,
		"grid_position": grid_position,
		"planned_grid_position": grid_position,
		"current_hp": player_data.currentHP,
		"max_hp": player_data.maxHP,
		"current_vitality": player_data.currentVitality,
		"max_vitality": player_data.maxVitality,
		"temporary_health": player_data.temporaryHealth,
		"current_mana": player_data.currentMana,
		"level": player_data.level,
		"details": "\n".join(details),
		"equipment": _serialize_equipment(player_data.equipment),
		"actions": _get_player_action_entries(player_data, 1),
		"action_names": _get_player_action_names(player_data, 1),
		"peer_id": peer_id,
	}

func _build_npc_payload(npc: NPC) -> Dictionary:
	npc.data.normalizeVitals(true)
	var details := [
		npc.short_description,
		"Attributes: %s" % _format_attribute_values(npc.data.attributes),
		"Actions: %s" % _format_name_list(npc.data.actions),
		"Mana: %s" % npc.data.currentMana,
		"Conditions: %s" % _format_name_list(npc.data.conditions),
	]
	var action_points := npc.data.getActionPoints()
	var grid_position := _find_first_open_grid_position()
	return {
		"id": _create_combatant_id("npc_%s" % npc._name.to_snake_case()),
		"name": npc._name,
		"type": "NPC",
		"team_id": 2,
		"dexterity_score": _get_attribute_score(npc.data.attributes, "Dexterity"),
		"controller_peer_id": 0,
		"active_loadout": 1,
		"action_points": action_points,
		"round_action_points": action_points,
		"remaining_action_points": action_points,
		"queued_actions": [],
		"queued_action_payloads": [],
		"movement_choice": {},
		"movement_path": [],
		"movement_ap_cost": 0,
		"grid_position": grid_position,
		"planned_grid_position": grid_position,
		"current_hp": npc.data.currentHP,
		"max_hp": npc.data.maxHP,
		"current_vitality": npc.data.currentVitality,
		"max_vitality": npc.data.maxVitality,
		"temporary_health": npc.data.temporaryHealth,
		"current_mana": npc.data.currentMana,
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
	_select_combatant_payload(combatant_payload)
	if is_host_role and str(combatant_payload.get("type", "")) == "NPC":
		controlled_host_combatant_id = str(combatant_payload.get("id", ""))
	elif is_host_role:
		controlled_host_combatant_id = ""
	selected_combatant_entry = entry
	if selected_combatant_entry != null and is_instance_valid(selected_combatant_entry):
		selected_combatant_entry.set_selected(true)

func _on_combatant_status_selected(_entry: CombatantEntry, combatant_payload: Dictionary) -> void:
	_show_status_popup(combatant_payload)

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
	entry.set_team_selector_visible(is_host_role)
	if is_host_role:
		var controlled_payload := _get_controlled_combatant_payload()
		if controlled_payload.is_empty() or str(controlled_payload.get("type", "")) != "NPC":
			entry.set_player_target_mode(false, false, selected_combatant_id == str(combatant_payload.get("id", "")))
			return
		var can_target_host := false
		var is_targeted_host := false
		if not pending_player_action.is_empty():
			var combatant_id := str(combatant_payload.get("id", ""))
			var controlled_id := str(controlled_payload.get("id", ""))
			var pending_action_name_host := str(pending_player_action.get("action_name", ""))
			var can_target_self_host := str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK and not _action_targets_ally(pending_action_name_host)
			if combatant_id != controlled_id or can_target_self_host:
				can_target_host = true
				if str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) == Action.CATEGORY_ATTACK:
					can_target_host = _is_attack_target_selectable(controlled_payload, combatant_payload, pending_player_action)
				elif _action_allows_any_target(pending_action_name_host):
					can_target_host = true
				elif _action_targets_ally(pending_action_name_host):
					can_target_host = _is_guard_target_selectable(controlled_payload, combatant_payload)
				elif _action_targets_self_or_ally(pending_action_name_host):
					can_target_host = _is_support_target_selectable(controlled_payload, combatant_payload)
				is_targeted_host = combatant_id == selected_combatant_id
		entry.set_player_target_mode(true, can_target_host, is_targeted_host)
		return
	var local_payload := _find_local_player_combatant(multiplayer.get_unique_id())
	if local_payload.is_empty():
		entry.set_player_target_mode(true, false, false)
		return
	var can_target := false
	var is_targeted := false
	if not pending_player_action.is_empty():
		var combatant_id := str(combatant_payload.get("id", ""))
		var local_id := str(local_payload.get("id", ""))
		var pending_action_name := str(pending_player_action.get("action_name", ""))
		var can_target_self := str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) != Action.CATEGORY_ATTACK and not _action_targets_ally(pending_action_name)
		if combatant_id != local_id or can_target_self:
			can_target = true
			if str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) == Action.CATEGORY_ATTACK:
				can_target = _is_attack_target_selectable(local_payload, combatant_payload, pending_player_action)
			elif _action_allows_any_target(pending_action_name):
				can_target = true
			elif _action_targets_ally(pending_action_name):
				can_target = _is_guard_target_selectable(local_payload, combatant_payload)
			elif _action_targets_self_or_ally(pending_action_name):
				can_target = _is_support_target_selectable(local_payload, combatant_payload)
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

func _on_combatant_team_changed(_entry: CombatantEntry, combatant_id: String, team_id: int) -> void:
	if not is_host_role or not encounter_combatants.has(combatant_id):
		return
	var payload: Dictionary = encounter_combatants[combatant_id].duplicate(true)
	payload["team_id"] = clampi(team_id, 1, 10)
	encounter_combatants[combatant_id] = payload
	var campaign_manager := _find_campaign_manager()
	if campaign_manager != null:
		campaign_manager.broadcast_combatant_update(payload)
	_refresh_queued_actions()
	_refresh_player_actions()
	_refresh_combat_grid()

func _show_inspector(combatant_payload: Dictionary) -> void:
	inspectorTitle.text = str(combatant_payload.get("name", "Combatant Inspector"))
	inspectorType.text = "Type: %s" % combatant_payload.get("type", "NA")
	var current_hp: float = float(combatant_payload.get("current_hp", 0.0))
	var max_hp: float = float(combatant_payload.get("max_hp", 0.0))
	var current_vitality: float = float(combatant_payload.get("current_vitality", 0.0))
	var max_vitality: float = float(combatant_payload.get("max_vitality", 0.0))
	var temporary_health: float = float(combatant_payload.get("temporary_health", 0.0))
	var current_concentration: int = int(combatant_payload.get("current_concentration", 0))
	var max_concentration: int = int(combatant_payload.get("max_concentration", 0))
	var current_mana: int = int(combatant_payload.get("current_mana", 0))
	inspectorHP.text = "HP: %s/%s | VIT: %s/%s | TEMP: %s" % [_display_vital(current_hp), _display_vital(max_hp), _display_vital(current_vitality), _display_vital(max_vitality), _display_vital(temporary_health)]
	inspectorHP.tooltip_text = "HP %.2f / %.2f | Vitality %.2f / %.2f | Temporary %.2f" % [current_hp, max_hp, current_vitality, max_vitality, temporary_health]
	inspectorLevel.text = "Level: %s" % combatant_payload.get("level", 0)
	inspectorLoadout.text = "Loadout: %s" % combatant_payload.get("active_loadout", 1)
	var details_text := str(combatant_payload.get("details", "No details available."))
	details_text += "\nTeam: %s" % clampi(int(combatant_payload.get("team_id", 1)), 1, 10)
	var queued_actions: Array = combatant_payload.get("queued_actions", [])
	if not queued_actions.is_empty():
		details_text += "\nQueued Actions: %s" % ", ".join(queued_actions)
	var pending_request := str(combatant_payload.get("pending_request", ""))
	if not pending_request.is_empty():
		details_text += "\nPending Request: %s" % pending_request
	var grid_position := _grid_position_from_payload(combatant_payload)
	if _is_valid_grid_position(grid_position):
		details_text += "\nGrid: (%s, %s)" % [grid_position.x + 1, grid_position.y + 1]
	details_text += "\nConcentration: %s/%s" % [current_concentration, max_concentration]
	details_text += "\nMana: %s" % current_mana
	var planned_position := _grid_position_from_payload({"grid_position": combatant_payload.get("planned_grid_position", Vector2i(-1, -1))})
	if _is_valid_grid_position(planned_position) and planned_position != grid_position:
		details_text += "\nPlanned Move: (%s, %s) [%s AP]" % [planned_position.x + 1, planned_position.y + 1, combatant_payload.get("movement_ap_cost", 0)]
	inspectorDetails.text = details_text
	_populate_action_list(inspectorActionsList, combatant_payload.get("actions", []), false)

func _clear_inspector() -> void:
	inspectorTitle.text = "Combatant Inspector"
	inspectorType.text = "Type:"
	inspectorHP.text = "HP:"
	inspectorHP.tooltip_text = ""
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
	hitLocationSelector.disabled = true
	hitLocationSelector.select(0)
	playerBasicActionsSection.visible = true
	playerAttacksSection.visible = true
	_populate_action_list(playerBasicActionsList, [], true)
	_populate_action_list(playerAttacksList, [], true)
	_refresh_player_summary()
	_refresh_combatant_entry_interactions()

func _refresh_player_actions() -> void:
	var controlled_payload := _get_controlled_combatant_payload()
	if controlled_payload.is_empty():
		_clear_player_actions()
		if is_host_role:
			playerCombatantName.text = "No NPC selected."
			playerActionsHint.text = "Select an NPC to control."
		return

	var runtime_payload := controlled_payload
	if str(controlled_payload.get("type", "")) == "Player":
		# Players rebuild their own actions from local PlayerVariables so weapon swaps
		# update immediately instead of waiting for the host snapshot to refresh.
		runtime_payload = _build_local_player_runtime_payload(controlled_payload)
	playerCombatantName.text = str(runtime_payload.get("name", "Unknown"))
	playerLoadout.text = "Loadout: %s" % runtime_payload.get("active_loadout", 1)
	playerSwapLoadout.disabled = str(runtime_payload.get("type", "")) != "Player"
	hitLocationSelector.disabled = false
	if not pending_player_action.is_empty():
		var pending_action_name := str(pending_player_action.get("action_name", "Action"))
		if pending_action_name == "Perform Skill Test":
			playerActionsHint.text = "Selected Perform Skill Test (%s AP). Choose any target or yourself." % pending_player_action.get("ap_cost", 0)
		else:
			var selection_text: String = _get_hit_location_selection_summary() if str(pending_player_action.get("category", Action.CATEGORY_ATTACK)) == Action.CATEGORY_ATTACK else ""
			playerActionsHint.text = "Selected %s (%s AP). %s Choose a target." % [pending_action_name, pending_player_action.get("ap_cost", 0), selection_text]
	elif current_phase == GameEvent.PHASE_PLANNING:
		var move_cost := int(runtime_payload.get("movement_ap_cost", 0))
		if move_cost > 0:
			var destination := _grid_position_from_payload({"grid_position": runtime_payload.get("planned_grid_position", Vector2i(-1, -1))})
			playerActionsHint.text = "Planned move to (%s, %s) for %s AP." % [destination.x + 1, destination.y + 1, move_cost]
		else:
			if is_host_role and str(runtime_payload.get("type", "")) == "NPC":
				playerActionsHint.text = "Click a destination on the grid to move the selected NPC."
			else:
				playerActionsHint.text = "Click a destination on the grid to move."
	elif current_phase == GameEvent.PHASE_EXECUTION:
		if is_host_role and str(runtime_payload.get("type", "")) == "NPC":
			playerActionsHint.text = "Queue actions for the selected NPC."
		else:
			playerActionsHint.text = "Queue actions now."
	else:
		playerActionsHint.text = "Queue actions during the Action phase."
	var split_actions := _split_action_entries(runtime_payload.get("actions", []))
	var basic_actions: Array = split_actions.get("actions", [])
	var attacks: Array = split_actions.get("attacks", [])
	playerBasicActionsSection.visible = not basic_actions.is_empty()
	playerAttacksSection.visible = not attacks.is_empty()
	_populate_action_list(playerBasicActionsList, basic_actions, true)
	_populate_action_list(playerAttacksList, attacks, true)
	_refresh_player_summary()
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
	player_data.normalizeVitals()
	var active_loadout := int(payload.get("active_loadout", 1))
	var action_points := player_data.getActionPoints()
	payload["current_hp"] = player_data.currentHP
	payload["max_hp"] = player_data.maxHP
	payload["current_vitality"] = player_data.currentVitality
	payload["max_vitality"] = player_data.maxVitality
	payload["temporary_health"] = player_data.temporaryHealth
	payload["current_concentration"] = player_data.currentConcentration
	payload["max_concentration"] = player_data.maxConcentration
	payload["current_mana"] = player_data.currentMana
	payload["level"] = player_data.level
	payload["active_loadout"] = active_loadout
	payload["action_points"] = action_points
	payload["round_action_points"] = int(base_payload.get("round_action_points", action_points))
	payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", payload.get("round_action_points", action_points))), int(payload.get("round_action_points", action_points)))
	payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
	payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
	payload["movement_choice"] = base_payload.get("movement_choice", {}).duplicate(true)
	payload["movement_path"] = base_payload.get("movement_path", []).duplicate(true)
	payload["movement_ap_cost"] = int(base_payload.get("movement_ap_cost", 0))
	payload["team_id"] = clampi(int(base_payload.get("team_id", 1)), 1, 10)
	payload["grid_position"] = base_payload.get("grid_position", Vector2i(-1, -1))
	payload["planned_grid_position"] = base_payload.get("planned_grid_position", payload["grid_position"])
	payload["details"] = "\n".join([
		"Peer ID: %s" % multiplayer.get_unique_id(),
		"Attributes: %s" % _format_attribute_values(player_data.attributes),
		"Actions: %s" % _format_player_action_names(player_data, active_loadout),
		"Concentration: %s/%s" % [player_data.currentConcentration, player_data.maxConcentration],
		"Mana: %s" % player_data.currentMana,
		"Conditions: %s" % _format_name_list(player_data.conditions),
	])
	payload["conditions"] = _serialize_condition_names(player_data.conditions)
	payload["stunned_round"] = _get_stunned_round(player_data)
	payload["stunned_resolve_speed"] = _get_stunned_resolve_speed(player_data)
	payload["stunned_spent_ap"] = _get_stunned_spent_ap(player_data)
	payload["bleed_turns_remaining"] = _get_bleed_turns_remaining(player_data)
	payload["obsidian_patches_location"] = _get_obsidian_patches_location(player_data)
	payload["obsidian_patches_location_name"] = _get_obsidian_patches_location_name(player_data)
	payload["dexterity_score"] = _get_attribute_score(player_data.attributes, "Dexterity")
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
		player_data.normalizeVitals()
		var player_action_points := player_data.getActionPoints()
		payload["current_hp"] = player_data.currentHP
		payload["max_hp"] = player_data.maxHP
		payload["current_vitality"] = player_data.currentVitality
		payload["max_vitality"] = player_data.maxVitality
		payload["temporary_health"] = player_data.temporaryHealth
		payload["current_concentration"] = player_data.currentConcentration
		payload["max_concentration"] = player_data.maxConcentration
		payload["current_mana"] = player_data.currentMana
		payload["level"] = player_data.level
		payload["action_points"] = player_action_points
		payload["round_action_points"] = int(base_payload.get("round_action_points", player_action_points))
		payload["details"] = "\n".join([
			"Peer ID: %s" % peer_id,
			"Attributes: %s" % _format_attribute_values(player_data.attributes),
			"Actions: %s" % _format_player_action_names(player_data, active_loadout),
			"Concentration: %s/%s" % [player_data.currentConcentration, player_data.maxConcentration],
			"Mana: %s" % player_data.currentMana,
			"Conditions: %s" % _format_name_list(player_data.conditions),
		])
		payload["conditions"] = _serialize_condition_names(player_data.conditions)
		payload["stunned_round"] = _get_stunned_round(player_data)
		payload["stunned_resolve_speed"] = _get_stunned_resolve_speed(player_data)
		payload["stunned_spent_ap"] = _get_stunned_spent_ap(player_data)
		payload["bleed_turns_remaining"] = _get_bleed_turns_remaining(player_data)
		payload["obsidian_patches_location"] = _get_obsidian_patches_location(player_data)
		payload["obsidian_patches_location_name"] = _get_obsidian_patches_location_name(player_data)
		payload["dexterity_score"] = _get_attribute_score(player_data.attributes, "Dexterity")
		payload["equipment"] = _serialize_equipment(player_data.equipment)
		payload["actions"] = _get_player_action_entries(player_data, active_loadout)
		payload["action_names"] = _get_player_action_names(player_data, active_loadout)
		payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", payload.get("round_action_points", player_action_points))), int(payload.get("round_action_points", player_action_points)))
		payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
		payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
		payload["movement_choice"] = base_payload.get("movement_choice", {}).duplicate(true)
		payload["movement_path"] = base_payload.get("movement_path", []).duplicate(true)
		payload["movement_ap_cost"] = int(base_payload.get("movement_ap_cost", 0))
		payload["team_id"] = clampi(int(base_payload.get("team_id", 1)), 1, 10)
		payload["grid_position"] = base_payload.get("grid_position", Vector2i(-1, -1))
		payload["planned_grid_position"] = base_payload.get("planned_grid_position", payload["grid_position"])
		return payload
	var npc: NPC = CampaignVariables.codex.NPCs.get(str(payload.get("name", "")), null)
	if npc == null:
		return {}
	npc.data.normalizeVitals()
	var npc_action_points := npc.data.getActionPoints()
	payload["current_hp"] = npc.data.currentHP
	payload["max_hp"] = npc.data.maxHP
	payload["current_vitality"] = npc.data.currentVitality
	payload["max_vitality"] = npc.data.maxVitality
	payload["temporary_health"] = npc.data.temporaryHealth
	payload["current_concentration"] = npc.data.currentConcentration
	payload["max_concentration"] = npc.data.maxConcentration
	payload["current_mana"] = npc.data.currentMana
	payload["level"] = npc.data.level
	payload["action_points"] = npc_action_points
	payload["round_action_points"] = int(base_payload.get("round_action_points", npc_action_points))
	payload["details"] = "\n".join([
		npc.short_description,
		"Attributes: %s" % _format_attribute_values(npc.data.attributes),
		"Actions: %s" % _format_name_list(npc.data.actions),
		"Concentration: %s/%s" % [npc.data.currentConcentration, npc.data.maxConcentration],
		"Mana: %s" % npc.data.currentMana,
		"Conditions: %s" % _format_name_list(npc.data.conditions),
	])
	payload["conditions"] = _serialize_condition_names(npc.data.conditions)
	payload["stunned_round"] = _get_stunned_round(npc.data)
	payload["stunned_resolve_speed"] = _get_stunned_resolve_speed(npc.data)
	payload["stunned_spent_ap"] = _get_stunned_spent_ap(npc.data)
	payload["bleed_turns_remaining"] = _get_bleed_turns_remaining(npc.data)
	payload["obsidian_patches_location"] = _get_obsidian_patches_location(npc.data)
	payload["obsidian_patches_location_name"] = _get_obsidian_patches_location_name(npc.data)
	payload["dexterity_score"] = _get_attribute_score(npc.data.attributes, "Dexterity")
	payload["actions"] = _get_npc_action_entries(npc, active_loadout)
	payload["action_names"] = _get_npc_action_names(npc, active_loadout)
	payload["remaining_action_points"] = min(int(base_payload.get("remaining_action_points", payload.get("round_action_points", npc_action_points))), int(payload.get("round_action_points", npc_action_points)))
	payload["queued_actions"] = base_payload.get("queued_actions", []).duplicate(true)
	payload["queued_action_payloads"] = base_payload.get("queued_action_payloads", []).duplicate(true)
	payload["movement_choice"] = base_payload.get("movement_choice", {}).duplicate(true)
	payload["movement_path"] = base_payload.get("movement_path", []).duplicate(true)
	payload["movement_ap_cost"] = int(base_payload.get("movement_ap_cost", 0))
	payload["team_id"] = clampi(int(base_payload.get("team_id", 2)), 1, 10)
	payload["grid_position"] = base_payload.get("grid_position", Vector2i(-1, -1))
	payload["planned_grid_position"] = base_payload.get("planned_grid_position", payload["grid_position"])
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

func _display_vital(value: Variant) -> int:
	return ceili(float(value))

func _format_exact_float(value: Variant) -> String:
	return "%.2f" % float(value)

func _get_round_action_points(payload: Dictionary) -> int:
	return int(payload.get("round_action_points", payload.get("action_points", 0)))

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
		if int(payload.get("stunned_round", -1)) == round_number and int(payload.get("stunned_resolve_speed", 0)) > 0:
			var stunned_payload := {
				"action_name": "Stunned",
				"action_source": "Innate",
				"action_hand": "Innate",
				"category": Action.CATEGORY_BASIC,
				"target_id": combatant_id,
				"target_location": int(Item.ItemSlots.Torso),
				"target_location_label": "Self",
				"ap_cost": 0,
				"action_speed": int(payload.get("stunned_resolve_speed", 0)),
				"queued_timestamp": -1.0,
				"resolve_speed": int(payload.get("stunned_resolve_speed", 0)),
				"preview_text": "Stunned -> Self",
			}
			queued_entries.append({
				"combatant_id": combatant_id,
				"actor_name": str(payload.get("name", "Combatant")),
				"action_name": "Stunned",
				"target_name": str(payload.get("name", "Self")),
				"target_location_name": "Self",
				"speed": int(stunned_payload.get("action_speed", 0)),
				"resolve_speed": int(stunned_payload.get("resolve_speed", stunned_payload.get("action_speed", 0))),
				"timestamp": -1.0,
				"queued_payload": stunned_payload,
			})
		for queued_action_payload_variant in queued_action_payloads:
			if not (queued_action_payload_variant is Dictionary):
				continue
			var queued_payload := queued_action_payload_variant as Dictionary
			var action_speed := int(queued_payload.get("action_speed", 0))
			var target_name := "Target"
			var target_id := str(queued_payload.get("target_id", ""))
			if encounter_combatants.has(target_id):
				target_name = str(encounter_combatants[target_id].get("name", "Target"))
			queued_entries.append({
				"combatant_id": combatant_id,
				"actor_name": str(payload.get("name", "Combatant")),
				"action_name": str(queued_payload.get("action_name", "Action")),
				"target_name": target_name,
				"target_location_name": str(queued_payload.get("target_location_label", _location_name_from_slot(int(queued_payload.get("target_location", Item.ItemSlots.Torso))))),
				"speed": action_speed,
				"resolve_speed": int(queued_payload.get("resolve_speed", action_speed)),
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
		var action_tooltip_lines := [
			"Source: %s (%s)" % [action_source, action_hand],
			"Category: %s" % action_data.get("category", "Unknown"),
			"AP: %s" % action_data.get("ap_cost", 0),
			"Speed: %s" % action_data.get("speed", 0),
		]
		var mana_cost := int(action_data.get("mana_cost", 0))
		if mana_cost > 0:
			action_tooltip_lines.append("Mana: %s" % mana_cost)
		var action_tooltip := "\n".join(action_tooltip_lines)
		var node: Control
		if use_buttons:
			var button := Button.new()
			button.text = "%s   %s AP / SPD %s" % [action_name, action_data.get("ap_cost", 0), action_data.get("speed", 0)]
			button.tooltip_text = action_tooltip
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
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

func _get_attribute_score(attributes: Array, attribute_name: String) -> int:
	for attribute_variant in attributes:
		if attribute_variant is Attribute:
			var attribute: Attribute = attribute_variant
			if attribute._name == attribute_name:
				return int(attribute.value)
	return 0

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
			"is_attack": action.is_attack_action(),
			"ap_cost": ap_cost,
			"mana_cost": (action as Attack).mana_cost if action is Attack else 0,
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
				"is_attack": action.is_attack_action(),
				"ap_cost": ap_cost,
				"mana_cost": (action as Attack).mana_cost if action is Attack else 0,
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
				"is_attack": action.is_attack_action(),
				"ap_cost": RuleEngine.getActionAPCost(action, null),
				"mana_cost": (action as Attack).mana_cost if action is Attack else 0,
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
