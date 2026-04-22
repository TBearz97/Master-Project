extends Window
class_name SkillCheckWindow

signal gm_offer_approved(options)
signal local_check_requested(options, selected_skill_name, helper_peer_id)
signal option_chosen(selected_skill_name: String, helper_peer_id: int)
signal request_cancelled()

const MODE_GM_SETUP := "gm_setup"
const MODE_LOCAL_SETUP := "local_setup"
const MODE_PLAYER_CHOICE := "player_choice"
const MAX_OPTIONAL_ROWS := 3

var available_skill_names: Array[String] = []
var current_mode := MODE_LOCAL_SETUP
var current_requester_name := ""
var requested_skill_name := ""
var current_options: Array[Dictionary] = []
var current_skill_values: Dictionary = {}
var current_helper_options_by_skill: Dictionary = {}

var title_label: Label
var description_label: Label
var setup_rows_container: VBoxContainer
var choice_container: VBoxContainer
var local_choice_label: Label
var local_choice_option: OptionButton
var helper_choice_label: Label
var helper_choice_option: OptionButton
var confirm_button: Button

var primary_row: Dictionary = {}
var optional_rows: Array[Dictionary] = []

func _ready() -> void:
	title = "Skill Check"
	size = Vector2i(520, 440)
	close_requested.connect(_on_close_requested)
	_build_ui()

func configure_gm_setup(skill_names: Array[String], requester_name: String, requested_skill: String) -> void:
	available_skill_names = skill_names.duplicate()
	available_skill_names.sort()
	current_mode = MODE_GM_SETUP
	current_requester_name = requester_name
	requested_skill_name = requested_skill
	current_helper_options_by_skill = {}
	title_label.text = "Approve Skill Check"
	if requested_skill.strip_edges().is_empty():
		description_label.text = "Create a skill check for %s. Set the primary option and up to %s optional skills." % [requester_name, MAX_OPTIONAL_ROWS]
	else:
		description_label.text = "%s requested %s. Set the primary option and up to %s optional skills." % [requester_name, requested_skill, MAX_OPTIONAL_ROWS]
	_setup_rows(true)
	choice_container.visible = false
	local_choice_label.visible = false
	local_choice_option.visible = false
	helper_choice_label.visible = false
	helper_choice_option.visible = false
	confirm_button.text = "Send Options"

func configure_local_setup(skill_names: Array[String], requested_skill: String, helper_options_by_skill: Dictionary = {}) -> void:
	available_skill_names = skill_names.duplicate()
	available_skill_names.sort()
	current_mode = MODE_LOCAL_SETUP
	current_requester_name = PlayerVariables.getName()
	requested_skill_name = requested_skill
	current_helper_options_by_skill = helper_options_by_skill.duplicate(true)
	title_label.text = "Local Skill Check"
	description_label.text = "Set the main DC and up to %s optional skills, then choose which one to resolve." % MAX_OPTIONAL_ROWS
	_setup_rows(true)
	choice_container.visible = false
	local_choice_label.visible = true
	local_choice_option.visible = true
	helper_choice_label.visible = true
	helper_choice_option.visible = true
	confirm_button.text = "Resolve"
	_refresh_local_choice_options()

func configure_player_choice(requester_name: String, options: Array[Dictionary], skill_values: Dictionary = {}, helper_options_by_skill: Dictionary = {}) -> void:
	current_mode = MODE_PLAYER_CHOICE
	current_requester_name = requester_name
	current_options = _sanitize_options(options)
	current_skill_values = skill_values.duplicate(true)
	current_helper_options_by_skill = helper_options_by_skill.duplicate(true)
	title_label.text = "Choose Skill"
	description_label.text = "%s can use one of the following GM-approved options." % requester_name
	setup_rows_container.visible = false
	local_choice_label.visible = true
	local_choice_option.visible = true
	helper_choice_label.visible = true
	helper_choice_option.visible = true
	choice_container.visible = false
	confirm_button.visible = true
	confirm_button.text = "Resolve"
	_refresh_player_choice_options()

