extends VBoxContainer

@onready var mgt : SpinBox = %MValue 
@onready var dex : SpinBox = %DValue 
@onready var end : SpinBox = %EValue 
@onready var per : SpinBox = %PValue 
@onready var inte : SpinBox = %IValue 
@onready var res : SpinBox = %RValue 

func _save():
		# Core attributes
	PlayerVariables.might = int(mgt.value)
	PlayerVariables.dexterity = int(dex.value)
	PlayerVariables.endurance = int(end.value)
	PlayerVariables.perception = int(per.value)
	PlayerVariables.intelligence = int(inte.value)
	PlayerVariables.resolve = int(res.value)
