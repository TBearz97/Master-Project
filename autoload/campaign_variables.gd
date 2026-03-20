extends Node

var data: CampaignData
var codex: Codex

func _ready() -> void:
	data = CampaignData.new()
	codex = ResourceLoader.load("res://data/baseRules.tres") as Codex
	if codex == null:
		push_error("Failed to load res://data/baseRules.tres")
		return

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
	for player_data in data.playersData:
		if player_data._name == value:
			return player_data
	return null

func save() -> void:
	if not _ensure_campaign_directory():
		return

	var file_path := "user://campaign/%s.res" % data.campaign_name

	var result := ResourceSaver.save(data, file_path)
	if result != OK:
		push_error("Failed to save campaign data. Error code: %s" % result)

func load(campaign_name: String) -> void:
	if not _ensure_campaign_directory():
		return

	var file_path := "user://campaign/%s.res" % campaign_name

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

func prepareLabel(label: RichTextLabel, short: bool = true) -> RichTextLabel:
	label.bbcode_enabled = true
	label.fit_content = true
	label.meta_underlined = false
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.meta_hover_started.connect(_on_meta_hovered.bind(label))
	label.meta_hover_ended.connect(_on_meta_hovered_end.bind(label))
	label.meta_clicked.connect(_on_meta_clicked)
	if short:
		label.scroll_active = false
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
	else:
		label.scroll_active = true
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func replaceText(text: String, ignore: String = "") -> String:
	var left_bounds: Array[String] = ["", " ", "\n", "\t", "(", "[", "{", "\"", "'"]
	var right_bounds: Array[String] = ["", " ", "\n", "\t", ".", ",", "!", "?", ":", ";", ")", "]", "}", "\"", "'"]

	for keyword in codex.orderedKeywords:
		if keyword == ignore:
			continue

		var meta := encode_meta(keyword)

		for left in left_bounds:
			for right in right_bounds:
				var needle := left + keyword + right
				if needle == keyword and text != keyword:
					continue

				text = text.replace(needle, left + meta + right)

	for keyword in codex.orderedKeywords:
		if keyword == ignore:
			continue

		var meta := encode_meta(keyword)
		text = text.replace(meta, "[url=" + meta + "][color=#EE4B2B]" + keyword + "[/color][/url]")

	return text

func _on_meta_clicked(meta: String) -> void:
	var item: CodexItem = codex.Keywords[decode_meta(meta)]
	var window := ConfirmationDialog.new()
	add_child(window)
	window.title = item._name
	var rtl := prepareLabel(RichTextLabel.new(), false)
	rtl.fit_content = false
	rtl.text = replaceText(item.long_description, item._name)
	window.add_child(rtl)
	window.get_cancel_button().visible = false
	window.get_ok_button().visible = false
	window.exclusive = false
	window.size = Vector2(300, 300)
	window.popup()
	window.position = get_viewport().get_mouse_position()

func _on_meta_hovered(meta: String, label: RichTextLabel) -> void:
	var item: CodexItem = codex.Keywords[decode_meta(meta)]
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	label.tooltip_text = item.short_description

@warning_ignore("unused_parameter")
func _on_meta_hovered_end(meta: Variant, label: RichTextLabel) -> void:
	label.tooltip_text = ""

func _clear_grid(grid: GridContainer) -> void:
	for c in grid.get_children():
		c.queue_free()

func encode_meta(value: String) -> String:
	var json := JSON.stringify(value)
	var bytes := json.to_utf8_buffer()
	var meta := Marshalls.raw_to_base64(bytes)
	return meta

func decode_meta(value: String) -> String:
	var bytes := Marshalls.base64_to_raw(value)
	var json := bytes.get_string_from_utf8()
	var parsed: Variant = JSON.parse_string(json)
	if parsed is String:
		return parsed
	return ""

func _ensure_campaign_directory() -> bool:
	var directory := DirAccess.open("user://")
	if directory == null:
		push_error("Failed to open user:// directory")
		return false

	if directory.dir_exists("campaign"):
		return true

	var result := directory.make_dir("campaign")
	if result != OK:
		push_error("Failed to create campaign directory. Error code: %s" % result)
		return false

	return true
