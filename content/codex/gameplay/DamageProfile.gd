extends Resource
class_name DamageProfile

enum DamageOrigin { PHYSICAL, MAGICAL, NECROTIC }

@export var base_damage: int
@export var damage_die: int
@export var crit_die: int
@export var origin: DamageOrigin
@export var damage_types: Array[String]
@export var ignore_dt: bool

func _init(_base_damage: int = 0, _damage_die: int = 0, _crit_die: int = 0, _origin: DamageOrigin = DamageOrigin.PHYSICAL, _damage_types: Array[String] = [], _ignore_dt: bool = false) -> void:
	base_damage = _base_damage
	damage_die = _damage_die
	crit_die = _crit_die
	origin = _origin
	damage_types = _damage_types.duplicate()
	ignore_dt = _ignore_dt

func describe() -> String:
	var parts: Array[String] = []
	if base_damage > 0:
		parts.append(str(base_damage))
	if damage_die > 0:
		parts.append("d" + str(damage_die))
	return ", ".join(parts)
