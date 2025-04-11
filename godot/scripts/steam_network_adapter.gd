extends "res://addons/godot-rollback-netcode/NetworkAdaptor.gd"

func send_ping(peer_id: int, msg: Dictionary) -> void:
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_ping(peer_id, msg)
	SteamManager.send_p2p_packet(peer_id, pack)

func send_ping_back(peer_id: int, msg: Dictionary) -> void:
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_ping_back(peer_id, msg)
	SteamManager.send_p2p_packet(peer_id, pack)

func send_remote_start(peer_id: int) -> void:
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_start(peer_id)
	SteamManager.send_p2p_packet(peer_id, pack)

func send_remote_stop(peer_id: int) -> void:
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_stop(peer_id)
	SteamManager.send_p2p_packet(peer_id, pack)

func send_input_tick(peer_id: int, msg: PackedByteArray) -> void:
	SteamManager.send_p2p_packet(peer_id, msg)

func is_network_host() -> bool:
	return SteamManager.is_host()

func is_network_master_for_node(node: Node) -> bool:
	return node.is_multiplayer_authority()

func get_unique_id() -> int:
	return multiplayer.get_unique_id()
