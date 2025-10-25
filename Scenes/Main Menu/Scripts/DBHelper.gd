extends Node
class_name DBHelper

var db : SQLite

@export var attributes_text : Array[Label]
@export var skills_text : Array[Label]
@export var perkGrid : GridContainer
@export var grid_weapons : GridContainer
@export var grid_armor : GridContainer
@export var grid_clothing : GridContainer
@export var grid_consumables : GridContainer
@export var grid_utility : GridContainer

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
	populate_weapons_grid(grid_weapons)
	populate_armor_grid(grid_armor)
	populate_clothing_grid(grid_clothing)
	populate_consumables_grid(grid_consumables)
	populate_utility_grid(grid_utility)

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

# Helpers
func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		c.queue_free()

func _mk_label(txt: String, expand := false) -> Label:
	var lbl := Label.new()
	lbl.text = txt
	lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	lbl.size_flags_horizontal = (Control.SIZE_EXPAND | Control.SIZE_FILL) if expand else Control.SIZE_SHRINK_CENTER
	#lbl.custom_minimum_size = Vector2(100, 100)
	return lbl
	
signal item_chosen(perk: Dictionary)

# =============== WEAPONS =================
func populate_weapons_grid(grid: GridContainer) -> void:
	# Columns: Name | Size | Range | Qualities | Weight | Cost | Select
	grid.columns = 7
	_clear_grid(grid)

	var sql := """
		SELECT weapon AS name, size, COALESCE("range",'') AS range,
			   COALESCE(qualities,'') AS qualities, weight, cost
		FROM Weapons
		WHERE cost != 0
	"""
	db.query(sql)
	var rows: Array = db.query_result
	
	grid.add_child(_mk_label("Name"))
	grid.add_child(_mk_label("Size"))
	grid.add_child(_mk_label("Range"))
	grid.add_child(_mk_label("Qualities"))
	grid.add_child(_mk_label("Weight"))
	grid.add_child(_mk_label("Cost"))
	grid.add_child(_mk_label("Select"))
	
	for r in rows:
		var _name := str(r["name"])
		var size := str(r["size"])
		var rng  := str(r["range"])
		var quals := str(r["qualities"])
		var weight = r["weight"]
		var cost = r["cost"]

		grid.add_child(_mk_label(_name))
		grid.add_child(_mk_label(size))
		grid.add_child(_mk_label(rng))
		grid.add_child(_mk_label(quals, true))
		grid.add_child(_mk_label(str(weight)))
		grid.add_child(_mk_label(str(cost)))

		var btn := Button.new()
		btn.text = "Select"
		btn.pressed.connect(func():
			emit_signal("item_chosen", r)
		)
		grid.add_child(btn)

# =============== ARMOR ===================
func populate_armor_grid(grid: GridContainer) -> void:
	# Columns: Name | Type | Phys DT | Mag DT | Necro DT | Weight | Cost | Select
	grid.columns = 8
	_clear_grid(grid)

	var sql := """
		SELECT item AS name,
		       armor_type,
		       physical_dt,
		       magical_dt,
		       COALESCE(necrotic_dt, 0) AS necrotic_dt,
		       weight,
		       cost
		FROM Armor
	"""
	db.query(sql)
	var rows: Array = db.query_result

	grid.add_child(_mk_label("Name"))
	grid.add_child(_mk_label("Type"))
	grid.add_child(_mk_label("Phys DT"))
	grid.add_child(_mk_label("Mag DT"))
	grid.add_child(_mk_label("Necro DT"))
	grid.add_child(_mk_label("Weight"))
	grid.add_child(_mk_label("Cost"))
	grid.add_child(_mk_label("Select"))

	for r in rows:
		var _name := str(r["name"])
		var typ  := str(r["armor_type"])
		var pdt  := int(r["physical_dt"])
		var mdt  := int(r["magical_dt"])
		var ndt  := int(r["necrotic_dt"])
		var weight = r["weight"]
		var cost   = r["cost"]

		grid.add_child(_mk_label(_name))
		grid.add_child(_mk_label(typ))

		var phys_lbl := _mk_label(str(pdt))
		phys_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(phys_lbl)

		var mag_lbl := _mk_label(str(mdt))
		mag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(mag_lbl)

		var nec_lbl := _mk_label(str(ndt))
		nec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(nec_lbl)

		var w_lbl := _mk_label(str(weight))
		w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(w_lbl)

		var c_lbl := _mk_label(str(cost))
		c_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		grid.add_child(c_lbl)

		var btn := Button.new()
		btn.text = "Select"
		btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		btn.pressed.connect(func():
			emit_signal("item_chosen", r)
		)
		grid.add_child(btn)


