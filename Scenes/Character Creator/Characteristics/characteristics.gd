extends VBoxContainer

@onready var character_name : LineEdit = %Name
@onready var genderOb : OptionButton = %GenderOptions
@onready var age : SpinBox = %Age

@onready var raceGroup : VBoxContainer = %Race
@onready var homelandGroup : VBoxContainer = %Homeland
@onready var backgroundGroup : VBoxContainer = %Background

@onready var backstory : TextEdit = %Backstory

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()
	

func _setup() :
	_race()
	_homeland()
	_background()
	

func _race () :
	var title = DbHelper.prepareLabel(RichTextLabel.new())
	var description = DbHelper.prepareLabel(RichTextLabel.new(), false)
	var perkTitle = DbHelper.prepareLabel(RichTextLabel.new())
	var perkDescription = DbHelper.prepareLabel(RichTextLabel.new(), false)
	
	title.text = "Your race?"
	
	var ob = OptionButton.new()
	var popup = ob.get_popup()
	var races = DbHelper.db_fetch("SELECT * FROM Race")
	for race in races :
		ob.add_item(race["name"], race["ID"] - 1)
		popup.set_item_tooltip(race["ID"] - 1, race["short_description"])
		popup.set_item_metadata(race["ID"] - 1, race)
	ob.item_selected.connect(func (index: int):
		var race = popup.get_item_metadata(index)
		description.text = DbHelper.replaceText(race["long_description"]) 
		
		var perk = DbHelper.db_fetch("SELECT * FROM Perk WHERE name =" + "'" + race["perk"] + "'")
		perkTitle.text = DbHelper.replaceText("Perk: " + perk[0]["name"]) 
		perkDescription.text = DbHelper.replaceText(perk[0]["long_description"]) 
		)
	ob.select(-1)
	
	raceGroup.add_child(title)
	raceGroup.add_child(ob)
	raceGroup.add_child(description)
	raceGroup.add_child(perkTitle)
	raceGroup.add_child(perkDescription)

func _homeland() :
	var title = DbHelper.prepareLabel(RichTextLabel.new())
	var description = DbHelper.prepareLabel(RichTextLabel.new(), false)
	var perkTitle = DbHelper.prepareLabel(RichTextLabel.new())
	var perkDescription = DbHelper.prepareLabel(RichTextLabel.new(), false)
	
	title.text = "Your Homeland?"
	
	var ob = OptionButton.new()
	var popup = ob.get_popup()
	var homelands = DbHelper.db_fetch("SELECT * FROM Homeland")
	for homeland in homelands :
		ob.add_item(homeland["name"], homeland["ID"] - 1)
		popup.set_item_tooltip(homeland["ID"] - 1, homeland["short_description"])
		popup.set_item_metadata(homeland["ID"] - 1, homeland)
	ob.item_selected.connect(func (index: int):
		var homeland = popup.get_item_metadata(index)
		description.text = DbHelper.replaceText(homeland["long_description"]) 
		
		var perk = DbHelper.db_fetch("SELECT * FROM Perk WHERE name =" + "'" + homeland["perk"] + "'")
		perkTitle.text = DbHelper.replaceText("Perk: " + perk[0]["name"]) 
		perkDescription.text = DbHelper.replaceText(perk[0]["long_description"]) 
		)
	ob.select(-1)
	
	homelandGroup.add_child(title)
	homelandGroup.add_child(ob)
	homelandGroup.add_child(description)
	homelandGroup.add_child(perkTitle)
	homelandGroup.add_child(perkDescription)

func _background () :
	var title = DbHelper.prepareLabel(RichTextLabel.new())
	var description = DbHelper.prepareLabel(RichTextLabel.new(), false)
	var perkTitle = DbHelper.prepareLabel(RichTextLabel.new())
	var perkDescription = DbHelper.prepareLabel(RichTextLabel.new(), false)
	
	
	title.text = DbHelper.replaceText("Your Background?") 
	
	var ob = OptionButton.new()
	var popup = ob.get_popup()
	var backgrounds = DbHelper.db_fetch("SELECT * FROM Background")
	for background in backgrounds :
		ob.add_item(background["name"], background["ID"] - 1)
		popup.set_item_tooltip(background["ID"] - 1, background["short_description"])
		popup.set_item_metadata(background["ID"] - 1, background)
	ob.item_selected.connect(func (index: int):
		var background = popup.get_item_metadata(index)
		description.text = DbHelper.replaceText(background["long_description"]) 
		
		var perk = DbHelper.db_fetch("SELECT * FROM Perk WHERE name =" + '"' + background["perk"] + '"')
		perkTitle.text = DbHelper.replaceText("Perk: " + perk[0]["name"]) 
		perkDescription.text = DbHelper.replaceText(perk[0]["long_description"]) 
		)
	ob.select(-1)
	
	backgroundGroup.add_child(title)
	backgroundGroup.add_child(ob)
	backgroundGroup.add_child(description)
	backgroundGroup.add_child(perkTitle)
	backgroundGroup.add_child(perkDescription)

func _save():
	# Basic information
	PlayerVariables.setName(character_name.text) 
	PlayerVariables.setAge(int(age.value))
	if genderOb.selected != -1 :
		PlayerVariables.setGender(genderOb.get_item_text(genderOb.selected)) 
	for child in raceGroup.get_children() :
		if child is OptionButton :
			if child.selected != -1 :
				PlayerVariables.setRace(child.get_item_text(child.selected)) 
	for child in homelandGroup.get_children() :
		if child is OptionButton :
			if child.selected != -1 :
				PlayerVariables.setHomeland(child.get_item_text(child.selected)) 
	for child in backgroundGroup.get_children() :
		if child is OptionButton :
			if child.selected != -1 :
				PlayerVariables.setBackground(child.get_item_text(child.selected)) 
	PlayerVariables.setBackstory(backstory.text) 
