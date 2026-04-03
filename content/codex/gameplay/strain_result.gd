extends CodexItem
class_name StrainResult

@export var roll_total: int
@export var outcome: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", roll_totalDB: int = 0, outcomeDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	roll_total = roll_totalDB
	outcome = outcomeDB
