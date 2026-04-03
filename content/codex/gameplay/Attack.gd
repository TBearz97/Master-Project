extends Action
class_name Attack

@export var attack_tier: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", ap_costDB: int = 0, speedDB: int = 0, expressionsDB: Array[String] = [], attack_tierDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB, ap_costDB, speedDB, expressionsDB)
	attack_tier = attack_tierDB
