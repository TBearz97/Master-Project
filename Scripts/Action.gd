extends Resource
class_name Action

@export var _name : String
@export var expression : String

func _init() -> void:
	_name = ""
	expression = ""

func use() -> void:
	Expressions.evaluate(expression)
