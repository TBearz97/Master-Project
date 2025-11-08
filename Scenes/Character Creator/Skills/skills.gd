extends VBoxContainer

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

func _save():
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
