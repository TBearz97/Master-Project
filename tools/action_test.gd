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
	if weapon == null or weapon.actions.is_empty():
		print("No weapon action available.")
		return
	var action: Action = weapon.actions[0]
	var result = action.use(target, CreatureData.new(), weapon.damage_profile)
	print("Clicked: " + action._name)
	print(result)
