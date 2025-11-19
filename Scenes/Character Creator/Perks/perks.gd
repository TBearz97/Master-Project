extends VBoxContainer

@export var points : SpinBox
@export var selected : ItemList
@export var grid : GridContainer

func _ready() -> void:
	_setup()
	visibility_changed.connect(_save)

func _setup ():
	points.value = PlayerVariables.perk_points
	var categories = DbHelper.db_fetch("SELECT DISTINCT category FROM Perk WHERE category NOT IN ('Race', 'Homeland', 'Background')")
	if not categories.is_empty() :
		grid.columns = categories.size()
	
	for category in categories :
		var title = DbHelper.prepareLabel(RichTextLabel.new(), true)
		title.text = DbHelper.replaceText(category["category"])
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(title)
		
	for category in categories :
		var perks = DbHelper.db_fetch("SELECT * FROM Perk WHERE category = '%s'" % category["category"])
		var subGrid = GridContainer.new()
		subGrid.columns = 3
		subGrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(subGrid)
		for perk in perks :
			var _name = DbHelper.prepareLabel(RichTextLabel.new(), true)
			_name.text = DbHelper.replaceText(perk["name"]) 
			
			var description = DbHelper.prepareLabel(RichTextLabel.new(), false)
			description.text = DbHelper.replaceText(perk["long_description"]) 
			description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			
			var selectBtn = Button.new()
			selectBtn.text = "Select"
			selectBtn.pressed.connect(func ():
				if points.value > 0 and !_item_exists(selected, perk["name"]) :
					var idx = selected.add_item(perk["name"])
					selected.set_item_metadata(idx, perk)
					selected.set_item_tooltip(idx, perk["short_description"])
					selected.item_clicked.connect(func (index, _pos, _mbidx):
						selected.remove_item(index)
						points.value += 1
						)
					points.value -= 1
				)
			
			subGrid.add_child(_name)
			subGrid.add_child(description)
			subGrid.add_child(selectBtn)
		

func _item_exists(_iList : ItemList, _name : String) -> bool :
	for i in range(_iList.item_count) :
		if _iList.get_item_text(i) == _name:
			return true
	return false

func _save () :
	var perks = []
	for i in range(selected.item_count) :
		perks.append(selected.get_item_metadata(i))
	PlayerVariables.perks = perks
	PlayerVariables.perk_points = int(points.value)
