extends Control

@onready var start_campaign_button: Button = $StartCampaignButton
@onready var campaign_code_input: LineEdit = $VBoxContainer/JoinCampaign/CampaignCodeInput
@onready var join_campaign_button: Button = $VBoxContainer/JoinCampaign/JoinCampaignButton
@onready var status_label: RichTextLabel = $VBoxContainer/StatusLabel
@onready var chat_log: RichTextLabel = $VBoxContainer/ChatLog
@onready var chat_input: LineEdit = $VBoxContainer/SendMessage/ChatInput
@onready var send_chat_button: Button = $VBoxContainer/SendMessage/SendChatButton
@onready var leave_campaign_button: Button = $VBoxContainer/LeaveCampaign/LeaveCampaignButton
@onready var campaign_code_label: Label = $VBoxContainer/LeaveCampaign/CampaignCode
@onready var join_campaign: HSplitContainer = $VBoxContainer/JoinCampaign
@onready var leave_campaign: HSplitContainer = $VBoxContainer/LeaveCampaign

var lobbyID

func _ready() -> void:
	DbHelper.prepareLabel(chat_log, false)
	chat_log.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	chat_log.fit_content = false
	chat_log.scroll_following = true
	
	start_campaign_button.pressed.connect(_on_start_campaign_pressed)
	join_campaign_button.pressed.connect(_on_join_campaign_pressed)
	send_chat_button.pressed.connect(_on_send_chat_pressed)
	leave_campaign_button.pressed.connect(_on_leave_campaign_pressed)
	
	CampaignNetwork.campaign_created.connect(_on_campaign_created)
	CampaignNetwork.campaign_joined.connect(_on_campaign_joined)
	CampaignNetwork.campaign_join_failed.connect(_on_campaign_join_failed)
	
	Steam.lobby_message.connect(_on_chat_message_received)

	_set_chat_enabled(false)


func _on_start_campaign_pressed() -> void:
	status_label.clear()
	status_label.append_text("Creating campaign...\n")
	CampaignNetwork.start_campaign(6)

func _on_leave_campaign_pressed() -> void:
	return

func _on_join_campaign_pressed() -> void:
	var code_text: String = campaign_code_input.text
	status_label.clear()
	status_label.append_text("Searching for campaign...\n")
	CampaignNetwork.join_campaign_by_code(code_text)

func _on_campaign_created(campaign_code: String, lobby_steam_id: int) -> void:
	status_label.append_text("Campaign created.\n")
	status_label.append_text("Code: %s\n" % campaign_code)
	status_label.append_text("Lobby: %s\n" % str(lobby_steam_id))
	Steam.setLobbyData(lobby_steam_id, "Campaign Key", campaign_code)
	Steam.setLobbyData(lobby_steam_id, "Host", str(Steam.getSteamID()))
	lobbyID = lobby_steam_id

func _on_campaign_joined(lobby_steam_id: int) -> void:
	status_label.append_text("Joined campaign lobby: %s\n" % str(lobby_steam_id))
	lobbyID = lobby_steam_id
	_set_chat_enabled(true)

func _on_campaign_join_failed(reason_text: String) -> void:
	status_label.append_text("Join failed: %s\n" % reason_text)
	_set_chat_enabled(false)

func _on_send_chat_pressed() -> void:
	var message_text: String = chat_input.text.strip_edges()
	if message_text.is_empty():
		return
	Steam.sendLobbyChatMsg(lobbyID, message_text)

func _on_chat_message_received(_lobby_steam_id: int, sender_steam_id: int, message_text: String, _chat_type:int) -> void:
	chat_log.append_text(DbHelper.replaceText("%s: %s\n" % [Steam.getFriendPersonaName(sender_steam_id), message_text]))

func _set_chat_enabled(is_enabled: bool) -> void:
	chat_input.editable = is_enabled
	send_chat_button.disabled = not is_enabled
	join_campaign.visible = !is_enabled
	leave_campaign.visible = is_enabled
	if lobbyID != null :
		var campaignKey = Steam.getLobbyData(lobbyID, "Campaign Key")
		campaign_code_label.text = "Campaign Code: " + campaignKey
