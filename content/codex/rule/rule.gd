extends CodexItem
class_name Rule

@export var expression: String

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "", expr: String = "") -> void:
	super(__name, shortDescription, longDescription)
	expression = expr
