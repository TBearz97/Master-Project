extends SpinBox

@export var iList : ItemList

@onready var test : Control = %Character_Creator

func _ready() -> void:
	test.item_chosen.connect(_on_item_chosen)
	iList.item_selected.connect(_on_selected)
	
func _on_item_chosen(perk: Dictionary) -> void:
	if value - perk["cost"] >= 0:
		for i in iList.item_count:
			var curr_Item = iList.get_item_text(i)
			var parts = curr_Item.split(" x")
			if parts[0] == perk["name"]:
				var count := 1
				if parts.size() > 1:
					count = int(parts[1])
				count += 1
				iList.set_item_text(i, "%s x%d" % [parts[0], count])
				iList.set_item_metadata(iList.item_count - 1, perk["cost"])
				value -= perk["cost"]
				return 
		
		iList.add_item(perk["name"])
		iList.set_item_metadata(iList.item_count - 1, perk["cost"])
		value -= perk["cost"]
	
func _on_selected(index: int) -> void:
	var curr_Item = iList.get_item_text(index)
	var parts = curr_Item.split(" x")
	if parts.size() > 1:
		var count = int(parts[1]) - 1
		value += iList.get_item_metadata(index)
		if count == 1 :
			iList.set_item_text(index, parts[0])
		else :
			iList.set_item_text(index, "%s x%d" % [parts[0], count])
		iList.deselect(index)
	else :
		value += iList.get_item_metadata(index)
		iList.remove_item(index)
