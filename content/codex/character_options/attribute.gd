extends CodexItem
class_name Attribute

@export var value: int
@export var bonus_1_prefix: String
@export var bonus_2_prefix: String
@export var bonus_1_expression: String
@export var bonus_2_expression: String
@export var bonus_1_suffix: String
@export var bonus_2_suffix: String

func _init(
	__name: String = "",
	shortDescription: String = "",
	longDescription: String = "",
	valueAtt: int = 0,
	bonus_1_prefixDB: String = "",
	bonus_2_prefixDB: String = "",
	bonus_1_expressionDB: String = "",
	bonus_2_expressionDB: String = "",
	bonus_1_suffixDB: String = "",
	bonus_2_suffixDB: String = ""
) -> void:
	super(__name, shortDescription, longDescription)
	value = valueAtt
	bonus_1_prefix = bonus_1_prefixDB
	bonus_2_prefix = bonus_2_prefixDB
	bonus_1_expression = bonus_1_expressionDB
	bonus_2_expression = bonus_2_expressionDB
	bonus_1_suffix = bonus_1_suffixDB
	bonus_2_suffix = bonus_2_suffixDB

	if _name != "":
		var error := ResourceSaver.save(self, "res://data/Attribute/" + _name + ".res")
		if error != OK:
			push_error("Attribute save failed for %s: %s" % [_name, error])
