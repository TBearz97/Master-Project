extends Control

@onready var campaign_name: Label = %CampaignName
@onready var campaign_description: RichTextLabel = %CampaignDescription
@onready var campaign_manager: Node = %CampaignManager
@onready var player_picker: OptionButton = %PlayerPicker
@onready var no_players_label: Label = %NoPlayersLabel
@onready var create_skill_check_button: Button = %CreateSkillCheckButton

func _ready() -> void:
	campaign_name.text = CampaignVariables.getCampaignName()
	campaign_description.text = CampaignVariables.getCampaignDescription()
	create_skill_check_button.pressed.connect(_on_create_skill_check_pressed)
	if campaign_manager != null and campaign_manager.has_signal("member_list_changed"):
		campaign_manager.member_list_changed.connect(_refresh_player_picker)
	campaign_manager.use_enet()
	campaign_manager.become_host()
	_refresh_player_picker()

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

func _on_create_skill_check_pressed() -> void:
	if player_picker.item_count == 0:
		return
	var peer_id := int(player_picker.get_selected_metadata())
	if peer_id < 0:
		return
	if campaign_manager != null and campaign_manager.has_method("begin_gm_skill_check_for_peer"):
		campaign_manager.begin_gm_skill_check_for_peer(peer_id)
