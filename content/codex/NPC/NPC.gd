extends CodexItem
class_name NPC

@export var data: CreatureData

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", dataDB: CreatureData = CreatureData.new()) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	data = dataDB
