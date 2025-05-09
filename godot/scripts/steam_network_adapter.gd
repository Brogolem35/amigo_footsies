extends "res://addons/godot-rollback-netcode/NetworkAdaptor.gd"

func send_ping(peer_id: int, msg: Dictionary) -> void:
	# printerr("send_ping: ", peer_id, SteamManager.lobby_members)
	var pack: PackedByteArray = CustomMessageSerializer.serialize_ping(peer_id, msg)
	SteamManagerStatic.send_p2p_packet(peer_id, pack)

func send_ping_back(peer_id: int, msg: Dictionary) -> void:
	# printerr("send_pingback: ", peer_id, SteamManager.lobby_members)
	var pack: PackedByteArray = CustomMessageSerializer.serialize_ping_back(peer_id, msg)
	SteamManagerStatic.send_p2p_packet(peer_id, pack)

func send_remote_start(peer_id: int) -> void:
	var pack: PackedByteArray = CustomMessageSerializer.serialize_start(peer_id)
	SteamManagerStatic.send_p2p_packet(peer_id, pack)

func send_remote_stop(peer_id: int) -> void:
	var pack: PackedByteArray = CustomMessageSerializer.serialize_stop(peer_id)
	SteamManagerStatic.send_p2p_packet(peer_id, pack)

func send_input_tick(peer_id: int, msg: PackedByteArray) -> void:
	SteamManagerStatic.send_p2p_packet(peer_id, msg)

func is_network_host() -> bool:
	return SteamManagerStatic.is_host()

func is_network_master_for_node(node: Node) -> bool:
	return node.steam_mp_id == SteamManagerStatic.steam_id

func get_unique_id() -> int:
	return SteamManagerStatic.steam_id
