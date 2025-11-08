extends SpinBox

@export var iList : ItemList

func _ready() -> void:
	value = PlayerVariables.perk_points
	DbHelper.perk_chosen.connect(_on_perk_chosen)
	iList.item_selected.connect(_on_selected)
	
func _on_perk_chosen(perk: Dictionary) -> void:
	if value > 0 and !_item_exists(iList, perk["name"]):
		iList.add_item(perk["name"])
		iList.set_item_tooltip_enabled(iList.item_count - 1, true)
		iList.set_item_tooltip(iList.item_count - 1, perk["short_description"])
		iList.set_item_metadata(iList.item_count - 1, perk["long_description"])
		value -= 1

func _on_selected(index: int) -> void:
	iList.remove_item(index)
	value += 1

func _item_exists(_iList : ItemList, _name : String) -> bool :
	for i in range(_iList.item_count) :
		if _iList.get_item_text(i) == _name:
			return true
	return false
