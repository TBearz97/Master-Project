extends Item
class_name Weapon

enum WeaponSize {ONE_HANDED, TWO_HANDED}
enum WeaponRange {MELEE, CLOSE, MEDIUM, LONG}

var damage: int
var speed: int
var qualities : Array
var size : WeaponSize
var weaponRange : WeaponRange

func _init(itemName: String, itemDescription: String, itemWeight: float, itemValue: int, itemDamage: int, itemSpeed : int, itemQualities : Array, itemSize : String, itemRange : String) -> void:
	super(itemName, itemDescription, itemWeight, itemValue)
	damage = itemDamage
	speed = itemSpeed
	qualities = itemQualities
	match itemSize :
		"1H" : size = WeaponSize.ONE_HANDED
		"2H" : size = WeaponSize.TWO_HANDED
	match itemRange :
		null : weaponRange = WeaponRange.MELEE
		"C" : weaponRange = WeaponRange.CLOSE
		"M" : weaponRange = WeaponRange.MEDIUM
		"L" : weaponRange = WeaponRange.LONG

func use(target) -> void:
	print("You attack %s with %s for %d damage." % [str(target), name, damage])
