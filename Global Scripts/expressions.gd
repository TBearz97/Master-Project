extends Node

enum diceType {d4 = 4, d6 = 6, d8 = 8, d10 = 10, d12 = 12, d20 = 20}

signal diceRolled(diceArray)

func evaluate(command, variable_names = [], variable_values = []):
	var expression = Expression.new()
	var error = expression.parse(command, variable_names)
	if error != OK:
		push_error(expression.get_error_text())

	var result = expression.execute(variable_values, self)

	if not expression.has_execute_failed():
		return result
	
	return null
	


func rollDice(num: int, sides: int) -> int:
	var diceArray = []
	var rng = RandomNumberGenerator.new()
	var total := 0
	for i in num:
		var res = rng.randi_range(1, sides)
		total += res
		diceArray.append(res)
	emit_signal("diceRolled", diceArray)
	return total