func _build_ui() -> void:
	var panel := Panel.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(margin)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	margin.add_child(root)

	title_label = Label.new()
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	root.add_child(title_label)

	description_label = Label.new()
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	root.add_child(description_label)

	setup_rows_container = VBoxContainer.new()
	setup_rows_container.add_theme_constant_override("separation", 8)
	root.add_child(setup_rows_container)

	choice_container = VBoxContainer.new()
	choice_container.add_theme_constant_override("separation", 6)
	root.add_child(choice_container)

	local_choice_label = Label.new()
	local_choice_label.text = "Resolve using"
	root.add_child(local_choice_label)

	local_choice_option = OptionButton.new()
	local_choice_option.item_selected.connect(func(_idx: int) -> void: _refresh_helper_choice_options())
	root.add_child(local_choice_option)

	helper_choice_label = Label.new()
	helper_choice_label.text = "Assisted by"
	root.add_child(helper_choice_label)

	helper_choice_option = OptionButton.new()
	root.add_child(helper_choice_option)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(spacer)

	confirm_button = Button.new()
	confirm_button.pressed.connect(_on_confirm_pressed)
	root.add_child(confirm_button)

func _setup_rows(include_requested_skill: bool) -> void:
	setup_rows_container.visible = true
	confirm_button.visible = true
	for child in setup_rows_container.get_children():
		child.queue_free()
	optional_rows.clear()

	primary_row = _build_option_row("Primary Skill", false)
	setup_rows_container.add_child(primary_row["container"])
	_populate_skill_selector(primary_row["skill"] as OptionButton, requested_skill_name if include_requested_skill else "")
	(primary_row["dc"] as SpinBox).value_changed.connect(func(_value: float) -> void:
		_sync_optional_difficulty_bounds()
	)

	for idx in MAX_OPTIONAL_ROWS:
		var row := _build_option_row("Optional Skill %s" % (idx + 1), true)
		_populate_skill_selector(row["skill"] as OptionButton, "")
		optional_rows.append(row)
		setup_rows_container.add_child(row["container"])
	_sync_optional_difficulty_bounds()
	_refresh_unique_skill_availability()

func _build_option_row(row_label_text: String, allow_disable: bool) -> Dictionary:
	var container := HBoxContainer.new()
	container.add_theme_constant_override("separation", 8)

	var enabled := CheckBox.new()
	enabled.text = row_label_text
	enabled.button_pressed = not allow_disable
	enabled.disabled = not allow_disable
	enabled.custom_minimum_size = Vector2(130, 0)
	container.add_child(enabled)

	var skill_selector := OptionButton.new()
	skill_selector.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(skill_selector)

	var dc := SpinBox.new()
	dc.min_value = 0
	dc.max_value = 99
	dc.step = 1
	dc.rounded = true
	dc.value = 10
	dc.custom_minimum_size = Vector2(80, 0)
	container.add_child(dc)

	var dc_label := Label.new()
	dc_label.text = "DC"
	container.add_child(dc_label)
	skill_selector.disabled = allow_disable
	dc.editable = not allow_disable

	enabled.toggled.connect(func(_pressed: bool) -> void:
		skill_selector.disabled = not enabled.button_pressed
		dc.editable = enabled.button_pressed
		_refresh_unique_skill_availability()
		_refresh_local_choice_options()
		_refresh_helper_choice_options()
	)
	skill_selector.item_selected.connect(func(_idx: int) -> void:
		_refresh_unique_skill_availability()
		_refresh_local_choice_options()
		_refresh_helper_choice_options()
	)
	dc.value_changed.connect(func(_value: float) -> void: _refresh_local_choice_options())

	return {
		"container": container,
		"enabled": enabled,
		"skill": skill_selector,
		"dc": dc,
	}

func _sync_optional_difficulty_bounds() -> void:
	if primary_row.is_empty():
		return
	var primary_dc := int((primary_row["dc"] as SpinBox).value)
	for row in optional_rows:
		var dc := row.get("dc", null) as SpinBox
		if dc == null:
			continue
		dc.min_value = primary_dc
		if dc.value < primary_dc:
			dc.value = primary_dc

