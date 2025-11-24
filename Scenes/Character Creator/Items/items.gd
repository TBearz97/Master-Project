extends VBoxContainer

@export var points : SpinBox
@export var selected : ItemList
@export var grid : GridContainer

var inventory : Dictionary

func _ready() -> void:
	_setup()
	visibility_changed.connect(_save)


func _setup():
	selected.item_selected.connect(_on_selected)
	var types =  DbHelper.db_fetch("SELECT DISTINCT type FROM Item")
	if not types.is_empty() :
		grid.columns = types.size()
	
	for type in types :
		var title = DbHelper.prepareLabel(RichTextLabel.new(), true)
		title.text = DbHelper.replaceText(type["type"]) 
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		grid.add_child(title)
	
	for type in types :
		var items = DbHelper.db_fetch("SELECT * FROM '%s'" % type["type"])
		var subGrid = GridContainer.new()
		subGrid.columns = 4
		subGrid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lb1 = Label.new()
		var lb2 = Label.new()
		var lb3 = Label.new()
		var lb4 = Label.new()
		lb1.text = "Name"
		lb2.text = "Weight"
		lb3.text = "Cost"
		lb4.text = ""
		
		subGrid.add_child(lb1)
		subGrid.add_child(lb2)
		subGrid.add_child(lb3)
		subGrid.add_child(lb4)
		grid.add_child(subGrid)
		for item in items :
			item.erase("ID")
			var _name = DbHelper.prepareLabel(RichTextLabel.new(), true)
			_name.text = item["item"]
			_name.mouse_filter = Control.MOUSE_FILTER_PASS
			_name.tooltip_text = _dicToStr(item)
			_name.gui_input.connect(_on_Label_gui_input.bind(item))
			
			var weight = DbHelper.prepareLabel(RichTextLabel.new(), true)
			weight.text = str(item["weight"])
			
			var cost = DbHelper.prepareLabel(RichTextLabel.new(), true)
			cost.text = str(item["cost"])
			
			var selectBtn = Button.new()
			selectBtn.text = "Select"
			selectBtn.pressed.connect(_on_item_chosen.bind(item))
			
			subGrid.add_child(_name)
			subGrid.add_child(weight)
			subGrid.add_child(cost)
			subGrid.add_child(selectBtn)


func _on_item_chosen(item: Dictionary) -> void:
	if points.value - item["cost"] >= 0:
		if !inventory.has(item) :
			inventory[item] = 1
			var idx = selected.add_item(str(item["item"]) + " x" + str(inventory[item]))
			selected.set_item_metadata(idx, item)
			selected.set_item_tooltip(idx, _dicToStr(item))
		else :
			inventory[item] = inventory[item] + 1
			for i in range(selected.item_count) :
				var parts = selected.get_item_text(i).split(" x")
				if parts[0] == item["item"] :
					selected.set_item_text(i, str(item["item"]) + " x" + str(inventory[item]))
		
		points.value -= item["cost"]
	
func _on_selected(index: int) -> void:
	var item = selected.get_item_metadata(index)
	if inventory.has(item) :
		inventory[item] = inventory[item] - 1
		if inventory[item] == 0 :
			inventory.erase(item)
			selected.remove_item(index)
		else :
			selected.set_item_text(index, str(item["item"]) + " x" + str(inventory[item]))
			selected.deselect(index)
		points.value += item["cost"]
	

func _on_Label_gui_input(event: InputEvent, item : Dictionary):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var _window = ConfirmationDialog.new()
			add_child(_window)
			_window.title = item["item"]
			_window.get_label().text = _dicToStr(item)
			_window.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD
			_window.get_cancel_button().visible = false
			_window.get_ok_button().visible = false
			_window.popup()
			_window.position = get_viewport().get_mouse_position()
			_window.focus_exited.connect(func ():
				_window.hide())

func _dicToStr (dict : Dictionary) -> String :
	var output = ""
	for key in dict :
		output = output + str(key) + ": " + str(dict[key]) + "\n"
	return output

func _item_exists(_iList : ItemList, _name : String) -> bool :
	for i in range(_iList.item_count) :
		if _iList.get_item_text(i) == _name:
			return true
	return false

func _save ():
	PlayerVariables.inventory = inventory
	PlayerVariables.money = int(points.value)
