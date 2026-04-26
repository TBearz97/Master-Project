extends Control

const NOTE_ACTION_CREATE := "create_note"
const NOTE_ACTION_RENAME := "rename_note"
const FOLDER_ACTION_CREATE := "create_folder"
const FOLDER_ACTION_CREATE_CHILD := "create_child_folder"
const FOLDER_ACTION_RENAME := "rename_folder"
const DELETE_ACTION_NOTE := "delete_note"
const DELETE_ACTION_FOLDER := "delete_folder"

@onready var campaign_name: Label = %CampaignName
@onready var campaign_description: RichTextLabel = %CampaignDescription
@onready var campaign_manager: Node = %CampaignManager
@onready var player_picker: OptionButton = %PlayerPicker
@onready var no_players_label: Label = %NoPlayersLabel
@onready var create_skill_check_button: Button = %CreateSkillCheckButton
@onready var vault_status: Label = %VaultStatus
@onready var setup_panel: VBoxContainer = %SetupPanel
@onready var choose_vault_button: Button = %ChooseVaultButton
@onready var use_default_vault_button: Button = %UseDefaultVaultButton
@onready var editor_panel: HSplitContainer = %EditorPanel
@onready var folder_tree: Tree = %FolderTree
@onready var add_folder_button: Button = %AddFolderButton
@onready var add_subfolder_button: Button = %AddSubfolderButton
@onready var rename_folder_button: Button = %RenameFolderButton
@onready var delete_folder_button: Button = %DeleteFolderButton
@onready var note_list: ItemList = %NoteList
@onready var new_note_button: Button = %NewNoteButton
@onready var rename_note_button: Button = %RenameNoteButton
@onready var delete_note_button: Button = %DeleteNoteButton
@onready var refresh_notes_button: Button = %RefreshNotesButton
@onready var share_note_button: Button = %ShareNoteButton
@onready var current_note_label: Label = %CurrentNoteLabel
@onready var save_note_button: Button = %SaveNoteButton
@onready var open_vault_button: Button = %OpenVaultButton
@onready var note_editor: TextEdit = %NoteEditor
@onready var vault_picker: FileDialog = %VaultPicker
@onready var note_name_dialog: ConfirmationDialog = %NoteNameDialog
@onready var note_name_input: LineEdit = %NoteNameInput
@onready var delete_note_dialog: ConfirmationDialog = %DeleteNoteDialog
@onready var share_handout_dialog: ConfirmationDialog = %ShareHandoutDialog
@onready var share_dialog_label: Label = %ShareDialogLabel
@onready var share_recipient_list: ItemList = %ShareRecipientList
@onready var send_to_all_button: Button = %SendToAllButton

var selected_folder_path := ""
var selected_note := ""
var note_dirty := false
var suppress_note_text_change := false
var note_name_action := ""
var delete_action := ""

func _ready() -> void:
	campaign_name.text = CampaignVariables.getCampaignName()
	campaign_description.text = CampaignVariables.getCampaignDescription()
	_setup_skill_checks()
	_setup_notes()
	print(Steam.get_godotsteam_version())
	campaign_manager.use_steam()
	campaign_manager.become_host()
	_refresh_player_picker()

func _exit_tree() -> void:
	_save_current_note()

func _setup_skill_checks() -> void:
	create_skill_check_button.pressed.connect(_on_create_skill_check_pressed)
	if campaign_manager != null and campaign_manager.has_signal("member_list_changed"):
		campaign_manager.member_list_changed.connect(_refresh_player_picker)

func _setup_notes() -> void:
	choose_vault_button.pressed.connect(_on_choose_vault_pressed)
	use_default_vault_button.pressed.connect(_on_use_default_vault_pressed)
	folder_tree.item_selected.connect(_on_folder_tree_selected)
	add_folder_button.pressed.connect(_on_add_folder_pressed)
	add_subfolder_button.pressed.connect(_on_add_subfolder_pressed)
	rename_folder_button.pressed.connect(_on_rename_folder_pressed)
	delete_folder_button.pressed.connect(_on_delete_folder_pressed)
	note_list.item_selected.connect(_on_note_selected)
	new_note_button.pressed.connect(_on_new_note_pressed)
	rename_note_button.pressed.connect(_on_rename_note_pressed)
	delete_note_button.pressed.connect(_on_delete_note_pressed)
	refresh_notes_button.pressed.connect(_on_refresh_notes_pressed)
	share_note_button.pressed.connect(_on_share_note_pressed)
	save_note_button.pressed.connect(_on_save_note_pressed)
	open_vault_button.pressed.connect(_on_open_vault_pressed)
	note_editor.text_changed.connect(_on_note_text_changed)
	vault_picker.dir_selected.connect(_on_vault_dir_selected)
	note_name_dialog.confirmed.connect(_on_note_name_confirmed)
	delete_note_dialog.confirmed.connect(_on_delete_note_confirmed)
	share_handout_dialog.confirmed.connect(_on_share_handout_confirmed)
	share_recipient_list.item_activated.connect(_on_share_recipient_activated)
	send_to_all_button.pressed.connect(_on_send_to_all_pressed)
	_refresh_notes_ui()

