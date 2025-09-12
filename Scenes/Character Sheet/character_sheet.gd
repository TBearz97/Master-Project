extends Node2D

@onready var char_name = %Name_Field
@onready var gender = %Gender_Field
@onready var race = %Race_Field
@onready var homeland = %Homeland_Field
@onready var background = %Background_Field
@onready var backstory = %Backstory_Field

func _ready() -> void:
	char_name.text = PlayerVariables.character_name
	gender.text = PlayerVariables.gender
	race.text = PlayerVariables.race
	homeland.text = PlayerVariables.homeland
	background.text = PlayerVariables.background
	backstory.text = PlayerVariables.backstory
