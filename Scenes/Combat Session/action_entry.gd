extends Control
class_name ActionEntry

var data: Dictionary = {}

func setup(action_data: Dictionary) -> void:
	data = action_data.duplicate(true)
	if is_node_ready():
		_refresh()

func _ready() -> void:
	_refresh()

func _refresh() -> void:
	%Actor.text = str(data.get("actor_name", "Unknown"))
	var action_text := str(data.get("action_name", "Action"))
	if data.has("resolve_speed"):
		action_text += " @ " + str(data.get("resolve_speed", 0))
	%Action.text = action_text
	%Target.text = str(data.get("target_name", "Target"))
	%Location.text = str(data.get("target_location_name", "Torso"))
