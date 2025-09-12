extends SpinBox

@export var bonus1 : SpinBox
@export var bonus2 : SpinBox

func _ready() -> void:
	value_changed.connect(_on_value_changed)
	_on_value_changed(1)

func _on_value_changed(new_value: int) -> void:
	if bonus1:
		bonus1.value = PlayerVariables.calculate_Action_Points(new_value)
	if bonus2:
		bonus2.value = PlayerVariables.calculate_Speed_Bonus(new_value)
