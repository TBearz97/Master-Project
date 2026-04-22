extends VBoxContainer

@export var points: SpinBox
@export var selected: ItemList
@export var grid: GridContainer

var _selected_click_connected: bool = false

func _ready() -> void:
	_setup()
	visibility_changed.connect(_save)
	visibility_changed.connect(_refresh_selected_perks)
	_refresh_selected_perks()
	_connect_selected_item_clicked()

func _setup() -> void:
	points.value = PlayerVariables.current().perk_points
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
					_add_selected_perk(perk, false)
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
		var entry_metadata: Variant = selected.get_item_metadata(index)
		if entry_metadata is Dictionary and bool((entry_metadata as Dictionary).get("locked", false)):
			return
		selected.remove_item(index)
		points.value += 1
	)
	_selected_click_connected = true

func _item_exists(_iList: ItemList, _name: String) -> bool:
	for i in range(_iList.item_count):
		var entry_metadata: Variant = _iList.get_item_metadata(i)
		if entry_metadata is Dictionary:
			var perk := (entry_metadata as Dictionary).get("perk", null) as Perk
			if perk != null and perk._name == _name:
				return true
		elif _iList.get_item_text(i) == _name:
			return true
	return false

func _save() -> void:
	var perks: Array[Perk] = []
	for i in range(selected.item_count):
		var entry_metadata: Variant = selected.get_item_metadata(i)
		if entry_metadata is Dictionary:
			var entry := entry_metadata as Dictionary
			if bool(entry.get("locked", false)):
				continue
			var perk := entry.get("perk", null) as Perk
			if perk != null:
				perks.append(perk)
		elif entry_metadata is Perk:
			perks.append(entry_metadata)
	PlayerVariables.setPerks(perks)
	PlayerVariables.setPerkPoints(int(points.value))

func _refresh_selected_perks() -> void:
	selected.clear()
	for perk: Perk in PlayerVariables.getOriginPerks():
		_add_selected_perk(perk, true)
	for perk: Perk in PlayerVariables.getPerks():
		_add_selected_perk(perk, false)

func _add_selected_perk(perk: Perk, locked: bool) -> void:
	if perk == null or _item_exists(selected, perk._name):
		return
	var label := perk._name
	if locked:
		label = "%s [Origin]" % perk._name
	var idx := selected.add_item(label)
	selected.set_item_metadata(idx, {
		"perk": perk,
		"locked": locked,
	})
	selected.set_item_tooltip(idx, perk.short_description)
	selected.set_item_disabled(idx, locked)