func _refresh_player_picker() -> void:
	player_picker.clear()
	var players: Array = []
	if campaign_manager != null and campaign_manager.has_method("get_selectable_player_peers"):
		players = campaign_manager.get_selectable_player_peers()
	for player_entry in players:
		if not (player_entry is Dictionary):
			continue
		var player_name := str(player_entry.get("name", "Player"))
		var peer_id := int(player_entry.get("peer_id", -1))
		if peer_id < 0:
			continue
		player_picker.add_item(player_name)
		player_picker.set_item_metadata(player_picker.item_count - 1, peer_id)
	var has_players := player_picker.item_count > 0
	player_picker.visible = has_players
	no_players_label.visible = not has_players
	create_skill_check_button.disabled = not has_players
	if has_players:
		player_picker.select(0)
	_update_note_buttons()

func _on_create_skill_check_pressed() -> void:
	if player_picker.item_count == 0:
		return
	var peer_id := int(player_picker.get_selected_metadata())
	if peer_id < 0:
		return
	if campaign_manager != null and campaign_manager.has_method("begin_gm_skill_check_for_peer"):
		campaign_manager.begin_gm_skill_check_for_peer(peer_id)

func _refresh_notes_ui() -> void:
	vault_status.text = "Vault: %s" % CampaignVariables.getVaultDisplayPath()
	var has_vault := not CampaignVariables.getVaultPath().is_empty()
	setup_panel.visible = not has_vault
	editor_panel.visible = has_vault
	open_vault_button.disabled = not has_vault
	if not has_vault:
		selected_folder_path = ""
		selected_note = ""
		folder_tree.clear()
		note_list.clear()
		_clear_note_editor()
		_update_folder_buttons()
		return

	if not CampaignVariables.ensureNotesVault(CampaignVariables.getVaultPath()):
		return

	_refresh_folder_tree()

func _refresh_folder_tree(preferred_folder: String = "") -> void:
	folder_tree.clear()
	var root := folder_tree.create_item()
	var folders := CampaignVariables.getNoteFolders()
	var items_by_path := {"": root}
	for folder_path in folders:
		var parent_path := _get_parent_folder_path(folder_path)
		var parent_item: TreeItem = items_by_path.get(parent_path, root)
		var folder_item := folder_tree.create_item(parent_item)
		folder_item.set_text(0, _get_folder_display_name(folder_path))
		folder_item.set_metadata(0, folder_path)
		items_by_path[folder_path] = folder_item

	var folder_to_select := preferred_folder
	if folder_to_select.is_empty() and items_by_path.has(selected_folder_path):
		folder_to_select = selected_folder_path
	if folder_to_select.is_empty() and folders.size() > 0:
		folder_to_select = folders[0]

	if folder_to_select.is_empty() or not items_by_path.has(folder_to_select):
		selected_folder_path = ""
		_refresh_note_list()
		_update_folder_buttons()
		return

	var selected_item: TreeItem = items_by_path[folder_to_select]
	selected_item.select(0)
	_expand_tree_item_parents(selected_item)
	_on_folder_tree_selected()

