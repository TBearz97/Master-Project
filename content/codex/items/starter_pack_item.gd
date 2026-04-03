extends Resource
class_name StarterPackItem

@export var item_table: String
@export var item_id: int
@export var quantity: int
@export var loadout_group: String
@export var item: Item

func _init(item_tableDB: String = "", item_idDB: int = 0, quantityDB: int = 0, loadout_groupDB: String = "", itemDB: Item = null) -> void:
	item_table = item_tableDB
	item_id = item_idDB
	quantity = quantityDB
	loadout_group = loadout_groupDB
	item = itemDB
