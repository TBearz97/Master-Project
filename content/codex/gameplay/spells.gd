extends CodexItem
class_name Spell

@export var school: SpellSchool
@export var tags: Array[String]
@export var action_range: ActionRange
@export var base_cast: String

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", schoolDB: SpellSchool = SpellSchool.new(), tagsDB: Array[String] = [], action_rangeDB: ActionRange = ActionRange.new(), base_castDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	school = schoolDB
	tags = tagsDB
	action_range = action_rangeDB
	base_cast = base_castDB
