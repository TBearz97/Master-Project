extends Button

@onready var character_name : LineEdit = %LineEdit
@onready var gender : OptionButton = %GenderOptions
@onready var race : OptionButton = %RaceOptions
@onready var homeland : OptionButton = %HomelandOptions
@onready var background : OptionButton = %BackgroundOptions
@onready var backstory : TextEdit = %TextEdit

@onready var mgt : SpinBox = %MValue 
@onready var dex : SpinBox = %DValue 
@onready var end : SpinBox = %EValue 
@onready var per : SpinBox = %PValue 
@onready var inte : SpinBox = %IValue 
@onready var res : SpinBox = %RValue 

func _ready():
	pressed.connect(_on_pressed)
	
func _on_pressed():
	PlayerVariables.character_name = character_name.text
	PlayerVariables.gender = gender.get_item_text(gender.selected)
	PlayerVariables.race = race.get_item_text(race.selected)
	PlayerVariables.homeland = homeland.get_item_text(homeland.selected)
	PlayerVariables.background = background.get_item_text(background.selected)
	PlayerVariables.backstory = backstory.text
	
