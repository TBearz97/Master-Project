extends Node

enum MULTIPLAYER_NETWORK_TYPE { ENET, STEAM }

var active_network_type: MULTIPLAYER_NETWORK_TYPE = MULTIPLAYER_NETWORK_TYPE.STEAM
var enet_network_scene: PackedScene = preload("res://Scenes/Networks/ENetNetwork.tscn")
var steam_network_scene: PackedScene = preload("res://Scenes/Networks/SteamNetwork.tscn")
var active_network: Node

func _build_multiplayer_network() -> void:
	if not active_network:
		SteamManager.log_network_message("Network", "Setting active_network")
		print("Setting active_network")

		match active_network_type:
			MULTIPLAYER_NETWORK_TYPE.ENET:
				SteamManager.log_network_message("Network", "Setting network type to ENet")
				print("Setting network type to ENet")
				_set_active_network(enet_network_scene)
			MULTIPLAYER_NETWORK_TYPE.STEAM:
				SteamManager.log_network_message("Network", "Setting network type to Steam")
				print("Setting network type to Steam")
				_set_active_network(steam_network_scene)
			_:
				SteamManager.log_network_message("Network", "No match for network type!")
				print("No match for network type!")

func _set_active_network(network_scene: PackedScene) -> void:
	active_network = network_scene.instantiate()
	add_child(active_network)

func become_host() -> void:
	_build_multiplayer_network()
	active_network.become_host()

func join_as_client(campaign_code: String = "") -> void:
	_build_multiplayer_network()
	active_network.join_as_client(campaign_code)

func list_lobbies() -> void:
	_build_multiplayer_network()
	active_network.list_lobbies()

func _disconnect() -> void:
	active_network.multiplayer_peer.close()
