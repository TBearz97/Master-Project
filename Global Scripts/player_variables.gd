extends Node

var character_name : String
var gender : String
var race : String
var homeland : String
var background : String
var backstory : String

var might : int
var dexterity : int
var endurance : int
var perception : int
var intelligence : int
var resolve : int


func calculate_Damage_Healing_Bonus (MGT: int) -> int:
	return (MGT - 1) * 5 

func calculate_Carry_Weight (MGT: int) -> int:
	return ((MGT - 1) * 5) + 75

func calculate_Action_Points (DEX: int) -> int:
	return DEX + 3
	
func calculate_Speed_Bonus (DEX: int) -> int:
	return (DEX - 1) * 2
	
func calculate_Health_Bonus (END: int) -> int:
	return END + 5
	
func calculate_Vitality_Bonus (END: int) -> int:
	return (3 + floor((END - 1) / 3))

func calculate_Effect_Difficulty (INT: int) -> int:
	return floor((INT - 1) / 2) - 1

func calculate_Mana_Generation (INT: int) -> int:
	return INT

func calculate_Concentration (RES: int) -> int:
	return RES
	
func calculate_Effect_Duration (RES: int) -> int:
	return (RES - 1) * 5

func calculate_Accuracy (PER: int) -> int:
	return floor((PER) / 2)

func calculate_Weapspot_Damage (PER: int) -> int:
	return PER
	
func calucalte_Defence (att1 : int, att2 : int):
	return att1 + att2
