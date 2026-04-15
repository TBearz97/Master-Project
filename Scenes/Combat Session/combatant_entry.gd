extends Control
class_name CombatantEntry

signal selected(entry: CombatantEntry, combatant_data: Dictionary)
signal target_selected(entry: CombatantEntry, combatant_data: Dictionary)
signal team_changed(entry: CombatantEntry, combatant_id: String, team_id: int)
signal status_selected(entry: CombatantEntry, combatant_data: Dictionary)

var data: Dictionary = {}
var is_player_target_mode := false
var show_team_selector := false

func _ready() -> void:
	%Inspect.pressed.connect(_inspect)
	%Status.pressed.connect(_on_status_pressed)
	%Target.toggled.connect(_on_target_toggled)
	%TeamSelector.item_selected.connect(_on_team_selected)
	_populate_team_selector()
	_refresh()

func setup(combatant_data: Dictionary) -> void:
	data = combatant_data.duplicate(true)
	if is_node_ready():
		_refresh()

func set_selected(is_selected: bool) -> void:
	%Panel.modulate = Color(1.0, 0.92, 0.72) if is_selected else Color(1, 1, 1)
	if %Target.button_pressed != is_selected:
		%Target.set_pressed_no_signal(is_selected)

func set_player_target_mode(enabled: bool, can_target: bool, is_targeted: bool) -> void:
	is_player_target_mode = enabled
	%Inspect.visible = not enabled
	%Target.visible = enabled
	%Target.disabled = not can_target
	%Target.set_pressed_no_signal(is_targeted)
	set_selected(is_targeted if enabled else is_targeted)

func set_team_selector_visible(visible_state: bool) -> void:
	show_team_selector = visible_state
	if is_node_ready():
		_refresh()

func _inspect() -> void:
	selected.emit(self, data)

func _on_target_toggled(pressed: bool) -> void:
	if not is_player_target_mode:
		return
	if pressed:
		target_selected.emit(self, data)

func _on_team_selected(index: int) -> void:
	var combatant_id: String = str(data.get("id", ""))
	if combatant_id.is_empty():
		return
	var selected_team_id: int = index + 1
	if int(data.get("team_id", 1)) == selected_team_id:
		return
	data["team_id"] = selected_team_id
	team_changed.emit(self, combatant_id, selected_team_id)

func _on_status_pressed() -> void:
	status_selected.emit(self, data)

func _refresh() -> void:
	var display_name := str(data.get("name", "Unknown"))
	if int(data.get("controller_peer_id", 0)) == multiplayer.get_unique_id() and int(data.get("controller_peer_id", 0)) != 0:
		display_name += " (You)"
	%Name.text = display_name

	var current_hp: float = float(data.get("current_hp", 0.0))
	var max_hp: float = maxf(float(data.get("max_hp", 0.0)), 1.0)
	var current_vitality: float = float(data.get("current_vitality", 0.0))
	var max_vitality: float = maxf(float(data.get("max_vitality", 0.0)), 1.0)
	var temporary_health: float = float(data.get("temporary_health", 0.0))
	var remaining_ap := int(data.get("remaining_action_points", 0))
	var action_points := int(data.get("action_points", 0))
	%HP.text = "HP %s/%s | Vit %s/%s" % [ceili(current_hp), ceili(max_hp), ceili(current_vitality), ceili(max_vitality)]
	if temporary_health > 0.0:
		%HP.text += "  T %s" % ceili(temporary_health)
	%HP.tooltip_text = "HP %.2f / %.2f | Vitality %.2f / %.2f | Temporary %.2f" % [current_hp, max_hp, current_vitality, max_vitality, temporary_health]
	%AP.text = "%s/%s" % [remaining_ap, action_points]

	var pending_request := str(data.get("pending_request", ""))
	var queued_actions: Array = data.get("queued_actions", [])
	var conditions: Array = data.get("conditions", [])
	if not pending_request.is_empty():
		%Status.text = "Pending"
	elif current_vitality <= 0.0:
		%Status.text = "Dead"
	elif current_hp <= 0.0:
		%Status.text = "Unconscious"
	elif conditions.has("Stunned"):
		%Status.text = "Stunned"
	elif not queued_actions.is_empty():
		%Status.text = "%s queued" % queued_actions.size()
	else:
		%Status.text = "Ready"

	%TeamLabel.visible = show_team_selector
	%TeamSelector.visible = show_team_selector
	%TeamSelector.disabled = not show_team_selector
	var team_id: int = clampi(int(data.get("team_id", 1)), 1, 10)
	if %TeamSelector.selected != team_id - 1:
		%TeamSelector.select(team_id - 1)

func _populate_team_selector() -> void:
	%TeamSelector.clear()
	for team_id in range(1, 11):
		%TeamSelector.add_item(str(team_id))
