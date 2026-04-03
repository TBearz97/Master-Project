extends CodexItem
class_name PlayerDataBlueprintEntry

enum SourceType {
	ATTRIBUTE,
	MODIFIER,
	PLAYER_FIELD,
	PLAYER_METHOD,
	DERIVED_EXPRESSION,
}

@export var source_type: SourceType
@export var source_id: int
@export var source_key: String
@export var expression: String
@export var sort_order: int
@export var enabled: bool


func _init(
	idDB: int = -1,
	nameDB: String = "",
	descriptionDB: String = "",
	source_typeDB: SourceType = SourceType.ATTRIBUTE,
	source_idDB: int = -1,
	source_keyDB: String = "",
	expressionDB: String = "",
	sort_orderDB: int = 0,
	enabledDB: bool = true,
) -> void:
	super(idDB, nameDB, descriptionDB, descriptionDB)
	source_type = source_typeDB
	source_id = source_idDB
	source_key = source_keyDB
	expression = expressionDB
	sort_order = sort_orderDB
	enabled = enabledDB
