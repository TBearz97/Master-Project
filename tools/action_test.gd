extends Button

@export var action : Action
var target = CreatureData.new()
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pressed.connect(_useAction)
	target._name = "Test"


func _useAction() -> void:
	action.use(target, CreatureData.new())
	print("Clicked: " + action._name)
