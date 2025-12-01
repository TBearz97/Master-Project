extends Node

var db : SQLite
var keywords : Array[Dictionary]
var rule : Dictionary

func _ready():
	db = SQLite.new()
	keywords = db_fetch("SELECT * FROM Keyword ORDER BY LENGTH(keyword) DESC")
	getRules()

func db_fetch(sql: String) -> Array:
	db.path = "res://data/Codex.db"
	db.verbosity_level = 0
	db.open_db()

	db.query(sql)
	db.close_db()
	return db.query_result  # Array of Dictionaries

func prepareLabel(label : RichTextLabel, short : bool = true) -> RichTextLabel:
	label.bbcode_enabled = true
	label.fit_content = true
	label.meta_underlined = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.meta_hover_started.connect(_on_meta_hovered.bind(label))
	label.meta_hover_ended.connect(_on_meta_hovered_end.bind(label))
	label.meta_clicked.connect(_on_meta_clicked)
	if short :
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	else :
		label.scroll_active = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func replaceText(text : String, ignore : String = "")  -> String:
	for keyword in keywords :
		if keyword["keyword"] != ignore and text.contains(keyword["keyword"]) :
			var meta = encode_meta(keyword)
			text = text.replace(keyword["keyword"], '[url=' + meta + '][color=#EE4B2B]' + keyword["keyword"] + '[/color][/url]')
	return text

func _on_meta_clicked(meta):
	var data = decode_meta(meta)
	var _window = ConfirmationDialog.new()
	add_child(_window)
	_window.title = data["keyword"]
	var rtl = prepareLabel(RichTextLabel.new(), false)
	rtl.fit_content = false
	rtl.text = replaceText(data["long_description"], data["keyword"])
	_window.add_child(rtl)
	_window.get_cancel_button().visible = false
	_window.get_ok_button().visible = false
	_window.exclusive = false
	_window.size = Vector2 (300, 300)
	_window.popup()
	_window.position = get_viewport().get_mouse_position()

func _on_meta_hovered(meta, label : RichTextLabel) :
	var data = decode_meta(meta)
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.tooltip_text = data["short_description"]

@warning_ignore("unused_parameter")
func _on_meta_hovered_end(meta, label : RichTextLabel) :
	label.tooltip_text = ""

func getRules() :
	var rows = db_fetch("SELECT * FROM Rule")
	for row in rows :
		rule[row["name"]] = row["expression"] 
	
## =============== HELPERS =================
func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		c.queue_free()

func encode_meta(dict : Dictionary) :
	var json = JSON.stringify(dict)
	var bytes = json.to_utf8_buffer()
	var meta = Marshalls.raw_to_base64(bytes)
	return meta

func decode_meta(_str : String) :
	var bytes = Marshalls.base64_to_raw(_str)
	var json = bytes.get_string_from_utf8()
	var data = JSON.parse_string(json)
	return data
	

#Legacy Code
#
#signal perk_chosen(perk: Dictionary)
#signal item_chosen(perk: Dictionary)
## ============ CHARACTERISTICS ============
#func populate_option_button(ob: OptionButton, table_name: String, rt : RichTextLabel):
	#
	#var sql = "SELECT name, short_description, long_description FROM %s" % table_name
	#var rows = db_fetch(sql)
	#var popup = ob.get_popup()
	#ob.clear()
	#for row in rows:
		#var idx = popup.item_count
		#ob.add_item(row["name"])              # shows race name
		#popup.set_item_tooltip(idx, row["short_description"]) # hover tooltip
		#popup.set_item_metadata(idx, row)                     # store full row
	##_on_option_selected(0, ob, rt)
	#ob.select(-1)
	#ob.item_selected.connect(_on_option_selected.bind(ob, rt))
#
## ================ PERKS ==================
#func populate_perks_grid(grid: GridContainer) -> void:
	## 3 columns: Name | Long Description | Button
	#grid.columns = 3
#
	## Clear previous rows
	#for c in grid.get_children():
		#c.queue_free()
#
	## Fetch non-Race/Background perks
	#var rows = db_fetch("""
		#SELECT name, short_description, long_description
		#FROM Perks
		#WHERE category NOT IN ('Race', 'Background', 'Homeland')
	#""", )
#
	## Build UI
	#for r in rows:
		#var name_lbl := Label.new()
		#name_lbl.text = str(r["name"])
		#name_lbl.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
#
		#var desc_lbl := Label.new()
		#desc_lbl.text = str(r["long_description"])
		#desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		#desc_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#desc_lbl.custom_minimum_size = Vector2(300, 0)  # so it wraps nicely
#
		#var btn := Button.new()
		#btn.text = "Select"
		#btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		#btn.pressed.connect(func():
			#emit_signal("perk_chosen", r)  # r contains name/short/long
		#)
