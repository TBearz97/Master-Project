extends CodexItem
class_name Race

@export var perk: Perk

func _init(idDB:int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", perkDB: Perk = Perk.new()) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	perk = perkDB
