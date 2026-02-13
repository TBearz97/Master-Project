extends Node

var data: CampaignData
var codex : Codex

func _ready() -> void:
	data = CampaignData.new()
	codex = ResourceLoader.load("res://data/baseRules.res")
	codex.createKeywords()

# Campaign Info
func setCampaignName(value: String) -> void:
	data.campaign_name = value

func getCampaignName() -> String:
	return data.campaign_name

func setCampaignDescription(value: String) -> void:
	data.campaign_description = value

func getCampaignDescription() -> String:
	return data.campaign_description

# Players
func setPlayersData(value: Array[PlayerData]) -> void:
	data.playersData = value

func getPlayersData() -> Array[PlayerData]:
	return data.playersData

func addPlayerData(value: PlayerData) -> void:
	data.playersData.append(value)

func removePlayerData(value: PlayerData) -> void:
	data.playersData.erase(value)

func getPlayerDataByName(value: String) -> PlayerData:
	for playerData in data.playersData:
		if playerData.character_name == value:
			return playerData
	return null

func save() -> void:
	var directory_path := "user://campaign"
	var file_path := directory_path + "/" + data.campaign_name + ".res"

	# Ensure directory exists
	var directory := DirAccess.open("user://")
	if directory == null:
		push_error("Failed to open user:// directory")
		return
	if not directory.dir_exists("campaign"):
		var _result := directory.make_dir("campaign")
		if _result != OK:
			push_error("Failed to create campaign directory. Error code: %s" % _result)
			return

	var result := ResourceSaver.save(data, file_path)
	if result != OK:
		push_error("Failed to save campaign data. Error code: %s" % result)


func load(campaign_name: String) -> void:
	var directory_path := "user://campaign"
	var file_path := directory_path + "/" + campaign_name + ".res"

	# Ensure directory exists
	var directory := DirAccess.open("user://")
	if directory == null:
		push_error("Failed to open user:// directory")
		return
	if not directory.dir_exists("campaign"):
		var result := directory.make_dir("campaign")
		if result != OK:
			push_error("Failed to create campaign directory. Error code: %s" % result)
			return

	if not FileAccess.file_exists(file_path):
		push_error("File %s does not exist" % file_path)
		return

	var resource := ResourceLoader.load(file_path)
	if resource is CampaignData:
		data = resource
	else:
		push_error("Save file %s is not a CampaignData resource" % file_path)

func resetCampaign() -> void:
	data = CampaignData.new()

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


func replaceText(text: String, ignore: String = "") -> String:
	var left_bounds := ["", " ", "\n", "\t", "(", "[", "{", "\"", "'"]
	var right_bounds := ["", " ", "\n", "\t", ".", ",", "!", "?", ":", ";", ")", "]", "}", "\"", "'"]

	# Pass 1: replace occurrences with placeholders, preserving boundaries
	for keyword in codex.orderedKeywords:
		if keyword == ignore:
			continue

		var meta = encode_meta(keyword)

		for left in left_bounds:
			for right in right_bounds:
				var needle = left + keyword + right
				if needle == keyword and text != keyword:
					continue # handled by left/right = "" cases separately below

				text = text.replace(needle, left + meta + right)

	# Pass 2: wrap placeholders
	for keyword in codex.orderedKeywords:
		if keyword == ignore:
			continue

		var meta = encode_meta(keyword)
		text = text.replace(meta, "[url=" + meta + "][color=#EE4B2B]" + keyword + "[/color][/url]")

	return text


func _on_meta_clicked(meta : String):
	var _data : CodexItem = codex.Keywords[decode_meta(meta)] 
	var _window = ConfirmationDialog.new()
	add_child(_window)
	_window.title = _data._name
	var rtl = prepareLabel(RichTextLabel.new(), false)
	rtl.fit_content = false
	rtl.text = replaceText(data.long_description, _data._name)
	_window.add_child(rtl)
	_window.get_cancel_button().visible = false
	_window.get_ok_button().visible = false
	_window.exclusive = false
	_window.size = Vector2 (300, 300)
	_window.popup()
	_window.position = get_viewport().get_mouse_position()

func _on_meta_hovered(meta : String, label : RichTextLabel) :
	var _data : CodexItem = codex.Keywords[decode_meta(meta)] 
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.tooltip_text = _data.short_description

@warning_ignore("unused_parameter")
func _on_meta_hovered_end(meta, label : RichTextLabel) :
	label.tooltip_text = ""
	
## =============== HELPERS =================
func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		c.queue_free()

func encode_meta(dict : String) :
	var json = JSON.stringify(dict)
	var bytes = json.to_utf8_buffer()
	var meta = Marshalls.raw_to_base64(bytes)
	return meta

func decode_meta(_str : String) :
	var bytes = Marshalls.base64_to_raw(_str)
	var json = bytes.get_string_from_utf8()
	var _data : String = JSON.parse_string(json)
	return _data

#func test() :
	#var items = dir_contents("res://data/Item/")
	#codex.Items.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Item/" + item + ".res")
		#codex.Items[_load._name] = _load
	#
	#items = dir_contents("res://data/Attribute/")
	#codex.Attributes.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Attribute/" + item + ".res")
		#codex.Attributes[_load._name] = _load
	#
	#items = dir_contents("res://data/Background/")
	#codex.Backgrounds.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Background/" + item + ".res")
		#codex.Backgrounds[_load._name] = _load
	#
	#items = dir_contents("res://data/Defence/")
	#codex.Defences.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Defence/" + item + ".res")
		#codex.Defences[_load._name] = _load
	#
	#items = dir_contents("res://data/Homeland/")
	#codex.Homelands.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Homeland/" + item + ".res")
		#codex.Homelands[_load._name] = _load
		#
	#items = dir_contents("res://data/Perk/")
	#codex.Perks.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Perk/" + item + ".res")
		#codex.Perks[_load._name] = _load
		#
	#items = dir_contents("res://data/Race/")
	#codex.Races.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Race/" + item + ".res")
		#codex.Races[_load._name] = _load
	#
	#items = dir_contents("res://data/Rule/")
	#codex.Rules.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Rule/" + item + ".res")
		#codex.Rules[_load._name] = _load
		#
	#items = dir_contents("res://data/Skill/")
	#codex.Skills.clear()
	#for item in items :
		#var _load : CodexItem = ResourceLoader.load("res://data/Skill/" + item + ".res")
		#codex.Skills[_load._name] = _load
#
#func dir_contents(path : String) -> Array[String]:
	#var files : Array[String]
	#var dir = DirAccess.open(path)
	#if dir:
		#dir.list_dir_begin()
		#var file_name = dir.get_next()
		#while file_name != "":
			#if !dir.current_is_dir() and file_name.contains(".res") and file_name != ".res":
				#files.append(file_name.left(file_name.length() - 4))
			#file_name = dir.get_next()
	#else:
		#print("An error occurred when trying to access the path.")
	#return files