#
		#grid.add_child(name_lbl)
		#grid.add_child(desc_lbl)
		#grid.add_child(btn)
#
## =============== WEAPONS =================
#func populate_weapons_grid(grid: GridContainer) -> void:
	## Columns: Name | Size | Range | Qualities | Weight | Cost | Select
	#grid.columns = 7
	#_clear_grid(grid)
#
	#var sql := """
		#SELECT item AS name, size, COALESCE("range",'') AS range,
			   #COALESCE(qualities,'') AS qualities, weight, cost
		#FROM Weapon
		#WHERE cost != 0
	#"""
	#var rows = db_fetch(sql)
	#
	#grid.add_child(_mk_label("Name"))
	#grid.add_child(_mk_label("Size"))
	#grid.add_child(_mk_label("Range"))
	#grid.add_child(_mk_label("Qualities"))
	#grid.add_child(_mk_label("Weight"))
	#grid.add_child(_mk_label("Cost"))
	#grid.add_child(_mk_label("Select"))
	#
	#for r in rows:
		#var _name := str(r["name"])
		#var size := str(r["size"])
		#var rng  := str(r["range"])
		#var quals := str(r["qualities"])
		#var weight = r["weight"]
		#var cost = r["cost"]
#
		#grid.add_child(_mk_label(_name))
		#grid.add_child(_mk_label(size))
		#grid.add_child(_mk_label(rng))
		#grid.add_child(_mk_label(quals, true))
		#grid.add_child(_mk_label(str(weight)))
		#grid.add_child(_mk_label(str(cost)))
#
		#var btn := Button.new()
		#btn.text = "Select"
		#btn.pressed.connect(func():
			#emit_signal("item_chosen", r)
		#)
		#grid.add_child(btn)
#
## =============== ARMOR ===================
#func populate_armor_grid(grid: GridContainer) -> void:
	## Columns: Name | Type | Phys DT | Mag DT | Necro DT | Weight | Cost | Select
	#grid.columns = 8
	#_clear_grid(grid)
#
	#var sql := """
		#SELECT item AS name,
			   #armor_type,
			   #physical_dt,
			   #magical_dt,
			   #COALESCE(necrotic_dt, 0) AS necrotic_dt,
			   #weight,
			   #cost
		#FROM Armor
	#"""
	#var rows = db_fetch(sql)
#
	#grid.add_child(_mk_label("Name"))
	#grid.add_child(_mk_label("Type"))
	#grid.add_child(_mk_label("Phys DT"))
	#grid.add_child(_mk_label("Mag DT"))
	#grid.add_child(_mk_label("Necro DT"))
	#grid.add_child(_mk_label("Weight"))
	#grid.add_child(_mk_label("Cost"))
	#grid.add_child(_mk_label("Select"))
#
	#for r in rows:
		#var _name := str(r["name"])
		#var typ  := str(r["armor_type"])
		#var pdt  := int(r["physical_dt"])
		#var mdt  := int(r["magical_dt"])
		#var ndt  := int(r["necrotic_dt"])
		#var weight = r["weight"]
		#var cost   = r["cost"]
#
		#grid.add_child(_mk_label(_name))
		#grid.add_child(_mk_label(typ))
#
		#var phys_lbl := _mk_label(str(pdt))
		#phys_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#grid.add_child(phys_lbl)
#
		#var mag_lbl := _mk_label(str(mdt))
		#mag_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#grid.add_child(mag_lbl)
#
		#var nec_lbl := _mk_label(str(ndt))
		#nec_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#grid.add_child(nec_lbl)
#
		#var w_lbl := _mk_label(str(weight))
		#w_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#grid.add_child(w_lbl)
#
		#var c_lbl := _mk_label(str(cost))
		#c_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		#grid.add_child(c_lbl)
#
		#var btn := Button.new()
		#btn.text = "Select"
		#btn.size_flags_horizontal = Control.SIZE_SHRINK_END
		#btn.pressed.connect(func():
			#emit_signal("item_chosen", r)
		#)
		#grid.add_child(btn)
#
## =============== CLOTHING ================
#func populate_clothing_grid(grid: GridContainer) -> void:
	## Columns: Item | Locations | Weight | Cost | Select
	#grid.columns = 5
	#_clear_grid(grid)
#
	#var sql := """
		#SELECT item AS name, locations_covered, weight, cost
		#FROM Clothing
		#ORDER BY type
	#"""
	#var rows = db_fetch(sql)
#
	#grid.add_child(_mk_label("Name"))
	#grid.add_child(_mk_label("Location"))
	#grid.add_child(_mk_label("Weight"))
	#grid.add_child(_mk_label("Cost"))
	#grid.add_child(_mk_label("Select"))
	#
	#for r in rows:
		#var _name := str(r["name"])
		#var locs := str(r["locations_covered"])
		#var weight = r["weight"]
		#var cost = r["cost"]
