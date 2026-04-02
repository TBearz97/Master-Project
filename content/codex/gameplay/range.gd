extends CodexItem
class_name ActionRange

@export var max_distance: int
@export var short_hand: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", max_distanceDB: int = 0, short_handDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	max_distance = max_distanceDB
	short_hand = short_handDB