func _refresh_note_list(preferred_note: String = "") -> void:
	_save_current_note()
	note_list.clear()
	if selected_folder_path.is_empty():
		selected_note = ""
		_clear_note_editor()
		_update_note_buttons()
		return

	var notes := CampaignVariables.listNotes(selected_folder_path)
	for note_name in notes:
		note_list.add_item(note_name)

	var note_to_open := preferred_note
	if note_to_open.is_empty() and notes.has(selected_note):
		note_to_open = selected_note
	if note_to_open.is_empty() and notes.size() > 0:
		note_to_open = notes[0]

	if note_to_open.is_empty():
		selected_note = ""
		_clear_note_editor()
	else:
		var note_index := notes.find(note_to_open)
		if note_index >= 0:
			note_list.select(note_index)
			_open_note(note_to_open)
		else:
			selected_note = ""
			_clear_note_editor()

	_update_note_buttons()

func _open_note(note_name: String) -> void:
	if selected_folder_path.is_empty():
		return
	if selected_note != note_name:
		_save_current_note()
	selected_note = note_name
	suppress_note_text_change = true
	note_editor.text = CampaignVariables.readNote(selected_folder_path, selected_note)
	suppress_note_text_change = false
	note_editor.editable = true
	note_dirty = false
	_update_note_header()
	_update_note_buttons()

func _save_current_note() -> bool:
	if selected_folder_path.is_empty() or selected_note.is_empty() or not note_dirty:
		return true
	var saved := CampaignVariables.writeNote(selected_folder_path, selected_note, note_editor.text)
	if saved:
		note_dirty = false
		_update_note_header()
	return saved

func _clear_note_editor() -> void:
	suppress_note_text_change = true
	note_editor.text = ""
	suppress_note_text_change = false
	note_editor.editable = false
	note_dirty = false
	_update_note_header()
	_update_note_buttons()

func _update_note_header() -> void:
	if selected_note.is_empty():
		current_note_label.text = "No note selected"
	else:
		var dirty_suffix := ""
		if note_dirty:
			dirty_suffix = " *"
		current_note_label.text = "%s / %s%s" % [selected_folder_path, selected_note, dirty_suffix]

func _update_note_buttons() -> void:
	var has_vault := not CampaignVariables.getVaultPath().is_empty()
	var has_folder := not selected_folder_path.is_empty()
	var has_note := not selected_note.is_empty()
	new_note_button.disabled = not has_vault or not has_folder
	rename_note_button.disabled = not has_note
	delete_note_button.disabled = not has_note
	share_note_button.disabled = not has_note or _get_shareable_player_count() == 0
	save_note_button.disabled = not has_note
	note_editor.editable = has_note
	_update_folder_buttons()

func _update_folder_buttons() -> void:
	var has_vault := not CampaignVariables.getVaultPath().is_empty()
	var has_folder := not selected_folder_path.is_empty()
	add_folder_button.disabled = not has_vault
	add_subfolder_button.disabled = not has_folder
	rename_folder_button.disabled = not has_folder
	delete_folder_button.disabled = not has_folder

func _get_shareable_player_count() -> int:
	if campaign_manager == null or not campaign_manager.has_method("get_selectable_player_peers"):
		return 0
	return campaign_manager.get_selectable_player_peers().size()

func _on_choose_vault_pressed() -> void:
	vault_picker.popup_centered_ratio()

func _on_use_default_vault_pressed() -> void:
	var default_path := CampaignVariables.createDefaultVaultPath()
	_configure_vault(default_path)

func _on_vault_dir_selected(dir_path: String) -> void:
	_configure_vault(dir_path)

func _configure_vault(vault_path: String) -> void:
	if not CampaignVariables.ensureNotesVault(vault_path):
		return
	CampaignVariables.setVaultPath(vault_path)
	CampaignVariables.save()
	_refresh_notes_ui()

func _on_folder_tree_selected() -> void:
	var selected_item := folder_tree.get_selected()
	if selected_item == null:
		selected_folder_path = ""
		selected_note = ""
		_refresh_note_list()
		_update_folder_buttons()
		return
	var folder_path := str(selected_item.get_metadata(0))
	if selected_folder_path == folder_path:
		_refresh_note_list()
		return
	_save_current_note()
	selected_folder_path = folder_path
	selected_note = ""
	_refresh_note_list()
	_update_folder_buttons()

func _on_add_folder_pressed() -> void:
	note_name_action = FOLDER_ACTION_CREATE
	note_name_dialog.title = "New Folder"
	note_name_dialog.get_ok_button().text = "Create"
	note_name_input.text = ""
	note_name_dialog.popup_centered()
	note_name_input.grab_focus()

