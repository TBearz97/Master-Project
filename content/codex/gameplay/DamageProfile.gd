extends Resource
class_name DamageProfile

@export var damage_die: int
@export var speed: int
@export var action_range: ActionRange

func _init(_damage_die: int = 0, _speed: int = 0, _action_range: ActionRange = ActionRange.new()) -> void:
	damage_die = _damage_die
	speed = _speed
	action_range = _action_range

func describe() -> String:
	var parts: Array[String] = []

	# Damage Die
	if damage_die > 0:
		parts.append("d" + str(damage_die))

	# Speed
	if speed > 0:
		parts.append(str(speed))

	# Range
	if action_range != null:
		if "short_hand" in action_range:
			parts.append(action_range.short_hand)
		elif "name" in action_range:
			parts.append(action_range.name)

	return " | ".join(parts)
