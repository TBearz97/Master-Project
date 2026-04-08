extends Node

var data: CampaignData
var codex: Codex
var snapshot: CampaignData
var gameEvents: Array[GameEvent]

func _ready() -> void:
	data = CampaignData.new()
	snapshot = null
	gameEvents = []
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

func setVaultPath(value: String) -> void:
	data.vault_path = value

func getVaultPath() -> String:
	return data.vault_path

func setVaultId(value: String) -> void:
	data.vault_id = value

func getVaultId() -> String:
	return data.vault_id

func getNoteFolders() -> Array[String]:
	var folders: Array[String] = []
	if data.note_categories == null:
		data.note_categories = []
	if data.vault_path.is_empty() or not DirAccess.dir_exists_absolute(data.vault_path):
		return folders
	_collect_note_folders(data.vault_path, "", folders)
	folders.sort()
	return folders

func createNoteFolder(parent_folder: String, folder_name: String) -> String:
	if data.vault_path.is_empty():
		return ""
	var sanitized_name := _sanitize_note_name(folder_name)
	if sanitized_name.is_empty():
		return ""
	var relative_path := sanitized_name
	if not parent_folder.is_empty():
		relative_path = "%s/%s" % [parent_folder, sanitized_name]
	var absolute_path := _build_note_folder_path(data.vault_path, relative_path)
	var result := DirAccess.make_dir_recursive_absolute(absolute_path)
	if result != OK:
		push_error("Failed to create notes folder at %s. Error code: %s" % [absolute_path, result])
		return ""
	return relative_path

func renameNoteFolder(folder_path: String, folder_name: String) -> String:
	if data.vault_path.is_empty() or folder_path.is_empty():
		return ""
	var sanitized_name := _sanitize_note_name(folder_name)
	if sanitized_name.is_empty():
		return ""
	var parent_folder := _get_parent_note_folder(folder_path)
	var renamed_relative_path := sanitized_name
	if not parent_folder.is_empty():
		renamed_relative_path = "%s/%s" % [parent_folder, sanitized_name]
	var previous_path := _build_note_folder_path(data.vault_path, folder_path)
	var renamed_path := _build_note_folder_path(data.vault_path, renamed_relative_path)
	if previous_path == renamed_path:
		return renamed_relative_path
	if DirAccess.dir_exists_absolute(renamed_path):
		push_error("Cannot rename folder. Destination already exists: %s" % renamed_path)
		return ""
	var result := DirAccess.rename_absolute(previous_path, renamed_path)
	if result != OK:
		push_error("Failed to rename notes folder from %s to %s. Error code: %s" % [previous_path, renamed_path, result])
		return ""
	return renamed_relative_path

