extends CodexItem
class_name Background

@export var perk: Perk
@export var skill_1 : Skill
@export var skill_2 : Skill

func _init(idDB:int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", perkDB: Perk = Perk.new(), skill_1DB: Skill = Skill.new(), skill_2DB: Skill = Skill.new()) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	perk = perkDB
	skill_1 = skill_1DB
	skill_2 = skill_2DB
