extends CodexItem
class_name Modifier

enum ApplicationType {
	FLAT,
	PERCENT_ADD,
	PERCENT_MULT,
	OVERRIDE,
}

@export var value: float
@export var application_type: ApplicationType


func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "") -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	value = 0.0
	application_type = ApplicationType.FLAT


func apply_to(base_value: float) -> float:
	match application_type:
		ApplicationType.FLAT:
			return base_value + value
		ApplicationType.PERCENT_ADD:
			return base_value + (base_value * (value / 100.0))
		ApplicationType.PERCENT_MULT:
			return base_value * max(0.0, 1.0 + (value / 100.0))
		ApplicationType.OVERRIDE:
			return value
		_:
			return base_value
