extends VBoxContainer

@onready var character_name: LineEdit = %Name
@onready var genderOb: OptionButton = %GenderOptions
@onready var age: SpinBox = %Age

@onready var raceGroup: VBoxContainer = %Race
@onready var homelandGroup: VBoxContainer = %Homeland
@onready var backgroundGroup: VBoxContainer = %Background

@onready var backstory: TextEdit = %Backstory

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()

func _setup() -> void:
	if PlayerVariables.getName() != "":
		character_name.text = PlayerVariables.getName()
	if PlayerVariables.getGender() != "":
		for i in range(genderOb.item_count):
			if PlayerVariables.getGender() == genderOb.get_item_text(i):
				genderOb.select(i)
	age.value = PlayerVariables.getAge()

	_race()
	_homeland()
	_background()

func _race() -> void:
	var title := CampaignVariables.prepareLabel(RichTextLabel.new())
	var description := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
	var perkTitle := CampaignVariables.prepareLabel(RichTextLabel.new())
	var perkDescription := CampaignVariables.prepareLabel(RichTextLabel.new(), false)

	title.text = "Your race?"

	var ob := OptionButton.new()
	var popup := ob.get_popup()
	var races := CampaignVariables.codex.Races
	var id := 0
	for race: Race in races.values():
		ob.add_item(race._name, id)
		popup.set_item_tooltip(id, race.short_description)
		popup.set_item_metadata(id, race)
		id += 1

	ob.item_selected.connect(func(index: int) -> void:
		var race: Race = popup.get_item_metadata(index)
		description.text = CampaignVariables.replaceText(race.long_description)

		var perk: Perk = race.perk
		perkTitle.text = CampaignVariables.replaceText("Perk: " + perk._name)
		perkDescription.text = CampaignVariables.replaceText(perk.long_description)
		)

	for i in range(ob.item_count):
		if PlayerVariables.getRace()._name == ob.get_item_text(i):
			ob.select(i)
			var race: Race = popup.get_item_metadata(i)
			description.text = CampaignVariables.replaceText(race.long_description)
			break
		else:
			ob.select(-1)

	raceGroup.add_child(title)
	raceGroup.add_child(ob)
	raceGroup.add_child(description)
	raceGroup.add_child(perkTitle)
	raceGroup.add_child(perkDescription)

func _homeland() -> void:
	var title := CampaignVariables.prepareLabel(RichTextLabel.new())
	var description := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
	var perkTitle := CampaignVariables.prepareLabel(RichTextLabel.new())
	var perkDescription := CampaignVariables.prepareLabel(RichTextLabel.new(), false)

	title.text = "Your Homeland?"

	var ob := OptionButton.new()
	var popup := ob.get_popup()
	var homelands := CampaignVariables.codex.Homelands
	var id := 0
	for homeland: Homeland in homelands.values():
		ob.add_item(homeland._name, id)
		popup.set_item_tooltip(id, homeland.short_description)
		popup.set_item_metadata(id, homeland)
		id += 1

	ob.item_selected.connect(func(index: int) -> void:
		var homeland: Homeland = popup.get_item_metadata(index)
		description.text = CampaignVariables.replaceText(homeland.long_description)

		var perk: Perk = homeland.perk
		perkTitle.text = CampaignVariables.replaceText("Perk: " + perk._name)
		perkDescription.text = CampaignVariables.replaceText(perk.long_description)
		)

	for i in range(ob.item_count):
		if PlayerVariables.getHomeland()._name == ob.get_item_text(i):
			ob.select(i)
			var homeland: Homeland = popup.get_item_metadata(i)
			description.text = CampaignVariables.replaceText(homeland.long_description)
			break
		else:
			ob.select(-1)

	homelandGroup.add_child(title)
	homelandGroup.add_child(ob)
	homelandGroup.add_child(description)
	homelandGroup.add_child(perkTitle)
	homelandGroup.add_child(perkDescription)

func _background() -> void:
	var title := CampaignVariables.prepareLabel(RichTextLabel.new())
	var description := CampaignVariables.prepareLabel(RichTextLabel.new(), false)
	var perkTitle := CampaignVariables.prepareLabel(RichTextLabel.new())
	var perkDescription := CampaignVariables.prepareLabel(RichTextLabel.new(), false)

	title.text = CampaignVariables.replaceText("Your Background?")

	var ob := OptionButton.new()
	var popup := ob.get_popup()
	var backgrounds := CampaignVariables.codex.Backgrounds
	var id := 0
	for background: Background in backgrounds.values():
		ob.add_item(background._name, id)
		popup.set_item_tooltip(id, background.short_description)
		popup.set_item_metadata(id, background)
		id += 1

	ob.item_selected.connect(func(index: int) -> void:
		var background: Background = popup.get_item_metadata(index)
		description.text = CampaignVariables.replaceText(background.long_description)

		var perk: Perk = background.perk
		perkTitle.text = CampaignVariables.replaceText("Perk: " + perk._name)
		perkDescription.text = CampaignVariables.replaceText(perk.long_description)
		)

	for i in range(ob.item_count):
		if PlayerVariables.getBackground()._name == ob.get_item_text(i):
			ob.select(i)
			var background: Background = popup.get_item_metadata(i)
			description.text = CampaignVariables.replaceText(background.long_description)
			break
		else:
			ob.select(-1)

	backgroundGroup.add_child(title)
	backgroundGroup.add_child(ob)
	backgroundGroup.add_child(description)
	backgroundGroup.add_child(perkTitle)
	backgroundGroup.add_child(perkDescription)

func _save() -> void:
	PlayerVariables.setName(character_name.text)
	PlayerVariables.setAge(int(age.value))
	if genderOb.selected != -1:
		PlayerVariables.setGender(genderOb.get_item_text(genderOb.selected))
	else:
		PlayerVariables.setGender(genderOb.get_item_text(0))
	for child in raceGroup.get_children():
		if child is OptionButton:
			if child.selected != -1:
				PlayerVariables.setRace(child.get_item_metadata(child.selected))
			else:
				PlayerVariables.setRace(child.get_item_metadata(0))
	for child in homelandGroup.get_children():
		if child is OptionButton:
			if child.selected != -1:
				PlayerVariables.setHomeland(child.get_item_metadata(child.selected))
			else:
				PlayerVariables.setHomeland(child.get_item_metadata(0))
	for child in backgroundGroup.get_children():
		if child is OptionButton:
			if child.selected != -1:
				PlayerVariables.setBackground(child.get_item_metadata(child.selected))
			else:
				PlayerVariables.setBackground(child.get_item_metadata(0))
	PlayerVariables.setBackstory(backstory.text)
