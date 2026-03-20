extends Resource
class_name Action

@export var _name: String
@export var expression: String

func _init() -> void:
	_name = ""
	expression = ""

func can_use(target: CreatureData, source: CreatureData) -> bool:
	return target != null and source != null and not expression.is_empty()

func use(target: CreatureData, source: CreatureData) -> Variant:
	if not can_use(target, source):
		push_error("Action.use requires a target, a source, and a non-empty expression.")
		return null

	return Expressions.evaluate(expression, ["target", "source"], [target, source])