func _on_add_subfolder_pressed() -> void:
	if selected_folder_path.is_empty():
		return
	note_name_action = FOLDER_ACTION_CREATE_CHILD
	note_name_dialog.title = "New Subfolder"
	note_name_dialog.get_ok_button().text = "Create"
	note_name_input.text = ""
	note_name_dialog.popup_centered()
	note_name_input.grab_focus()

func _on_rename_folder_pressed() -> void:
	if selected_folder_path.is_empty():
		return
	note_name_action = FOLDER_ACTION_RENAME
	note_name_dialog.title = "Rename Folder"
	note_name_dialog.get_ok_button().text = "Rename"
	note_name_input.text = _get_folder_display_name(selected_folder_path)
	note_name_dialog.popup_centered()
	note_name_input.grab_focus()
	note_name_input.select_all()

func _on_delete_folder_pressed() -> void:
	if selected_folder_path.is_empty():
		return
	delete_action = DELETE_ACTION_FOLDER
	delete_note_dialog.get_label().text = "Delete folder %s and everything inside it? This cannot be undone." % selected_folder_path
	delete_note_dialog.popup_centered()

func _on_note_selected(index: int) -> void:
	_open_note(note_list.get_item_text(index))

func _on_new_note_pressed() -> void:
	if selected_folder_path.is_empty():
		return
	note_name_action = NOTE_ACTION_CREATE
	note_name_dialog.title = "New Note"
	note_name_dialog.get_ok_button().text = "Create"
	note_name_input.text = ""
	note_name_dialog.popup_centered()
	note_name_input.grab_focus()

func _on_rename_note_pressed() -> void:
	if selected_note.is_empty():
		return
	note_name_action = NOTE_ACTION_RENAME
	note_name_dialog.title = "Rename Note"
	note_name_dialog.get_ok_button().text = "Rename"
	note_name_input.text = selected_note
	note_name_dialog.popup_centered()
	note_name_input.grab_focus()
	note_name_input.select_all()

func _on_delete_note_pressed() -> void:
	if selected_note.is_empty():
		return
	delete_action = DELETE_ACTION_NOTE
	delete_note_dialog.get_label().text = "Delete %s from %s?" % [selected_note, selected_folder_path]
	delete_note_dialog.popup_centered()

func _on_refresh_notes_pressed() -> void:
	_refresh_folder_tree(selected_folder_path)

func _on_share_note_pressed() -> void:
	if selected_note.is_empty() or campaign_manager == null:
		return
	if not _save_current_note():
		return
	share_recipient_list.clear()
	var players: Array = campaign_manager.get_selectable_player_peers()
	for player_entry in players:
		if not (player_entry is Dictionary):
			continue
		var peer_name := str(player_entry.get("name", "Player"))
		var peer_id := int(player_entry.get("peer_id", -1))
		if peer_id < 0:
			continue
		share_recipient_list.add_item(peer_name)
		share_recipient_list.set_item_metadata(share_recipient_list.item_count - 1, peer_id)
	share_dialog_label.text = "Share %s with a connected player or everyone." % selected_note
	var has_players := share_recipient_list.item_count > 0
	share_handout_dialog.get_ok_button().text = "Send"
	share_handout_dialog.get_ok_button().disabled = not has_players
	send_to_all_button.disabled = not has_players
	if has_players:
		share_recipient_list.select(0)
	share_handout_dialog.popup_centered()

func _on_share_handout_confirmed() -> void:
	var selected_items := share_recipient_list.get_selected_items()
	if share_recipient_list.item_count == 0 or selected_items.size() == 0:
		return
	_share_selected_note_to_peer(int(share_recipient_list.get_item_metadata(selected_items[0])))

func _on_share_recipient_activated(index: int) -> void:
	_share_selected_note_to_peer(int(share_recipient_list.get_item_metadata(index)))
	share_handout_dialog.hide()

func _on_send_to_all_pressed() -> void:
	if selected_note.is_empty() or campaign_manager == null:
		return
	if campaign_manager.has_method("share_handout_to_all"):
		campaign_manager.share_handout_to_all(selected_note, note_editor.text)
	share_handout_dialog.hide()

func _on_save_note_pressed() -> void:
	_save_current_note()

func _on_open_vault_pressed() -> void:
	CampaignVariables.revealVaultInFileManager()

func _on_note_text_changed() -> void:
	if suppress_note_text_change or selected_note.is_empty():
		return
	note_dirty = true
	_update_note_header()

