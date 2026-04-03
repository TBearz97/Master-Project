extends CodexItem
class_name Rule

@export var expression: String

func _init(idDB: int = -1, __name: String = "", shortDescription: String = "", longDescription: String = "", expr: String = "") -> void:
	super(idDB, __name, shortDescription, longDescription)
	expression = expr
