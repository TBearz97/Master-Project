extends Resource
class_name CombatRequest

const TYPE_MOVEMENT := "movement_request"
const TYPE_ACTION := "action_request"
const TYPE_QUEUE_UPDATED := "queue_updated"

@export var request_type: String
@export var combatant_id: String
@export var target_id: String
@export var payload: Dictionary
@export var timestamp: float

func _init(type_name: String = "", source_combatant_id: String = "", target_combatant_id: String = "", request_payload: Dictionary = {}, request_timestamp: float = -1.0) -> void:
	request_type = type_name
	combatant_id = source_combatant_id
	target_id = target_combatant_id
	payload = request_payload.duplicate(true)
	timestamp = request_timestamp if request_timestamp >= 0.0 else Time.get_unix_time_from_system()

func to_dict() -> Dictionary:
	return {
		"request_type": request_type,
		"combatant_id": combatant_id,
		"target_id": target_id,
		"payload": payload.duplicate(true),
		"timestamp": timestamp,
	}

static func from_dict(data: Dictionary) -> CombatRequest:
	return CombatRequest.new(
		str(data.get("request_type", "")),
		str(data.get("combatant_id", "")),
		str(data.get("target_id", "")),
		data.get("payload", {}),
		float(data.get("timestamp", -1.0))
	)
