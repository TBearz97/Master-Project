extends Control
class_name CombatantEntry

signal selected(entry: CombatantEntry, combatant_data: Dictionary)
signal target_selected(entry: CombatantEntry, combatant_data: Dictionary)

var data: Dictionary = {}
var is_player_target_mode := false

func _ready() -> void:
	%Inspect.pressed.connect(_inspect)
	%Target.toggled.connect(_on_target_toggled)
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

func _inspect() -> void:
	selected.emit(self, data)

func _on_target_toggled(pressed: bool) -> void:
	if not is_player_target_mode:
		return
	if pressed:
		target_selected.emit(self, data)

func _refresh() -> void:
	var display_name := str(data.get("name", "Unknown"))
	if int(data.get("controller_peer_id", 0)) == multiplayer.get_unique_id() and int(data.get("controller_peer_id", 0)) != 0:
		display_name += " (You)"
	%Name.text = display_name
	var type_text := str(data.get("type", "NA"))
	var loadout := int(data.get("active_loadout", 1))
	type_text += "  L%s" % loadout
	if int(data.get("level", 0)) > 0:
		type_text += "  Lv%s" % int(data.get("level", 0))
	%Type.text = type_text

	var current_hp := int(data.get("current_hp", 0))
	var max_hp := maxi(int(data.get("max_hp", 0)), 1)
	var current_vitality := int(data.get("current_vitality", 0))
	var max_vitality := maxi(int(data.get("max_vitality", 0)), 1)
	var temporary_health := int(data.get("temporary_health", 0))
	var remaining_ap := int(data.get("remaining_action_points", 0))
	var action_points := int(data.get("action_points", 0))
	%HP.text = "HP %s/%s  V %s/%s" % [current_hp, max_hp, current_vitality, max_vitality]
	if temporary_health > 0:
		%HP.text += "  T %s" % temporary_health
	%AP.text = "AP %s/%s" % [remaining_ap, action_points]

	var pending_request := str(data.get("pending_request", ""))
	var queued_actions: Array = data.get("queued_actions", [])
	if not pending_request.is_empty():
		%Status.text = "Pending"
	elif current_vitality <= 0:
		%Status.text = "Dead"
	elif current_hp <= 0:
		%Status.text = "Unconscious"
	elif not queued_actions.is_empty():
		%Status.text = "%s queued" % queued_actions.size()
	else:
		%Status.text = "Ready"
