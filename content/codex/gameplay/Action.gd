extends Resource
class_name Action

@export var _name: String
@export var expressions: Array[String]

func _init() -> void:
	_name = ""
	expressions = []


func use(target: CreatureData, source: CreatureData) -> void:
	for expression in expressions :
		RuleEngine.evaluate(expression, ["target", "source"], [target, source])
