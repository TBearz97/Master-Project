extends CodexItem
class_name Action

@export var ap_cost: int
@export var speed: int
@export var expressions: Array[String]

func _init(idDB: int = -1, _nameDB: String = "", short_descriptionDB: String = "", long_descriptionDB: String = "", ap_costDB: int = 0, speedDB: int = 0, expressionsDB: Array[String] = []) -> void:
	super(idDB, _nameDB, short_descriptionDB, long_descriptionDB)
	ap_cost = ap_costDB
	speed = speedDB
	expressions = expressionsDB


func use(target: CreatureData, source: CreatureData):
	for expression in expressions:
		return RuleEngine.evaluate(expression, ["target", "source"], [target, source])
