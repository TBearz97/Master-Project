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

@onready var animalHandling : SpinBox = %AnimalHandlingValue
@onready var athletics : SpinBox = %AthleticsValue
@onready var command : SpinBox = %CommandValue
@onready var craft : SpinBox = %CraftValue
@onready var insight : SpinBox = %InsightValue
@onready var investigation : SpinBox = %InvestigationValue
@onready var lore : SpinBox = %LoreValue
@onready var medicine : SpinBox = %MedicineValue
@onready var sleightOfHand : SpinBox = %SleightOfHandValue
@onready var society : SpinBox = %SocietyValue
@onready var speech : SpinBox = %SpeechValue
@onready var stealth : SpinBox = %StealthValue
@onready var survival : SpinBox = %SurvivalValue

@onready var perks : ItemList = %PerkList
@onready var items : ItemList = %ItemList

func _ready():
	pressed.connect(_on_pressed)
	
func _on_pressed():
	# Basic information
	PlayerVariables.character_name = character_name.text
	PlayerVariables.gender = gender.get_item_text(gender.selected)
	PlayerVariables.race = race.get_item_text(race.selected)
	PlayerVariables.homeland = homeland.get_item_text(homeland.selected)
	PlayerVariables.background = background.get_item_text(background.selected)
	PlayerVariables.backstory = backstory.text

	# Core attributes
	PlayerVariables.might = int(mgt.value)
	PlayerVariables.dexterity = int(dex.value)
	PlayerVariables.endurance = int(end.value)
	PlayerVariables.perception = int(per.value)
	PlayerVariables.intelligence = int(inte.value)
	PlayerVariables.resolve = int(res.value)

	# Skills
	PlayerVariables.animalHandling = int(animalHandling.value)
	PlayerVariables.athletics = int(athletics.value)
	PlayerVariables.command = int(command.value)
	PlayerVariables.craft = int(craft.value)
	PlayerVariables.insight = int(insight.value)
	PlayerVariables.investigation = int(investigation.value)
	PlayerVariables.lore = int(lore.value)
	PlayerVariables.medicine = int(medicine.value)
	PlayerVariables.sleightOfHand = int(sleightOfHand.value)
	PlayerVariables.society = int(society.value)
	PlayerVariables.speech = int(speech.value)
	PlayerVariables.stealth = int(stealth.value)
	PlayerVariables.survival = int(survival.value)

	# Lists
	PlayerVariables.perks = itemListToArray(perks)
	PlayerVariables.inventory = itemListToArray(items)
	
	PlayerVariables.save()
	PlayerVariables.load(PlayerVariables.character_name)



func itemListToArray (iList : ItemList) -> Array[String] :
	var array : Array[String] 
	for i in iList.item_count :
		array.append(iList.get_item_text(i))
	return array
