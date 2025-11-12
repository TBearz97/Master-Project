extends VBoxContainer

@onready var character_name : LineEdit = %Name
@onready var genderOb : OptionButton = %GenderOptions

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
	var title = Label.new()
	var description = Label.new()
	var perkTitle = Label.new()
	var perkDescription = Label.new()
	
	
	title.text = "Your race?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perkTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perkDescription.autowrap_mode = TextServer.AUTOWRAP_WORD
	perkDescription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var ob = OptionButton.new()
	var popup = ob.get_popup()
	var races = DbHelper.db_fetch("SELECT * FROM Race")
	for race in races :
		ob.add_item(race["name"], race["ID"] - 1)
		popup.set_item_tooltip(race["ID"] - 1, race["short_description"])
		popup.set_item_metadata(race["ID"] - 1, race)
	ob.item_selected.connect(func (index: int):
		var race = popup.get_item_metadata(index)
		description.text = race["long_description"]
		
		var perk = DbHelper.db_fetch("SELECT * FROM Perk WHERE name =" + "'" + race["perk"] + "'")
		perkTitle.text = "Perk: " + perk[0]["name"]
		perkDescription.text = perk[0]["long_description"]
		)
	ob.select(-1)
	
	raceGroup.add_child(title)
	raceGroup.add_child(ob)
	raceGroup.add_child(description)
	raceGroup.add_child(perkTitle)
	raceGroup.add_child(perkDescription)

func _homeland() :
	var title = Label.new()
	var description = Label.new()
	var perkTitle = Label.new()
	var perkDescription = Label.new()
	
	
	title.text = "Your Homeland?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perkTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perkDescription.autowrap_mode = TextServer.AUTOWRAP_WORD
	perkDescription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var ob = OptionButton.new()
	var popup = ob.get_popup()
	var homelands = DbHelper.db_fetch("SELECT * FROM Homeland")
	for homeland in homelands :
		ob.add_item(homeland["name"], homeland["ID"] - 1)
		popup.set_item_tooltip(homeland["ID"] - 1, homeland["short_description"])
		popup.set_item_metadata(homeland["ID"] - 1, homeland)
	ob.item_selected.connect(func (index: int):
		var homeland = popup.get_item_metadata(index)
		description.text = homeland["long_description"]
		
		var perk = DbHelper.db_fetch("SELECT * FROM Perk WHERE name =" + "'" + homeland["perk"] + "'")
		perkTitle.text = "Perk: " + perk[0]["name"]
		perkDescription.text = perk[0]["long_description"]
		)
	ob.select(-1)
	
	homelandGroup.add_child(title)
	homelandGroup.add_child(ob)
	homelandGroup.add_child(description)
	homelandGroup.add_child(perkTitle)
	homelandGroup.add_child(perkDescription)

func _background () :
	var title = Label.new()
	var description = Label.new()
	var perkTitle = Label.new()
	var perkDescription = Label.new()
	
	
	title.text = "Your Background?"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perkTitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	description.autowrap_mode = TextServer.AUTOWRAP_WORD
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	perkDescription.autowrap_mode = TextServer.AUTOWRAP_WORD
	perkDescription.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	var ob = OptionButton.new()
	var popup = ob.get_popup()
	var backgrounds = DbHelper.db_fetch("SELECT * FROM Background")
	for background in backgrounds :
		ob.add_item(background["name"], background["ID"] - 1)
		popup.set_item_tooltip(background["ID"] - 1, background["short_description"])
		popup.set_item_metadata(background["ID"] - 1, background)
	ob.item_selected.connect(func (index: int):
		var background = popup.get_item_metadata(index)
		description.text = background["long_description"]
		
		var perk = DbHelper.db_fetch("SELECT * FROM Perk WHERE name =" + '"' + background["perk"] + '"')
		perkTitle.text = "Perk: " + perk[0]["name"]
		perkDescription.text = perk[0]["long_description"]
		)
	ob.select(-1)
	
	backgroundGroup.add_child(title)
	backgroundGroup.add_child(ob)
	backgroundGroup.add_child(description)
	backgroundGroup.add_child(perkTitle)
	backgroundGroup.add_child(perkDescription)

func _save():
	# Basic information
	PlayerVariables.character_name = character_name.text
	if genderOb.selected != -1 :
		PlayerVariables.gender = genderOb.get_item_text(genderOb.selected)
	for child in raceGroup.get_children() :
		if child is OptionButton :
			if child.selected != -1 :
				PlayerVariables.race = child.get_item_text(child.selected)
	for child in homelandGroup.get_children() :
		if child is OptionButton :
			if child.selected != -1 :
				PlayerVariables.homeland = child.get_item_text(child.selected)
	for child in backgroundGroup.get_children() :
		if child is OptionButton :
			if child.selected != -1 :
				PlayerVariables.background = child.get_item_text(child.selected)
	PlayerVariables.backstory = backstory.text
