extends SpinBox

@export var iList : ItemList

@onready var test : Control = %Character_Creator

func _ready() -> void:
	test.perk_chosen.connect(_on_perk_chosen)
	iList.item_selected.connect(_on_selected)
	
func _on_perk_chosen(perk: Dictionary) -> void:
	if value > 0:
		iList.add_item(perk["name"])
		iList.set_item_tooltip_enabled(iList.item_count - 1, true)
		iList.set_item_tooltip(iList.item_count - 1, perk["short_description"])
		iList.set_item_metadata(iList.item_count - 1, perk["long_description"])
		value -= 1
	
func _on_selected(index: int) -> void:
	iList.remove_item(index)
	value += 1
