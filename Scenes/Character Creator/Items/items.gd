extends VBoxContainer

@onready var items : ItemList = %ItemList

func _save():
	var array : Array[String] 
	for i in items.item_count :
		array.append(items.get_item_text(i))
	
	PlayerVariables.inventory = array
