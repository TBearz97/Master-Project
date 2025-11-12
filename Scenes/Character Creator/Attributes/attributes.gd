extends VBoxContainer

@export var grid : GridContainer
@export var points : SpinBox
@export var _max : int

var attributes : Dictionary[String, int] = {}
var spinBoxes : Array[SpinBox] = []
var prev = {}

func _ready() -> void:
	visibility_changed.connect(_save)
	_setup()

func _setup () :
	points.value = PlayerVariables.attribute_points
	var _attributes = DbHelper.db_fetch("SELECT * FROM Attribute")
	
	for rows in _attributes :
		#--- Label ---
		var label = Label.new()
		label.text = rows["name"]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.mouse_filter = Control.MOUSE_FILTER_PASS
		label.tooltip_text = rows["short_description"]
		label.gui_input.connect(_on_Label_gui_input.bind(rows["name"], rows["long_description"]))
		
		#--- Bonuses ---
		var bonus1 = Label.new()
		bonus1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus1.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var bonus2 = Label.new()
		bonus2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonus2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		#--- SpinBox ---
		var sb = SpinBox.new()
		spinBoxes.append(sb)
		sb.tooltip_text = rows["name"]
		sb.alignment = HORIZONTAL_ALIGNMENT_CENTER
		sb.min_value = 1
		sb.max_value = _max
		if PlayerVariables.attributes.has(rows["name"]) :
			sb.value = PlayerVariables.attributes[rows["name"]]
		sb.rounded = true
		sb.step = 1
		prev[sb] = 1
		sb.value_changed.connect(_on_value_changed.bind(bonus1, bonus2, rows, sb))
		_on_value_changed(1, bonus1, bonus2, rows, sb)
		
		#--- Grid Setup
		grid.columns = 4
		grid.add_child(label)
		grid.add_child(sb)
		grid.add_child(bonus1)
		grid.add_child(bonus2)

func _save () :
	for sb in spinBoxes :
		attributes[sb.tooltip_text] = int(sb.value)
	PlayerVariables.attributes = attributes
	PlayerVariables.attribute_points = int(points.value)

# ---- Helpers ----
func _on_value_changed(new_value: int, bonus1 : Label, bonus2 : Label, rows : Dictionary, sb : SpinBox) -> void:
	bonus1.text = rows["bonus_1_prefix"] + " " + str(Expressions.evaluate(rows["bonus_1_expression"], ["x"], [new_value])) + " " + rows["bonus_1_suffix"]
	bonus2.text = rows["bonus_2_prefix"] + " " + str(Expressions.evaluate(rows["bonus_2_expression"], ["x"], [new_value])) +  " " + rows["bonus_2_suffix"]
	
	if new_value > prev[sb] :
		points.value -= 1
	elif new_value < prev[sb] :
		points.value += 1
	
	prev[sb] = new_value
	
	if points.value == 0 :
		for key in prev :
			key.max_value = key.value
	else : 
		for key in prev :
			key.max_value = _max

func _on_Label_gui_input(event: InputEvent, attribute : String, description : String):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var _window = ConfirmationDialog.new()
			add_child(_window)
			_window.title = attribute
			_window.get_label().text = description
			_window.get_label().autowrap_mode = TextServer.AUTOWRAP_WORD
			_window.get_cancel_button().visible = false
			_window.get_ok_button().visible = false
			_window.popup_centered()
			_window.focus_exited.connect(func ():
				_window.hide())
