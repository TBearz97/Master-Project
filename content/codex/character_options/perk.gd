extends CodexItem
class_name Perk

@export var category: String
@export var requirement_text: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", categoryDB: String = "", requirement_textDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	category = categoryDB
	requirement_text = requirement_textDB
