extends CodexItem
class_name SpellVariant

@export var spell: Spell
@export var mana_cost : int

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", spellDB: Spell = null, mana_costDB: int = 0) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	spell = spellDB
	mana_cost = mana_costDB
