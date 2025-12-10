extends Resource
class_name Equipment

#Armor
@export var head : Armor
@export var torso : Armor
@export var leftArm : Armor
@export var rightArm : Armor
@export var leftLeg : Armor
@export var rightLeg : Armor

#Weapons
@export var weapon1Left : Weapon
@export var weapon1Right : Weapon
@export var weapon2Left : Weapon
@export var weapon2Right : Weapon

#Quick Items
@export var quickItem1 : Item
@export var quickItem2 : Item
@export var quickItem3 : Item
@export var quickItem4 : Item

func equipmentList() -> Array[Item]:
	return [
		head,
		torso,
		leftArm,
		rightArm,
		leftLeg,
		rightLeg,
		weapon1Left,
		weapon1Right,
		weapon2Left,
		weapon2Right,
		quickItem1,
		quickItem2,
		quickItem3,
		quickItem4
	]
