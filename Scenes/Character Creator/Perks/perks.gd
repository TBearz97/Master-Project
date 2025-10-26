extends VBoxContainer

@onready var perks : ItemList = %PerkList

func _save():
	var array : Array[String] 
	for i in perks.item_count :
		array.append(perks.get_item_text(i))
	
	PlayerVariables.perks = array
