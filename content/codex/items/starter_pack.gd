extends CodexItem
class_name StarterPack

@export var leftover_gold: float
@export var items: Array

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", leftover_goldDB: float = 0.0, itemsDB: Array = []) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	leftover_gold = leftover_goldDB
	items = itemsDB
