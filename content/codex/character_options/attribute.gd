extends CodexItem
class_name Attribute

@export var value: int
@export var modifier_1: Modifier
@export var modifier_1_expression: String
@export var modifier_2: Modifier
@export var modifier_2_expression: String


func _init(
	idDB: int = -1,
	_nameDB: String = "",
	short_descriptionDB: String = "",
	long_descriptionDB: String = "",
	modifier_1DB: Modifier = Modifier.new(),
	modifier_1_expressionDB: String = "",
	modifier_2DB: Modifier = Modifier.new(),
	modifier_2_expressionDB: String = "",
) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	modifier_1 = modifier_1DB
	modifier_1_expression = modifier_1_expressionDB
	modifier_2 = modifier_2DB
	modifier_2_expression = modifier_2_expressionDB
	value = 0
