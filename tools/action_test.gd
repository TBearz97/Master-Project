extends Button
@export var weapon : Weapon
var target = CreatureData.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_useAction)
	target._name = "Test"
	target.maxHP = 100
	target.currentHP = 100


func _useAction() -> void:
	var result = weapon.actions[1].use(target, CreatureData.new(), weapon.damage_profile)
	print("Clicked: " + weapon.actions[1]._name)
	print(result)