func _refresh_unique_skill_availability() -> void:
	var rows: Array[Dictionary] = []
	if not primary_row.is_empty():
		rows.append(primary_row)
	for row in optional_rows:
		rows.append(row)

	var active_skill_names: Array[String] = []
	for row in rows:
		if not _is_row_active(row):
			continue
		var skill_selector := row.get("skill", null) as OptionButton
		if skill_selector == null or skill_selector.item_count == 0:
			continue
		var selected_skill_name := str(skill_selector.get_selected_metadata()).strip_edges()
		if not selected_skill_name.is_empty() and not active_skill_names.has(selected_skill_name):
			active_skill_names.append(selected_skill_name)

	for row in rows:
		var skill_selector := row.get("skill", null) as OptionButton
		if skill_selector == null or skill_selector.item_count == 0:
			continue
		var row_active := _is_row_active(row)
		var selected_skill_name := str(skill_selector.get_selected_metadata()).strip_edges()
		for idx in range(skill_selector.item_count):
			var item_skill_name := str(skill_selector.get_item_metadata(idx)).strip_edges()
			var should_disable := false
			if row_active and not item_skill_name.is_empty() and item_skill_name != selected_skill_name and active_skill_names.has(item_skill_name):
				should_disable = true
			skill_selector.set_item_disabled(idx, should_disable)
		if row_active and skill_selector.selected > 0 and skill_selector.is_item_disabled(skill_selector.selected):
			_select_first_enabled_item(skill_selector)

func _is_row_active(row: Dictionary) -> bool:
	var enabled := row.get("enabled", null) as CheckBox
	if enabled == null:
		return false
	return enabled.button_pressed

func _select_first_enabled_item(skill_selector: OptionButton) -> void:
	for idx in range(1, skill_selector.item_count):
		if not skill_selector.is_item_disabled(idx):
			skill_selector.select(idx)
			return
	skill_selector.select(0)

func _populate_skill_selector(selector: OptionButton, preferred_skill: String) -> void:
	selector.clear()
	selector.add_item("-- Select Skill --")
	selector.set_item_metadata(0, "")
	for skill_name in available_skill_names:
		selector.add_item(skill_name)
		selector.set_item_metadata(selector.item_count - 1, skill_name)
	selector.select(0)
	if preferred_skill.is_empty():
		return
	for idx in range(selector.item_count):
		if selector.get_item_text(idx) == preferred_skill:
			selector.select(idx)
			return

func _collect_setup_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	var used_skill_names: Array[String] = []
	var primary_option := _row_to_option(primary_row, true)
	if primary_option.is_empty():
		return []
	options.append(primary_option)
	used_skill_names.append(primary_option["skill_name"])

	for row in optional_rows:
		var enabled := (row["enabled"] as CheckBox).button_pressed
		if not enabled:
			continue
		var option := _row_to_option(row, false)
		if option.is_empty():
			continue
		if used_skill_names.has(option["skill_name"]):
			continue
		used_skill_names.append(option["skill_name"])
		options.append(option)
	return options

func _row_to_option(row: Dictionary, is_primary: bool) -> Dictionary:
	var skill_selector := row.get("skill", null) as OptionButton
	var dc := row.get("dc", null) as SpinBox
	if skill_selector == null or skill_selector.item_count == 0 or dc == null:
		return {}
	var selected_skill_name := str(skill_selector.get_selected_metadata()).strip_edges()
	if selected_skill_name.is_empty():
		return {}
	return {
		"skill_name": selected_skill_name,
		"difficulty": int(dc.value),
		"is_primary": is_primary,
	}

func _sanitize_options(options: Array[Dictionary]) -> Array[Dictionary]:
	var sanitized: Array[Dictionary] = []
	for option in options:
		if option == null:
			continue
		var skill_name := str(option.get("skill_name", "")).strip_edges()
		if skill_name.is_empty():
			continue
		sanitized.append({
			"skill_name": skill_name,
			"difficulty": maxi(int(option.get("difficulty", 0)), 0),
			"is_primary": bool(option.get("is_primary", false)),
		})
	return sanitized

