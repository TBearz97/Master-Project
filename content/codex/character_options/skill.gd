extends CodexItem
class_name Skill

@export var value: int
@export var min_rank: int
@export var max_rank: int

func _init(idDB: int = -1,
	_nameDB: String = "",
	short_descriptionDB: String = "",
	long_descriptionDB: String = "",
	min_rankDB: int = 0,
	max_rankDB: int = 10,
) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	value = 0
	min_rank = min_rankDB
	max_rank = max_rankDB
