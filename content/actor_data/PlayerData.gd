extends HumanoidData
class_name PlayerData

@export var gender: String
@export var age: int
@export var peer_id: int
@export var backstory: String
@export var handouts: Array[Dictionary]

# Level Up
@export var levelAvailable: bool
@export var experience: int
@export var attribute_points: int
@export var skill_points: int
@export var perk_points: int

func _init() -> void:
	super()
	gender = ""
	age = 0
	peer_id = -1
	backstory = ""
	handouts = []

	levelAvailable = false
	experience = 0
	level = 1
	attribute_points = 0
	skill_points = 0
	perk_points = 0

func getHandouts() -> Array[Dictionary]:
	_ensure_handout_store()
	return handouts.duplicate(true)

func addOrUpdateHandout(title: String, text: String, shared_by: String, shared_at: String) -> Dictionary:
	_ensure_handout_store()
	var normalized_title := title.strip_edges()
	if normalized_title.is_empty():
		return {}

	for index in range(handouts.size()):
		var existing := handouts[index] as Dictionary
		if str(existing.get("title", "")) != normalized_title:
			continue
		existing["text"] = text
		existing["shared_by"] = shared_by
		existing["shared_at"] = shared_at
		existing["unread"] = true
		handouts[index] = existing
		return existing.duplicate(true)

	var handout := {
		"id": "%s_%s" % [normalized_title, str(Time.get_ticks_msec())],
		"title": normalized_title,
		"text": text,
		"shared_by": shared_by,
		"shared_at": shared_at,
		"unread": true,
	}
	handouts.append(handout)
	return handout.duplicate(true)

func deleteHandout(id: String) -> bool:
	_ensure_handout_store()
	for index in range(handouts.size()):
		var existing := handouts[index] as Dictionary
		if str(existing.get("id", "")) != id:
			continue
		handouts.remove_at(index)
		return true
	return false

func markHandoutRead(id: String) -> bool:
	_ensure_handout_store()
	for index in range(handouts.size()):
		var existing := handouts[index] as Dictionary
		if str(existing.get("id", "")) != id:
			continue
		if not bool(existing.get("unread", false)):
			return false
		existing["unread"] = false
		handouts[index] = existing
		return true
	return false

func addExperienceWithThreshold(value: int, exp_threshold: int) -> bool:
	experience += value
	if experience <= exp_threshold:
		return false
	experience -= exp_threshold
	levelUp()
	return true

func levelUp() -> void:
	levelAvailable = true
	level += 1
	attribute_points += 1
	skill_points += 2
	perk_points += 1
	normalizeVitals(true)

func _ensure_handout_store() -> void:
	if handouts == null:
		handouts = []
