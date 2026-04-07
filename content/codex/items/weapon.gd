extends Item
class_name Weapon

enum WeaponSize { ONE_HANDED, TWO_HANDED }
enum WeaponRange { MELEE, CLOSE, MEDIUM, LONG }
enum WeaponSpeedCategory { VERY_FAST, FAST, NORMAL, SLOW }

@export var damage_profile: DamageProfile
@export var base_ap_cost: int
@export var speed_category: WeaponSpeedCategory
@export var qualities: Array[String]
@export var size: WeaponSize
@export var weaponRange: WeaponRange
@export var actions: Array[Action]

func _init(itemName: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemValue: int = 0, itemDamageDie: int = 0, itemAPCost: int = 0, itemSpeedCategory: String = "", itemQualities: String = "", itemSize: String = "", itemRange: String = "") -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemValue)
	allowed_slots = [ItemSlots.WeaponSlot]
	damage_profile = DamageProfile.new(0, itemDamageDie, 0)
	base_ap_cost = itemAPCost
	speed_category = _parse_speed_category(itemSpeedCategory)
	qualities = []
	qualities.assign(itemQualities.split(","))
	actions = []

	match itemSize:
		"1H":
			size = WeaponSize.ONE_HANDED
		"2H":
			size = WeaponSize.TWO_HANDED
		_:
			size = WeaponSize.ONE_HANDED

	match itemRange:
		null:
			weaponRange = WeaponRange.MELEE
		"C":
			weaponRange = WeaponRange.CLOSE
		"M":
			weaponRange = WeaponRange.MEDIUM
		"L":
			weaponRange = WeaponRange.LONG
		_:
			weaponRange = WeaponRange.MELEE

func _parse_speed_category(_value: String) -> WeaponSpeedCategory:
	match _value:
		"Very Fast":
			return WeaponSpeedCategory.VERY_FAST
		"Fast":
			return WeaponSpeedCategory.FAST
		"Slow":
			return WeaponSpeedCategory.SLOW
		_:
			return WeaponSpeedCategory.NORMAL

func get_speed_multiplier() -> float:
	match speed_category:
		WeaponSpeedCategory.VERY_FAST:
			return 0.6
		WeaponSpeedCategory.FAST:
			return 0.8
		WeaponSpeedCategory.SLOW:
			return 1.2
		_:
			return 1.0

func get_speed_category_name() -> String:
	match speed_category:
		WeaponSpeedCategory.VERY_FAST:
			return "Very Fast"
		WeaponSpeedCategory.FAST:
			return "Fast"
		WeaponSpeedCategory.SLOW:
			return "Slow"
		_:
			return "Normal"

func _print() -> String:
	return (
		super() +
		"Damage: " + damage_profile.describe() + "\n" +
		"AP Cost: " + str(base_ap_cost) + "\n" +
		"Speed: " + get_speed_category_name() + "\n" +
		"Qualities: " + str(qualities) + "\n" +
		"Size: " + str(size) + "\n" +
		"Range: " + str(weaponRange) + "\n"
	)
