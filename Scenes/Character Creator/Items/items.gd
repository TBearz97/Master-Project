extends VBoxContainer

@export var points : SpinBox
@export var selected : ItemList
@export var grid : GridContainer

var inventory = PlayerVariables.getInventory()

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
			var meta = getItemMeta(item, type["type"])
			item.erase("ID")
			var _name = DbHelper.prepareLabel(RichTextLabel.new(), true)
			_name.text = item["item"]
			_name.mouse_filter = Control.MOUSE_FILTER_PASS
			_name.gui_input.connect(_on_Label_gui_input.bind(meta))
			
			var weight = DbHelper.prepareLabel(RichTextLabel.new(), true)
			weight.text = str(item["weight"])
			
			var cost = DbHelper.prepareLabel(RichTextLabel.new(), true)
			cost.text = str(item["cost"])
			
			var selectBtn = Button.new()
			selectBtn.text = "Select"
			selectBtn.pressed.connect(_on_item_chosen.bind(meta))
			
			subGrid.add_child(_name)
			subGrid.add_child(weight)
			subGrid.add_child(cost)
			subGrid.add_child(selectBtn)

func getItemMeta(item : Dictionary, type : String) :
	match type:
		"Weapon" : return Weapon.new(item["item"], item["weight"], item["cost"], item["damage_multiplier"], item["base_speed"], str(item["qualities"]), str(item["size"]), str(item["range"]))
		"Armor" : return Armor.new(item["item"], item["weight"],  item["cost"], item["armor_slot"], item["physical_dt"], item["magical_dt"], item["necrotic_dt"])
		"Clothing" : return Clothing.new(item["item"], item["weight"], item["cost"], item["locations_covered"], 0, 0, 0, "")
		"Consumable" : return Consumable.new(item["item"], item["weight"], item["hp_healed"], str(item["effect"]), item["addiction_threshold"] if item["addiction_threshold"] != null else  0 ,  item["cost"])
		"Utility" : return Utility.new(item["item"], item["weight"], item["effect"],  item["cost"])


func _on_item_chosen(obj : Item) -> void:
	if points.value - obj.value >= 0:
		if !inventory.has(obj) :
			inventory[obj] = 1
			var idx = selected.add_item(str(obj._name) + " x" + str(inventory[obj]))
			selected.set_item_metadata(idx, obj)
			selected.set_item_tooltip(idx, obj._print())
		else :
			inventory[obj] = inventory[obj] + 1
			for i in range(selected.item_count) :
				var parts = selected.get_item_text(i).split(" x")
				if parts[0] == obj._name :
					selected.set_item_text(i, str(obj._name) + " x" + str(inventory[obj]))
		
		points.value -= obj.value
	
func _on_selected(index: int) -> void:
	var item = selected.get_item_metadata(index)
	if inventory.has(item) :
		inventory[item] = inventory[item] - 1
		if inventory[item] == 0 :
			inventory.erase(item)
			selected.remove_item(index)
		else :
			selected.set_item_text(index, str(item._name) + " x" + str(inventory[item]))
			selected.deselect(index)
		points.value += item.value

func _on_Label_gui_input(event: InputEvent, item : Item):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var _window = ConfirmationDialog.new()
			add_child(_window)
			_window.title = item._name
			_window.get_label().text = item._print()
			_window.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD
			_window.get_cancel_button().visible = false
			_window.get_ok_button().visible = false
			_window.popup()
			_window.position = get_viewport().get_mouse_position()
			_window.focus_exited.connect(func ():
				_window.hide())

func _item_exists(_iList : ItemList, _name : String) -> bool :
	for i in range(_iList.item_count) :
		if _iList.get_item_text(i) == _name:
			return true
	return false

#Consider just saving the entire ItemList instead as it can be reused
func _save ():
	PlayerVariables.setInventory(inventory)
	PlayerVariables.setMoney(int(points.value))
