extends Control

@onready var tab_container: TabContainer = %TabContainer
@onready var combat_session: Control = %CombatSession
@onready var campaign_manager: Node = %CampaignManager
@onready var quick_stats: GridContainer = $Panel/MarginContainer/QuickInfo/Stats

func _ready() -> void:
	if campaign_manager != null and campaign_manager.has_signal("encounter_state_changed"):
		campaign_manager.encounter_state_changed.connect(_update_combat_tab_state)
	if campaign_manager != null and campaign_manager.has_signal("authority_role_changed"):
		campaign_manager.authority_role_changed.connect(_on_authority_role_changed)

	var started := false
	if campaign_manager != null and campaign_manager.has_method("has_started_encounter"):
		started = campaign_manager.has_started_encounter()
	_update_combat_tab_state(started)
	if not PlayerVariables.vitals_changed.is_connected(_refresh_quick_stats):
		PlayerVariables.vitals_changed.connect(_refresh_quick_stats)
	if not PlayerVariables.leveledUp.is_connected(_refresh_quick_stats):
		PlayerVariables.leveledUp.connect(_refresh_quick_stats)
	_refresh_quick_stats()

func _on_authority_role_changed(_is_host: bool) -> void:
	var started := false
	if campaign_manager != null and campaign_manager.has_method("has_started_encounter"):
		started = campaign_manager.has_started_encounter()
	_update_combat_tab_state(started)

func _update_combat_tab_state(started: bool) -> void:
	var combat_tab_idx := _get_combat_tab_index()
	if combat_tab_idx == -1:
		return

	var is_host_role := false
	if campaign_manager != null and campaign_manager.has_method("is_host_authority"):
		is_host_role = campaign_manager.is_host_authority()

	var should_disable := not is_host_role and not started
	tab_container.set_tab_disabled(combat_tab_idx, should_disable)
	if should_disable and tab_container.current_tab == combat_tab_idx:
		tab_container.current_tab = 0

func _get_combat_tab_index() -> int:
	for idx in range(tab_container.get_tab_count()):
		if tab_container.get_tab_control(idx) == combat_session:
			return idx
	return -1

func _refresh_quick_stats() -> void:
	var max_health := RuleEngine.getMaxHealth(PlayerVariables.data)
	var max_vitality := RuleEngine.getMaxVitality(PlayerVariables.data)
	for child in quick_stats.get_children():
		match child.name:
			"Level":
				child.get_child(1).text = str(PlayerVariables.getLevel())
			"Health":
				child.get_child(1).text = "%s/%s" % [PlayerVariables.data.currentHP, max_health]
			"ActionPoints":
				child.get_child(1).text = str(RuleEngine.getActionPoints(PlayerVariables.data))
			"Experience":
				child.get_child(1).text = str(PlayerVariables.getExperience())
			"Vitality":
				child.get_child(1).text = "%s/%s" % [PlayerVariables.data.currentVitality, max_vitality]
			"Fatigue":
				child.get_child(1).text = str(PlayerVariables.getFatigue())
			"NecroticDamage":
				child.get_child(1).text = str(PlayerVariables.getNecroticDamage())
			"LevelUp":
				child.disabled = !PlayerVariables.getLevelAvailable()
