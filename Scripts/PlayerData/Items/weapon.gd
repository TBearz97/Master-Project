extends Item
class_name Weapon

enum WeaponSize {ONE_HANDED, TWO_HANDED}
enum WeaponRange {MELEE, CLOSE, MEDIUM, LONG}

@export var damage: float
@export var speed: int
@export var qualities : Array
@export var size : WeaponSize
@export var weaponRange : WeaponRange

func _init(itemName: String = "", itemWeight: float = 0, itemValue: int = 0, itemDamage: float = 0, itemSpeed : int = 0, itemQualities : String = "", itemSize : String = "", itemRange : String = "") -> void:
	super(itemName, itemWeight, itemValue)
	allowed_slots = [ItemSlots.WeaponSlot]
	damage = itemDamage
	speed = itemSpeed
	qualities = itemQualities.split(",")
	match itemSize :
		"1H" : size = WeaponSize.ONE_HANDED
		"2H" : size = WeaponSize.TWO_HANDED
	match itemRange :
		null : weaponRange = WeaponRange.MELEE
		"C" : weaponRange = WeaponRange.CLOSE
		"M" : weaponRange = WeaponRange.MEDIUM
		"L" : weaponRange = WeaponRange.LONG

func _print() -> String:
	return(super() +
		"Damage: " + str(damage) + "\n" +
		"Speed: " + str(speed) + "\n" +
		"Qualities: " + str(qualities) + "\n" +
		"Size: " + str(size) + "\n" +
		"Range: " + str(weaponRange) + "\n"
		)