#
		#grid.add_child(_mk_label(_name))
		#grid.add_child(_mk_label(locs, true))
		#grid.add_child(_mk_label(str(weight)))
		#grid.add_child(_mk_label(str(cost)))
#
		#var btn := Button.new()
		#btn.text = "Select"
		#btn.pressed.connect(func():
			#emit_signal("item_chosen", r)
		#)
		#grid.add_child(btn)
#
## =============== CONSUMABLES =============
#func populate_consumables_grid(grid: GridContainer) -> void:
	## Columns: Item | Type | HP | Duration | Effect | Weight | Cost | Select
	#grid.columns = 8
	#_clear_grid(grid)
#
	#var sql := """
		#SELECT item AS name, type, COALESCE(hp_healed,0) AS hp,
			   #COALESCE(duration,'') AS duration, COALESCE(effect,'') AS effect,
			   #weight, cost, COALESCE(alcoholic,0) AS alcoholic,
			   #addiction_threshold
		#FROM Consumable
		#ORDER BY type
	#"""
	#var rows = db_fetch(sql)
#
#
	#grid.add_child(_mk_label("Name"))
	#grid.add_child(_mk_label("Type"))
	#grid.add_child(_mk_label("Health Restored"))
	#grid.add_child(_mk_label("Duration"))
	#grid.add_child(_mk_label("Effect"))
	#grid.add_child(_mk_label("Weight"))
	#grid.add_child(_mk_label("Cost"))
	#grid.add_child(_mk_label("Select"))
#
	#for r in rows:
		#var _name := str(r["name"])
		#var typ  := str(r["type"])
		#var hp   := int(r["hp"])
		#var dur  := str(r["duration"])
		#var eff  := str(r["effect"])
		#var weight = r["weight"]
		#var cost = r["cost"]
#
		#grid.add_child(_mk_label(_name))
		#grid.add_child(_mk_label(typ))
		#grid.add_child(_mk_label(str(hp)))
		#grid.add_child(_mk_label(dur))
		#grid.add_child(_mk_label(eff, true))
		#grid.add_child(_mk_label(str(weight)))
		#grid.add_child(_mk_label(str(cost)))
#
		#var btn := Button.new()
		#btn.text = "Select"
		#btn.pressed.connect(func():
			#emit_signal("item_chosen", r)
		#)
		#grid.add_child(btn)
#
## =============== UTILITY =================
#func populate_utility_grid(grid: GridContainer) -> void:
	## Columns: Item | Category | Effect | Weight | Cost | Select
	#grid.columns = 6
	#_clear_grid(grid)
#
	#var sql := """
		#SELECT item AS name, category, COALESCE(effect,'') AS effect, weight, cost
		#FROM UtilityItem
		#ORDER BY category
	#"""
	#var rows = db_fetch(sql)
#
#
	#grid.add_child(_mk_label("Name"))
	#grid.add_child(_mk_label("Catagory"))
	#grid.add_child(_mk_label("Effect"))
	#grid.add_child(_mk_label("Weight"))
	#grid.add_child(_mk_label("Cost"))
	#grid.add_child(_mk_label("Select"))
#
	#for r in rows:
		#var _name := str(r["name"])
		#var cat  := str(r["category"])
		#var eff  := str(r["effect"])
		#var weight = r["weight"]
		#var cost = r["cost"]
#
		#grid.add_child(_mk_label(_name))
		#grid.add_child(_mk_label(cat))
		#grid.add_child(_mk_label(eff, true))
		#grid.add_child(_mk_label(str(weight)))
		#grid.add_child(_mk_label(str(cost)))
#
		#var btn := Button.new()
		#btn.text = "Select"
		#btn.pressed.connect(func():
			#emit_signal("item_chosen", r)
		#)
		#grid.add_child(btn)
#
### =============== HELPERS =================
#func _clear_grid(grid: GridContainer) -> void:
	#for c in grid.get_children():
		#c.queue_free()

#func _mk_label(txt: String, expand := false) -> Label:
	#var lbl := Label.new()
	#lbl.text = txt
	#lbl.autowrap_mode = TextServer.AUTOWRAP_OFF
	#lbl.size_flags_horizontal = (Control.SIZE_EXPAND | Control.SIZE_FILL) if expand else Control.SIZE_SHRINK_CENTER
	##lbl.custom_minimum_size = Vector2(100, 100)
	#return lbl
#
#func _on_option_selected(index: int, ob: OptionButton, rt : RichTextLabel):
	#var popup = ob.get_popup()
	#var row = popup.get_item_metadata(index)
	#rt.clear()
	#rt.add_text(row["long_description"])
