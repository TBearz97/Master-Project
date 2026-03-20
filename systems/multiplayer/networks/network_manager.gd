extends Node

enum MULTIPLAYER_NETWORK_TYPE { ENET, STEAM }

var active_network_type: MULTIPLAYER_NETWORK_TYPE = MULTIPLAYER_NETWORK_TYPE.STEAM
var enet_network_scene := preload("res://Scenes/Networks/ENetNetwork.tscn")
var steam_network_scene := preload("res://Scenes/Networks/SteamNetwork.tscn")
var active_network

func _build_multiplayer_network():
	if not active_network:
		print("Setting active_network")
		
		match active_network_type:
			MULTIPLAYER_NETWORK_TYPE.ENET:
				print("Setting network type to ENet")
				_set_active_network(enet_network_scene)
			MULTIPLAYER_NETWORK_TYPE.STEAM:
				print("Setting network type to Steam")
				_set_active_network(steam_network_scene)
			_:
				print("No match for network type!")
		#%MultiplayerSynchronizer.update()

func _set_active_network(active_network_scene):
	var network_scene_initialized = active_network_scene.instantiate()
	active_network = network_scene_initialized
	add_child(active_network)

func become_host():
	_build_multiplayer_network()
	active_network.become_host()
	
func join_as_client(campaign_code = ""):
	_build_multiplayer_network()
	active_network.join_as_client(campaign_code)
	
func list_lobbies():
	_build_multiplayer_network()
	active_network.list_lobbies()

func _disconnect():
	active_network.multiplayer_peer.close()
