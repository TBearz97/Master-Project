extends Node
class_name DBHelper

var db : SQLite

@export var attributes_text : Array[Label]
@export var skills_text : Array[Label]
@export var perkGrid : GridContainer

@onready var race_ob : OptionButton = %RaceOptions
@onready var race_text : RichTextLabel = %RaceText

@onready var homeland_ob : OptionButton = %HomelandOptions
@onready var homeland_text : RichTextLabel = %HomelandText

@onready var background_ob : OptionButton = %BackgroundOptions
@onready var background_text : RichTextLabel = %BackgroundText

func _ready():
	db = SQLite.new()
	db.path = "res://data/Codex.db"
	db.open_db()
	race_ob.item_selected.connect(_on_option_selected.bind(race_ob, race_text))
	homeland_ob.item_selected.connect(_on_option_selected.bind(homeland_ob, homeland_text))
	background_ob.item_selected.connect(_on_option_selected.bind(background_ob, background_text))
	populate_option_button(race_ob, "Race")
	populate_option_button(homeland_ob, "Homelands")
	populate_option_button(background_ob, "Backgrounds")
	add_tooltip("Attributes", attributes_text)
	add_tooltip("Skills", skills_text)
	populate_perks_grid(perkGrid)

func fetch_table_options(table_name: String) -> Array:
	var sql = "SELECT name, short_description, long_description FROM %s" % table_name

	db.query(sql)
	return db.query_result  # Array of Dictionaries

func populate_option_button(ob: OptionButton, table_name: String):
	var rows = fetch_table_options(table_name)
	var popup = ob.get_popup()
	ob.clear()
	for row in rows:
		var idx = popup.item_count
		ob.add_item(row["name"])              # shows race name
		popup.set_item_tooltip(idx, row["short_description"]) # hover tooltip
		popup.set_item_metadata(idx, row)                     # store full row
	#_on_option_selected(0, ob, rt)
	ob.select(-1)

func _on_option_selected(index: int, ob: OptionButton, rt : RichTextLabel):
	var popup = ob.get_popup()
	var row = popup.get_item_metadata(index)
	rt.clear()
	rt.add_text(row["long_description"])
	
func add_tooltip(string: String, labels: Array) -> void:
	var sql = fetch_table_options(string)
	for i in sql:
		for j in labels:
			if i["name"] == j.name:
				j.tooltip_text = i["short_description"]
				j.mouse_filter = Control.MOUSE_FILTER_STOP

signal perk_chosen(perk: Dictionary)  # Emitted when a perk's button is pressed

func populate_perks_grid(grid: GridContainer) -> void:
	# 3 columns: Name | Long Description | Button
	grid.columns = 3

	# Clear previous rows
	for c in grid.get_children():
		c.queue_free()

	# Fetch non-Race/Background perks
	var sql := """
		SELECT name, short_description, long_description
		FROM Perks
		WHERE category NOT IN ('Race', 'Background', 'Homeland')
	"""
	db.query(sql)
	var rows: Array =  db.query_result # <-- replace with your DB function

	# Build UI
	for r in rows:
		var name_lbl := Label.new()
		name_lbl.text = str(r["name"])
		name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN

		var desc_lbl := Label.new()
		desc_lbl.text = str(r["long_description"])
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc_lbl.custom_minimum_size = Vector2(300, 0)  # so it wraps nicely

		var btn := Button.new()
		btn.text = "Select"
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.pressed.connect(func():
			emit_signal("perk_chosen", r)  # r contains name/short/long
		)

		grid.add_child(name_lbl)
		grid.add_child(desc_lbl)
		grid.add_child(btn)
