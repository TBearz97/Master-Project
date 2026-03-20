extends VBoxContainer

@export var points: SpinBox
@export var selected: ItemList
@export var grid: GridContainer

var _selected_click_connected: bool = false

func _ready() -> void:
	_setup()
	visibility_changed.connect(_save)
	if not PlayerVariables.getPerks().is_empty():
		for perk in PlayerVariables.getPerks():
			var idx := selected.add_item(perk._name)
			selected.set_item_metadata(idx, perk)
			selected.set_item_tooltip(idx, perk.short_description)
	_connect_selected_item_clicked()

func _setup() -> void:
	points.value = PlayerVariables.getPerkPoints()
	var categories: Array = (func() -> Array:
		var excluded := ["Race", "Homeland", "Background"]
		var temp: Array = []
		for perk: Perk in CampaignVariables.codex.Perks.values():
			if excluded.has(perk.category):
				continue
			if not temp.has(perk.category):
				temp.append(perk.category)
		return temp
	).call()

	if not categories.is_empty():
		grid.columns = categories.size()

	for category in categories:
		var title := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
		title.text = CampaignVariables.replaceText(category)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(title)

	for category in categories:
		var perks: Array[Perk] = (func() -> Array[Perk]:
			var result: Array[Perk] = []
			for perk: Perk in CampaignVariables.codex.Perks.values():
				if perk.category == category:
					result.append(perk)
			return result
		).call()
		var subGrid := GridContainer.new()
		subGrid.columns = 3
		subGrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(subGrid)
		for perk: Perk in perks:
			var _name := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
			_name.text = CampaignVariables.replaceText(perk._name)

			var description := CampaignVariables.prepareLabel(RichTextLabel.new(), true)
			description.text = CampaignVariables.replaceText(perk.long_description)
			description.custom_minimum_size = Vector2(100, 50)
			description.autowrap_mode = TextServer.AUTOWRAP_WORD
			description.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			var selectBtn := Button.new()
			selectBtn.text = "Select"
			selectBtn.pressed.connect(func() -> void:
				if points.value > 0 and not _item_exists(selected, perk._name):
					var idx := selected.add_item(perk._name)
					selected.set_item_metadata(idx, perk)
					selected.set_item_tooltip(idx, perk.short_description)
					_connect_selected_item_clicked()
					points.value -= 1
				)

			subGrid.add_child(_name)
			subGrid.add_child(description)
			subGrid.add_child(selectBtn)

func _connect_selected_item_clicked() -> void:
	if _selected_click_connected:
		return
	selected.item_clicked.connect(func(index: int, _pos: Vector2, _mbidx: int) -> void:
		selected.remove_item(index)
		points.value += 1
	)
	_selected_click_connected = true

func _item_exists(_iList: ItemList, _name: String) -> bool:
	for i in range(_iList.item_count):
		if _iList.get_item_text(i) == _name:
			return true
	return false

func _save() -> void:
	var perks: Array[Perk] = []
	for i in range(selected.item_count):
		perks.append(selected.get_item_metadata(i))
	PlayerVariables.setPerks(perks)
	PlayerVariables.setPerkPoints(int(points.value))
