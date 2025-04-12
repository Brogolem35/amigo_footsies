extends "res://addons/godot-rollback-netcode/NetworkAdaptor.gd"

func send_ping(code: int, msg: Dictionary) -> void:
	# printerr("send_ping: ", peer_id, SteamManager.lobby_members)
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_ping(code, msg)
	SteamManager.send_p2p_code(code, pack)

func send_ping_back(code: int, msg: Dictionary) -> void:
	# printerr("send_pingback: ", peer_id, SteamManager.lobby_members)
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_ping_back(code, msg)
	SteamManager.send_p2p_code(code, pack)

func send_remote_start(code: int) -> void:
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_start(code)
	SteamManager.send_p2p_code(code, pack)

func send_remote_stop(code: int) -> void:
	var pack: PackedByteArray = SyncManager.message_serializer.serialize_stop(code)
	SteamManager.send_p2p_code(code, pack)

func send_input_tick(code: int, msg: PackedByteArray) -> void:
	SteamManager.send_p2p_code(code, msg)

func is_network_host() -> bool:
	return SteamManager.is_host()

func is_network_master_for_node(node: Node) -> bool:
	var code := SteamManager.id2code(SteamManager.steam_id)
	print(node, ": ", node.get_multiplayer_authority())
	print("Code: ", code)
	return node.get_multiplayer_authority() == code

func get_unique_id() -> int:
	var code := SteamManager.id2code(SteamManager.steam_id)
	return code
