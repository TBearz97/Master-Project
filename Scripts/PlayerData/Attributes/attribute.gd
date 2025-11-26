extends Resource
class_name Attribute

@export var _name : String
@export var value : int
@export var short_description : String
@export var long_description : String
@export var bonus_1_prefix : String
@export var bonus_2_prefix : String
@export var bonus_1_expression : String
@export var bonus_2_expression : String
@export var bonus_1_suffix : String
@export var bonus_2_suffix : String

func _init(
		_nameDB : String = "",
		valueAtt : int = 0,
		short_descriptionDB : String = "",
		long_descriptionDB : String = "",
		bonus_1_prefixDB : String = "",
		bonus_2_prefixDB : String = "",
		bonus_1_expressionDB : String = "",
		bonus_2_expressionDB : String = "",
		bonus_1_suffixDB : String = "",
		bonus_2_suffixDB : String = ""
	):
	self._name = _nameDB
	self.value = valueAtt
	self.short_description = short_descriptionDB
	self.long_description = long_descriptionDB
	self.bonus_1_prefix = bonus_1_prefixDB
	self.bonus_2_prefix = bonus_2_prefixDB
	self.bonus_1_expression = bonus_1_expressionDB
	self.bonus_2_expression = bonus_2_expressionDB
	self.bonus_1_suffix = bonus_1_suffixDB
	self.bonus_2_suffix = bonus_2_suffixDB