func deleteNoteFolder(folder_path: String) -> bool:
	if data.vault_path.is_empty() or folder_path.is_empty():
		return false
	var absolute_path := _build_note_folder_path(data.vault_path, folder_path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return false
	return _delete_note_folder_recursive(absolute_path)

func ensureNotesVault(vault_path: String) -> bool:
	if vault_path.is_empty():
		push_error("Notes vault path cannot be empty.")
		return false
	if data.note_categories == null:
		data.note_categories = []

	var result := DirAccess.make_dir_recursive_absolute(vault_path)
	if result != OK:
		push_error("Failed to create notes vault at %s. Error code: %s" % [vault_path, result])
		return false

	for category in data.note_categories:
		var category_path := _build_note_folder_path(vault_path, category)
		result = DirAccess.make_dir_recursive_absolute(category_path)
		if result != OK:
			push_error("Failed to create notes category at %s. Error code: %s" % [category_path, result])
			return false

	return true

func createDefaultVaultPath() -> String:
	if data.vault_id.is_empty():
		data.vault_id = _generate_vault_id()
	return ProjectSettings.globalize_path("user://campaign_vaults/%s" % data.vault_id)

func getVaultDisplayPath() -> String:
	if data.vault_path.is_empty():
		return "No vault selected"
	return data.vault_path

func listNotes(folder_path: String) -> Array[String]:
	var notes: Array[String] = []
	if data.vault_path.is_empty():
		return notes

	var absolute_folder_path := _build_note_folder_path(data.vault_path, folder_path)
	var directory := DirAccess.open(absolute_folder_path)
	if directory == null:
		return notes

	directory.list_dir_begin()
	var file_name := directory.get_next()
	while file_name != "":
		if not directory.current_is_dir() and file_name.ends_with(".md"):
			notes.append(file_name.left(file_name.length() - 3))
		file_name = directory.get_next()
	directory.list_dir_end()
	notes.sort()
	return notes

func readNote(folder_path: String, note_name: String) -> String:
	var note_path := _build_note_path(data.vault_path, folder_path, note_name)
	if note_path.is_empty() or not FileAccess.file_exists(note_path):
		return ""

	var file := FileAccess.open(note_path, FileAccess.READ)
	if file == null:
		push_error("Failed to open note at %s" % note_path)
		return ""
	return file.get_as_text()

func writeNote(folder_path: String, note_name: String, content: String) -> bool:
	if data.vault_path.is_empty():
		push_error("Cannot save note without a notes vault.")
		return false

	if not ensureNotesVault(data.vault_path):
		return false

	var note_path := _build_note_path(data.vault_path, folder_path, note_name)
	if note_path.is_empty():
		push_error("Cannot save note with an empty name.")
		return false

	var file := FileAccess.open(note_path, FileAccess.WRITE)
	if file == null:
		push_error("Failed to write note at %s" % note_path)
		return false

	file.store_string(content)
	return true

func renameNote(folder_path: String, previous_name: String, new_name: String) -> String:
	if data.vault_path.is_empty():
		return ""

	var previous_path := _build_note_path(data.vault_path, folder_path, previous_name)
	var new_path := _build_note_path(data.vault_path, folder_path, new_name)
	if previous_path.is_empty() or new_path.is_empty():
		return ""

	if previous_path == new_path:
		return _sanitize_note_name(new_name)

	if FileAccess.file_exists(new_path):
		push_error("Cannot rename note. Destination already exists: %s" % new_path)
		return ""

	var result := DirAccess.rename_absolute(previous_path, new_path)
	if result != OK:
		push_error("Failed to rename note from %s to %s. Error code: %s" % [previous_path, new_path, result])
		return ""

	return _sanitize_note_name(new_name)

func deleteNote(folder_path: String, note_name: String) -> bool:
	if data.vault_path.is_empty():
		return false

	var note_path := _build_note_path(data.vault_path, folder_path, note_name)
	if note_path.is_empty() or not FileAccess.file_exists(note_path):
		return false

	var result := DirAccess.remove_absolute(note_path)
	if result != OK:
		push_error("Failed to delete note at %s. Error code: %s" % [note_path, result])
		return false
	return true

func noteExists(folder_path: String, note_name: String) -> bool:
	var note_path := _build_note_path(data.vault_path, folder_path, note_name)
	return not note_path.is_empty() and FileAccess.file_exists(note_path)

func sanitizeNoteName(note_name: String) -> String:
	return _sanitize_note_name(note_name)

func revealVaultInFileManager() -> void:
	if data.vault_path.is_empty():
		return
	OS.shell_open(data.vault_path)

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
		startSession()
	else:
		push_error("Save file %s is not a CampaignData resource" % file_path)

func resetCampaign() -> void:
	data = CampaignData.new()
	snapshot = null
	clearGameEvents()

func startSession() -> void:
	snapshot = data.duplicate(true) as CampaignData
	clearGameEvents()

func appendGameEvent(event: GameEvent) -> void:
	if event == null:
		return
	gameEvents.append(event)

func clearGameEvents() -> void:
	gameEvents.clear()

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

func _build_note_folder_path(vault_path: String, folder_path: String) -> String:
	if vault_path.is_empty():
		return ""
	if folder_path.is_empty():
		return vault_path
	return "%s/%s" % [vault_path, folder_path]

func _build_note_path(vault_path: String, folder_path: String, note_name: String) -> String:
	if vault_path.is_empty():
		return ""

	var sanitized_name := _sanitize_note_name(note_name)
	if sanitized_name.is_empty():
		return ""

	return "%s/%s.md" % [_build_note_folder_path(vault_path, folder_path), sanitized_name]

func _collect_note_folders(base_path: String, relative_path: String, folders: Array[String]) -> void:
	var directory := DirAccess.open(base_path)
	if directory == null:
		return
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while entry_name != "":
		if directory.current_is_dir() and entry_name != "." and entry_name != "..":
			var child_relative_path := entry_name if relative_path.is_empty() else "%s/%s" % [relative_path, entry_name]
			folders.append(child_relative_path)
			_collect_note_folders("%s/%s" % [base_path, entry_name], child_relative_path, folders)
		entry_name = directory.get_next()
	directory.list_dir_end()

func _delete_note_folder_recursive(absolute_path: String) -> bool:
	var directory := DirAccess.open(absolute_path)
	if directory == null:
		push_error("Failed to open notes folder at %s for deletion." % absolute_path)
		return false
	directory.list_dir_begin()
	var entry_name := directory.get_next()
	while entry_name != "":
		if entry_name == "." or entry_name == "..":
			entry_name = directory.get_next()
			continue
		var child_path := "%s/%s" % [absolute_path, entry_name]
		if directory.current_is_dir():
			if not _delete_note_folder_recursive(child_path):
				directory.list_dir_end()
				return false
		else:
			var remove_result := DirAccess.remove_absolute(child_path)
			if remove_result != OK:
				directory.list_dir_end()
				push_error("Failed to delete note at %s. Error code: %s" % [child_path, remove_result])
				return false
		entry_name = directory.get_next()
	directory.list_dir_end()
	var result := DirAccess.remove_absolute(absolute_path)
	if result != OK:
		push_error("Failed to delete notes folder at %s. Error code: %s" % [absolute_path, result])
		return false
	return true

func _get_parent_note_folder(folder_path: String) -> String:
	var split_path := folder_path.split("/")
	if split_path.size() <= 1:
		return ""
	split_path.remove_at(split_path.size() - 1)
	return "/".join(split_path)

func _sanitize_note_name(note_name: String) -> String:
	var sanitized := note_name.strip_edges()
	if sanitized.ends_with(".md"):
		sanitized = sanitized.left(sanitized.length() - 3)

	for token in ["/", "\\", ":", "*", "?", '"', "<", ">", "|", "\n", "\r", "\t"]:
		sanitized = sanitized.replace(token, "_")

	sanitized = sanitized.strip_edges()
	while sanitized.ends_with("."):
		sanitized = sanitized.left(sanitized.length() - 1)
	if sanitized.is_empty():
		return "Untitled"
	return sanitized

func _generate_vault_id() -> String:
	return "%s_%s" % [str(Time.get_unix_time_from_system()), str(randi())]
