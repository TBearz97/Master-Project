extends Resource
class_name CreatureData

var id: int
var name: String
var short_description: String
var long_description: String

var type: String
var category: String

var level: int
var max_hp: int

var attributes: Dictionary
var skills: Dictionary
var attacks: Array
var perks: Array


func _init(
	_id: int = 0,
	_name: String = "",
	_short_description: String = "",
	_long_description: String = "",
	_type: String = "",
	_category: String = "",
	_level: int = 1,
	_max_hp: int = 1,
	_attributes_json: String = "",
	_skills_json: String = "",
	_attacks_json: String = "",
	_perks_json: String = ""
) -> void:
	
	id = _id
	name = _name
	short_description = _short_description
	long_description = _long_description

	type = _type
	category = _category

	level = _level
	max_hp = _max_hp

	attributes = _parse_json_dict(_attributes_json)
	skills = _parse_json_dict(_skills_json)
	attacks = _parse_json_array(_attacks_json)
	perks = _parse_json_array(_perks_json)
