extends Item
class_name Weapon

enum WeaponSize { ONE_HANDED, TWO_HANDED }
enum WeaponRange { MELEE, CLOSE, MEDIUM, LONG }

@export var damage_profile: DamageProfile
@export var size: WeaponSize
@export var handedness: WeaponSize
@export var actions: Array[Action]
@export var qualities: Array

func _init(
	idDB: int = -1,
	_nameDB: String = "",
	short_descriptionDB: String = "",
	long_descriptionDB: String = "",
	weightDB: float = 0,
	valueDB: int = 0,
	damageDieDB: int = 0,
	speedDB: int = 0,
	handednessDB: String = "",
	action_rangeDB: ActionRange = ActionRange.new()
) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB, weightDB, valueDB)

	allowed_slots = [ItemSlots.WeaponSlot]
	damage_profile = DamageProfile.new(damageDieDB, speedDB, action_rangeDB)

	# Convert string → enum
	match handednessDB:
		"1H":
			size = WeaponSize.ONE_HANDED
			handedness = WeaponSize.ONE_HANDED
		"2H":
			size = WeaponSize.TWO_HANDED
			handedness = WeaponSize.TWO_HANDED
		_:
			size = WeaponSize.ONE_HANDED
			handedness = WeaponSize.ONE_HANDED  # safe default

	actions = []
	qualities = []

func _print() -> String:
	var handedness_str := ""
	match handedness:
		WeaponSize.ONE_HANDED:
			handedness_str = "1H"
		WeaponSize.TWO_HANDED:
			handedness_str = "2H"

	return (
		super() +
		"Damage: " + damage_profile.describe() + "\n" +
		"Handedness: " + handedness_str + "\n"
	)
