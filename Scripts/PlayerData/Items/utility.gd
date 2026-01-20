extends Item
class_name Utility

@export var effect: String

func _init(itemName: String = "", itemWeight: float = 0, itemEffect: String = "", itemValue: int = 0) -> void:
	super(itemName, itemWeight, itemValue)
	allowed_slots = [ItemSlots.QuickItem]
	effect = itemEffect

func get_shared_properties() -> Array[SharedProperty]:
	return super.get_shared_properties() + [
		SharedProperty.new("effect")
			.with_type(BytePacker.TYPE.LONG_STRING)
			.in_sync(true),
	]

func _print() -> String:
	return (super() + "Effect: " + effect)
