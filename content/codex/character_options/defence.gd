extends CodexItem
class_name Defence

@export var attribute1: Attribute
@export var attribute2: Attribute
@export var value: int

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", att1DB: Attribute = Attribute.new(), att2DB: Attribute = Attribute.new()) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	attribute1 = att1DB
	attribute2 = att2DB

func getValue(target: CreatureData) -> int:
	value = 0
	if target == null:
		return value

	for attribute: Attribute in target.attributes:
		if attribute == null:
			continue
		if attribute1 != null and attribute._name == attribute1._name:
			value += attribute.value
		if attribute2 != null and attribute._name == attribute2._name:
			value += attribute.value

	return value
