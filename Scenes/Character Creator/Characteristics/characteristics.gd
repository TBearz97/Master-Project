extends VBoxContainer

@onready var character_name : LineEdit = %LineEdit
@onready var gender : OptionButton = %GenderOptions
@onready var race : OptionButton = %RaceOptions
@onready var homeland : OptionButton = %HomelandOptions
@onready var background : OptionButton = %BackgroundOptions
@onready var backstory : TextEdit = %TextEdit

func _process(delta: float) -> void:
	visibility_changed.connect(_save)

func _save():
	# Basic information
	PlayerVariables.character_name = character_name.text
	PlayerVariables.gender = gender.get_item_text(gender.selected)
	PlayerVariables.race = race.get_item_text(race.selected)
	PlayerVariables.homeland = homeland.get_item_text(homeland.selected)
	PlayerVariables.background = background.get_item_text(background.selected)
	PlayerVariables.backstory = backstory.text
