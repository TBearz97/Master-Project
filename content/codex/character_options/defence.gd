extends CodexItem
class_name Defence

@export var attribute1: Attribute
@export var attribute2: Attribute
@export var value: int

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", att1: Attribute = Attribute.new(), att2: Attribute = Attribute.new()) -> void:
	super(__name, shortDescription, longDescription)
	attribute1 = att1
	attribute2 = att2
	value = 0

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
