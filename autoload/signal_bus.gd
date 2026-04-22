extends Node

@warning_ignore("unused_signal")
signal itemEquipped(newItem, oldItem, variant)

@warning_ignore("unused_signal")
signal gameplay_event_emitted(event_name, payload)

@warning_ignore("unused_signal")
signal combat_action_requested(payload)
@warning_ignore("unused_signal")
signal combat_action_previewed(payload)
@warning_ignore("unused_signal")
signal combat_action_resolving(payload)
@warning_ignore("unused_signal")
signal combat_action_resolved(payload)

@warning_ignore("unused_signal")
signal attack_roll_started(payload)
@warning_ignore("unused_signal")
signal attack_roll_finished(payload)
@warning_ignore("unused_signal")
signal attack_hit_confirmed(payload)
@warning_ignore("unused_signal")
signal attack_missed(payload)

@warning_ignore("unused_signal")
signal damage_will_apply(payload)
@warning_ignore("unused_signal")
signal damage_applied(payload)
@warning_ignore("unused_signal")
signal healing_applied(payload)

@warning_ignore("unused_signal")
signal condition_application_started(payload)
@warning_ignore("unused_signal")
signal condition_application_resolved(payload)
@warning_ignore("unused_signal")
signal condition_added(payload)
@warning_ignore("unused_signal")
signal condition_removed(payload)

@warning_ignore("unused_signal")
signal skill_check_requested(payload)
@warning_ignore("unused_signal")
signal skill_check_offer_created(payload)
@warning_ignore("unused_signal")
signal skill_check_roll_started(payload)
@warning_ignore("unused_signal")
signal skill_check_roll_finished(payload)
@warning_ignore("unused_signal")
signal skill_check_resolved(payload)

@warning_ignore("unused_signal")
signal encounter_started(payload)
@warning_ignore("unused_signal")
signal encounter_ended(payload)
@warning_ignore("unused_signal")
signal round_started(payload)
@warning_ignore("unused_signal")
signal round_ended(payload)
@warning_ignore("unused_signal")
signal phase_started(payload)
@warning_ignore("unused_signal")
signal phase_ended(payload)
@warning_ignore("unused_signal")
signal turn_state_changed(payload)

@warning_ignore("unused_signal")
signal character_loaded(payload)
@warning_ignore("unused_signal")
signal character_replaced(payload)
@warning_ignore("unused_signal")
signal race_changed(payload)
@warning_ignore("unused_signal")
signal homeland_changed(payload)
@warning_ignore("unused_signal")
signal background_changed(payload)
@warning_ignore("unused_signal")
signal perks_changed(payload)

func emit_gameplay_event(event_name: String, context_name: String, payload: Dictionary = {}) -> Dictionary:
	var event_payload: Dictionary = payload.duplicate(true)
	event_payload["event_name"] = event_name
	event_payload["context"] = context_name
	if not event_payload.has("metadata") or not (event_payload.get("metadata", {}) is Dictionary):
		event_payload["metadata"] = {}
	gameplay_event_emitted.emit(event_name, event_payload)
	if has_signal(event_name):
		emit_signal(event_name, event_payload)
	return event_payload