func _on_note_name_confirmed() -> void:
	var requested_name := CampaignVariables.sanitizeNoteName(note_name_input.text)
	match note_name_action:
		NOTE_ACTION_CREATE:
			_create_note(requested_name)
		NOTE_ACTION_RENAME:
			_rename_note(requested_name)
		FOLDER_ACTION_CREATE:
			_create_folder("", requested_name)
		FOLDER_ACTION_CREATE_CHILD:
			_create_folder(selected_folder_path, requested_name)
		FOLDER_ACTION_RENAME:
			_rename_folder(requested_name)
	note_name_input.text = ""

func _create_note(requested_name: String) -> void:
	if selected_folder_path.is_empty():
		return
	var note_name := _build_unique_note_name(requested_name)
	if not CampaignVariables.writeNote(selected_folder_path, note_name, "# %s\n" % note_name):
		return
	_refresh_note_list(note_name)

func _rename_note(requested_name: String) -> void:
	if selected_folder_path.is_empty() or selected_note.is_empty():
		return
	_save_current_note()
	var renamed_note := CampaignVariables.renameNote(selected_folder_path, selected_note, requested_name)
	if renamed_note.is_empty():
		return
	selected_note = renamed_note
	_refresh_note_list(renamed_note)

func _create_folder(parent_folder: String, requested_name: String) -> void:
	var created_folder := CampaignVariables.createNoteFolder(parent_folder, requested_name)
	if created_folder.is_empty():
		return
	CampaignVariables.save()
	selected_folder_path = created_folder
	selected_note = ""
	_refresh_folder_tree(created_folder)

func _rename_folder(requested_name: String) -> void:
	if selected_folder_path.is_empty():
		return
	_save_current_note()
	var renamed_folder := CampaignVariables.renameNoteFolder(selected_folder_path, requested_name)
	if renamed_folder.is_empty():
		return
	CampaignVariables.save()
	selected_folder_path = renamed_folder
	selected_note = ""
	_refresh_folder_tree(renamed_folder)

func _on_delete_note_confirmed() -> void:
	match delete_action:
		DELETE_ACTION_NOTE:
			_delete_selected_note()
		DELETE_ACTION_FOLDER:
			_delete_selected_folder()
	delete_action = ""

func _delete_selected_note() -> void:
	if selected_folder_path.is_empty() or selected_note.is_empty():
		return
	if not CampaignVariables.deleteNote(selected_folder_path, selected_note):
		return
	selected_note = ""
	note_dirty = false
	_refresh_note_list()

func _delete_selected_folder() -> void:
	if selected_folder_path.is_empty():
		return
	var parent_folder := _get_parent_folder_path(selected_folder_path)
	if not CampaignVariables.deleteNoteFolder(selected_folder_path):
		return
	CampaignVariables.save()
	selected_folder_path = parent_folder
	selected_note = ""
	note_dirty = false
	_refresh_folder_tree(parent_folder)

func _share_selected_note_to_peer(peer_id: int) -> void:
	if selected_note.is_empty() or peer_id < 0 or campaign_manager == null:
		return
	if campaign_manager.has_method("share_handout_to_peer"):
		campaign_manager.share_handout_to_peer(peer_id, selected_note, note_editor.text)

func _build_unique_note_name(base_name: String) -> String:
	var cleaned_name := CampaignVariables.sanitizeNoteName(base_name)
	if cleaned_name.is_empty():
		cleaned_name = "Untitled"
	if not CampaignVariables.noteExists(selected_folder_path, cleaned_name):
		return cleaned_name
	var suffix := 2
	while true:
		var candidate := "%s %s" % [cleaned_name, suffix]
		if not CampaignVariables.noteExists(selected_folder_path, candidate):
			return candidate
		suffix += 1
	return cleaned_name

func _get_parent_folder_path(folder_path: String) -> String:
	var split_path := folder_path.split("/")
	if split_path.size() <= 1:
		return ""
	split_path.remove_at(split_path.size() - 1)
	return "/".join(split_path)

func _get_folder_display_name(folder_path: String) -> String:
	if folder_path.is_empty():
		return ""
	var split_path := folder_path.split("/")
	return split_path[split_path.size() - 1]

func _expand_tree_item_parents(item: TreeItem) -> void:
	var current := item
	while current != null:
		current.collapsed = false
		current = current.get_parent()
