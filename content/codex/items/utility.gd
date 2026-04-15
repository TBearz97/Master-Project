extends Item
class_name Utility

@export var expression: String

func _init(itemName: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemExpression: String = "", itemValue: int = 0) -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	expression = itemExpression

func use(source: CreatureData, target: CreatureData = null, context: Dictionary = {}) -> Variant:
	if expression.strip_edges().is_empty():
		return {"success": false, "reason": "unsupported_utility", "item_name": _name}
	return RuleEngine.evaluate(expression, ["source", "target", "item", "context"], [source, target, self, context])

func _print() -> String:
	return (
		super() +
		"Expression: " + expression
	)
