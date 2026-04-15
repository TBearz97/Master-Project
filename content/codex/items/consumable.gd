extends Utility
class_name Consumable


func _init(itemName: String = "", shortDescription: String = "", longDescription: String = "", itemWeight: float = 0, itemExpression: String = "", itemValue: int = 0) -> void:
	super(itemName, shortDescription, longDescription, itemWeight, itemExpression, itemValue)
	allowed_slots = [ItemSlots.QuickItem]

func use(source: CreatureData, target: CreatureData = null, context: Dictionary = {}) -> Variant:
	return super.use(source, target, context)

func _print() -> String:
	return super()
