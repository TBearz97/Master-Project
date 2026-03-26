extends CodexItem
class_name Action

@export var expressions: Array[String]

func _init(__name: String = "", shortDescription: String = "", longDescription: String = "") -> void:
	super(__name, shortDescription, longDescription)
	expressions = []


func use(target: CreatureData, source: CreatureData, damageProfile: DamageProfile):
	for expression in expressions:
		return RuleEngine.evaluate(expression, ["target", "source", "dmgProfile"], [target, source, damageProfile])