func _refresh_local_choice_options() -> void:
	if not is_inside_tree() or current_mode != MODE_LOCAL_SETUP:
		return
	var options := _collect_setup_options()
	local_choice_option.clear()
	for option in options:
		local_choice_option.add_item("%s (DC %s)" % [option["skill_name"], option["difficulty"]])
		local_choice_option.set_item_metadata(local_choice_option.item_count - 1, option["skill_name"])
	if local_choice_option.item_count > 0:
		local_choice_option.select(0)
	_refresh_helper_choice_options()

func _refresh_player_choice_options() -> void:
	if not is_inside_tree() or current_mode != MODE_PLAYER_CHOICE:
		return
	local_choice_option.clear()
	for option in current_options:
		var skill_name := str(option.get("skill_name", ""))
		var chance_text := _build_choice_chance_text(skill_name, int(option.get("difficulty", 0)))
		local_choice_option.add_item("%s (%s)%s" % [skill_name, chance_text, " - Primary" if bool(option.get("is_primary", false)) else ""])
		local_choice_option.set_item_metadata(local_choice_option.item_count - 1, skill_name)
	if local_choice_option.item_count > 0:
		local_choice_option.select(0)
	_refresh_helper_choice_options()

func _refresh_helper_choice_options() -> void:
	if helper_choice_option == null:
		return
	helper_choice_option.clear()
	helper_choice_option.add_item("No Helper")
	helper_choice_option.set_item_metadata(0, -1)
	if local_choice_option == null or local_choice_option.item_count == 0:
		helper_choice_option.select(0)
		return
	var selected_skill_name := str(local_choice_option.get_item_metadata(local_choice_option.selected)).strip_edges()
	var helper_options_variant: Variant = current_helper_options_by_skill.get(selected_skill_name, [])
	if helper_options_variant is Array:
		for helper_option_variant in helper_options_variant:
			if not (helper_option_variant is Dictionary):
				continue
			var helper_option := helper_option_variant as Dictionary
			var helper_name := str(helper_option.get("name", "Player")).strip_edges()
			var support_bonus := int(helper_option.get("support_bonus", 0))
			if helper_name.is_empty() or support_bonus <= 0:
				continue
			helper_choice_option.add_item("%s (+%s Good Natured)" % [helper_name, support_bonus])
			helper_choice_option.set_item_metadata(helper_choice_option.item_count - 1, int(helper_option.get("peer_id", -1)))
	helper_choice_option.select(0)

func _build_choice_chance_text(skill_name: String, difficulty: int) -> String:
	if not current_skill_values.has(skill_name):
		return "DC %s" % difficulty
	var skill_value := int(current_skill_values.get(skill_name, 0))
	var threshold := difficulty - skill_value
	if threshold <= 1:
		return "100%% success"
	if threshold > 20:
		return "0%% success"
	var successful_rolls := 21 - threshold
	return "%s%% success" % (successful_rolls * 5)

func _on_confirm_pressed() -> void:
	match current_mode:
		MODE_GM_SETUP:
			var options := _collect_setup_options()
			if options.is_empty():
				return
			gm_offer_approved.emit(options)
			queue_free()
		MODE_LOCAL_SETUP:
			var local_options := _collect_setup_options()
			if local_options.is_empty() or local_choice_option.item_count == 0:
				return
			var selected_skill_name := str(local_choice_option.get_item_metadata(local_choice_option.selected))
			local_check_requested.emit(local_options, selected_skill_name, _get_selected_helper_peer_id())
			queue_free()
		MODE_PLAYER_CHOICE:
			if current_options.is_empty() or local_choice_option.item_count == 0:
				return
			var chosen_skill_name := str(local_choice_option.get_item_metadata(local_choice_option.selected))
			option_chosen.emit(chosen_skill_name, _get_selected_helper_peer_id())
			queue_free()

func _on_close_requested() -> void:
	request_cancelled.emit()
	queue_free()

func _get_selected_helper_peer_id() -> int:
	if helper_choice_option == null or helper_choice_option.item_count == 0:
		return -1
	return int(helper_choice_option.get_item_metadata(helper_choice_option.selected))
