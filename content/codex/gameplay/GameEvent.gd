extends Resource
class_name GameEvent

const CONTEXT_COMBAT := "combat"
const CONTEXT_INVENTORY := "inventory"
const CONTEXT_SKILL_CHECK := "skill_check"
const CONTEXT_STATE := "state"

const PHASE_NONE := ""
const PHASE_PLANNING := "planning"
const PHASE_EXECUTION := "execution"
const PHASE_RESOLUTION := "resolution"

@export var event_type: String
@export var context: String
@export var round_number: int
@export var phase: String
@export var timestamp: float
@export var source_id: String
@export var target_id: String
@export var payload: Dictionary
@export var state_changes: Array[Dictionary]
@export var results: Array[Dictionary]

func _init(type_name: String = "", event_context: String = CONTEXT_STATE, event_payload: Dictionary = {}, changes: Array[Dictionary] = [], event_results: Array[Dictionary] = [], encounter_round: int = 0, event_phase: String = PHASE_NONE, source_combatant_id: String = "", target_combatant_id: String = "", event_timestamp: float = -1.0) -> void:
	event_type = type_name
	context = event_context
	round_number = encounter_round
	phase = event_phase
	timestamp = event_timestamp if event_timestamp >= 0.0 else Time.get_unix_time_from_system()
	source_id = source_combatant_id
	target_id = target_combatant_id
	payload = event_payload.duplicate(true)
	state_changes = changes.duplicate(true)
	results = event_results.duplicate(true)

func to_dict() -> Dictionary:
	return {
		"event_type": event_type,
		"context": context,
		"round_number": round_number,
		"phase": phase,
		"timestamp": timestamp,
		"source_id": source_id,
		"target_id": target_id,
		"payload": payload.duplicate(true),
		"state_changes": state_changes.duplicate(true),
		"results": results.duplicate(true),
	}

static func from_dict(data: Dictionary) -> GameEvent:
	return GameEvent.new(
		str(data.get("event_type", "")),
		str(data.get("context", CONTEXT_STATE)),
		data.get("payload", {}),
		data.get("state_changes", []),
		data.get("results", []),
		int(data.get("round_number", 0)),
		str(data.get("phase", PHASE_NONE)),
		str(data.get("source_id", "")),
		str(data.get("target_id", "")),
		float(data.get("timestamp", -1.0))
	)
