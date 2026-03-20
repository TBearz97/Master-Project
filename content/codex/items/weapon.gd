extends Item
class_name Weapon

enum WeaponSize {ONE_HANDED, TWO_HANDED}
enum WeaponRange {MELEE, CLOSE, MEDIUM, LONG}

@export var damage: float
@export var speed: int
@export var qualities: Array[String]
@export var size: WeaponSize
@export var weaponRange: WeaponRange

func _init(itemName: String = "", shortDescription : String = "", longDescription : String = "", itemWeight: float = 0, itemValue: int = 0, itemDamage: float = 0, itemSpeed: int = 0, itemQualities: String = "", itemSize: String = "", itemRange: String = "") -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemValue)
	allowed_slots = [ItemSlots.WeaponSlot]
	damage = itemDamage
	speed = itemSpeed
	qualities.assign(itemQualities.split(",")) 

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

func _print() -> String:
	return(super() +
		"Damage: " + str(damage) + "\n" +
		"Speed: " + str(speed) + "\n" +
		"Qualities: " + str(qualities) + "\n" +
		"Size: " + str(size) + "\n" +
		"Range: " + str(weaponRange) + "\n"
	)