# =============== CLOTHING ================
func populate_clothing_grid(grid: GridContainer) -> void:
	# Columns: Item | Locations | Weight | Cost | Select
	grid.columns = 5
	_clear_grid(grid)

	var sql := """
		SELECT item AS name, locations_covered, weight, cost
		FROM Clothing
		ORDER BY type
	"""
	db.query(sql)
	var rows: Array = db.query_result

	grid.add_child(_mk_label("Name"))
	grid.add_child(_mk_label("Location"))
	grid.add_child(_mk_label("Weight"))
	grid.add_child(_mk_label("Cost"))
	grid.add_child(_mk_label("Select"))
	
	for r in rows:
		var _name := str(r["name"])
		var locs := str(r["locations_covered"])
		var weight = r["weight"]
		var cost = r["cost"]

		grid.add_child(_mk_label(_name))
		grid.add_child(_mk_label(locs, true))
		grid.add_child(_mk_label(str(weight)))
		grid.add_child(_mk_label(str(cost)))

		var btn := Button.new()
		btn.text = "Select"
		btn.pressed.connect(func():
			emit_signal("item_chosen", r)
		)
		grid.add_child(btn)

# =============== CONSUMABLES =============
func populate_consumables_grid(grid: GridContainer) -> void:
	# Columns: Item | Type | HP | Duration | Effect | Weight | Cost | Select
	grid.columns = 8
	_clear_grid(grid)

	var sql := """
		SELECT item AS name, type, COALESCE(hp_healed,0) AS hp,
			   COALESCE(duration,'') AS duration, COALESCE(effect,'') AS effect,
		       weight, cost, COALESCE(alcoholic,0) AS alcoholic,
		       addiction_threshold
		FROM Consumables
		ORDER BY type
	"""
	db.query(sql)
	var rows: Array = db.query_result


	grid.add_child(_mk_label("Name"))
	grid.add_child(_mk_label("Type"))
	grid.add_child(_mk_label("Health Restored"))
	grid.add_child(_mk_label("Duration"))
	grid.add_child(_mk_label("Effect"))
	grid.add_child(_mk_label("Weight"))
	grid.add_child(_mk_label("Cost"))
	grid.add_child(_mk_label("Select"))

	for r in rows:
		var _name := str(r["name"])
		var typ  := str(r["type"])
		var hp   := int(r["hp"])
		var dur  := str(r["duration"])
		var eff  := str(r["effect"])
		var weight = r["weight"]
		var cost = r["cost"]

		grid.add_child(_mk_label(_name))
		grid.add_child(_mk_label(typ))
		grid.add_child(_mk_label(str(hp)))
		grid.add_child(_mk_label(dur))
		grid.add_child(_mk_label(eff, true))
		grid.add_child(_mk_label(str(weight)))
		grid.add_child(_mk_label(str(cost)))

		var btn := Button.new()
		btn.text = "Select"
		btn.pressed.connect(func():
			emit_signal("item_chosen", r)
		)
		grid.add_child(btn)

# =============== UTILITY =================
func populate_utility_grid(grid: GridContainer) -> void:
	# Columns: Item | Category | Effect | Weight | Cost | Select
	grid.columns = 6
	_clear_grid(grid)

	var sql := """
		SELECT item AS name, category, COALESCE(effect,'') AS effect, weight, cost
		FROM UtilityItems
		ORDER BY category
	"""
	db.query(sql)
	var rows: Array = db.query_result


	grid.add_child(_mk_label("Name"))
	grid.add_child(_mk_label("Catagory"))
	grid.add_child(_mk_label("Effect"))
	grid.add_child(_mk_label("Weight"))
	grid.add_child(_mk_label("Cost"))
	grid.add_child(_mk_label("Select"))

	for r in rows:
		var _name := str(r["name"])
		var cat  := str(r["category"])
		var eff  := str(r["effect"])
		var weight = r["weight"]
		var cost = r["cost"]

		grid.add_child(_mk_label(_name))
		grid.add_child(_mk_label(cat))
		grid.add_child(_mk_label(eff, true))
		grid.add_child(_mk_label(str(weight)))
		grid.add_child(_mk_label(str(cost)))

		var btn := Button.new()
		btn.text = "Select"
		btn.pressed.connect(func():
			emit_signal("item_chosen", r)
		)
		grid.add_child(btn)
