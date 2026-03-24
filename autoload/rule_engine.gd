extends Node

enum DiceType { D4 = 4, D6 = 6, D8 = 8, D10 = 10, D12 = 12, D20 = 20 }

signal diceRolled(diceArray)

func evaluate(command: String, variable_names: Array = [], variable_values: Array = []) -> Variant:
	var expression := Expression.new()
	var error := expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())
		return null

	var result: Variant = expression.execute(variable_values, self)

	if not expression.has_execute_failed():
		return result

	return null

func rollDice(num: int, sides: int) -> int:
	var diceArray: Array[int] = []
	var rng := RandomNumberGenerator.new()
	var total := 0
	for i in num:
		var res := rng.randi_range(1, sides)
		total += res
		diceArray.append(res)
	diceRolled.emit(diceArray)
	return total


func dealDamage(target : CreatureData) -> void:
	print(target._name + " Took 5 damage")
	
func applyCondition(target : CreatureData, condition_name : String) -> void:
	var condition = CampaignVariables.codex.Conditions.get(condition_name)
	print(target._name + " received " + condition._name)
