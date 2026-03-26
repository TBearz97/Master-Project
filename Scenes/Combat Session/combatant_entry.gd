extends Control
class_name CombatantEntry

signal selected(entry: CombatantEntry, combatant_data: Dictionary)

var data: Dictionary = {}

func _ready() -> void:
	%Inspect.pressed.connect(_inspect)
	_refresh()

func setup(combatant_data: Dictionary) -> void:
	data = combatant_data.duplicate(true)
	if is_node_ready():
		_refresh()

func set_selected(is_selected: bool) -> void:
	%Panel.modulate = Color(1.0, 0.92, 0.72) if is_selected else Color(1, 1, 1)

func _inspect() -> void:
	selected.emit(self, data)

func _refresh() -> void:
	var display_name := str(data.get("name", "Unknown"))
	if int(data.get("controller_peer_id", 0)) == multiplayer.get_unique_id() and int(data.get("controller_peer_id", 0)) != 0:
		display_name += " (You)"
	%Name.text = display_name
	%Type.text = str(data.get("type", "NA"))
	%HP.text = "%s/%s" % [data.get("current_hp", 0), data.get("max_hp", 0)]
