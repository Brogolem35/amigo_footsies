extends MessageSerializer

const input_path_mapping := {
	"/root/MainMenu/BattleScene/Player1InputDummy": 1,
	"/root/MainMenu/BattleScene/Player2InputDummy": 2,
}

const input_path_reverse := {
	1: "/root/MainMenu/BattleScene/Player1InputDummy",
	2: "/root/MainMenu/BattleScene/Player2InputDummy",
}

enum HeaderFlags {
	FORWARD_FLAG = 1 << 0,
	BACKWARD_FLAG = 1 << 1,
	ATTACK_PRESS_FLAG = 1 << 2,
	SPECIAL_PRESS_FLAG = 1 << 3,
}

func message_type(serialized: PackedByteArray) -> Constants.MessageType:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	
	return buf.get_u8()

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.resize(16)
	buf.put_u8(Constants.MessageType.MATCH_INPUT)
	
	buf.put_u32(all_input["$"])
	buf.put_u8(all_input.size() - 1)
	
	for path in all_input:
		if path == "$":
			continue
		buf.put_u8(input_path_mapping[path])
		
		var header := 0
		var input: Dictionary = all_input[path]
		var input_vec = input.get("movement", 0)
		match sign(input_vec):
			1:
				header |= HeaderFlags.FORWARD_FLAG
			-1:
				header |= HeaderFlags.BACKWARD_FLAG
		if input.get("attack_press", false):
			header |= HeaderFlags.ATTACK_PRESS_FLAG
		if input.get("special_press", false):
			header |= HeaderFlags.SPECIAL_PRESS_FLAG
		
		buf.put_u8(header)
	
	buf.resize(buf.get_position())
	# print("count: %s" % buf.data_array.size())
	return buf.data_array

func unserialize_input(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	
	if buf.get_u8() != Constants.MessageType.MATCH_INPUT:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var all_input := {}

	all_input["$"] = buf.get_u32()
	var input_count := buf.get_u8()
	if input_count == 0:
		return all_input
	
	var path = input_path_reverse[buf.get_u8()]
	var input := {}
	
	var header := buf.get_u8()
	var movement := 0
	if header & HeaderFlags.FORWARD_FLAG:
		movement = 1
	elif header & HeaderFlags.BACKWARD_FLAG:
		movement = -1
	input["movement"] = movement
	input["attack_press"] = (header & HeaderFlags.ATTACK_PRESS_FLAG) as bool
	input["special_press"] = (header & HeaderFlags.SPECIAL_PRESS_FLAG) as bool
	
	all_input[path] = input
	return all_input

func serialize_handshake(peer_id: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.resize(9)
	buf.put_u8(Constants.MessageType.HANDSHAKE)
	buf.put_64(peer_id)
	
	return buf.data_array

# 0 if error
func unserialize_handshake(serialized: PackedByteArray) -> int:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	
	if buf.get_u8() != Constants.MessageType.HANDSHAKE:
		return 0
	
	return buf.get_64()

# https://github.com/hislittlecuzin/Snopek-Rollback-Steamworks-FP-Template/blob/main/Scripts/Netcode/SteamMessageSerializer.gd
func serialize_ping(dest_id: int, msg: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(25) #byte 1 int 8 int 8, int 8
	buffer.put_u8(Constants.MessageType.PING)
	
	buffer.put_64(dest_id) # Destination
	buffer.put_64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	
	#message contents
	buffer.put_64(msg["local_time"])
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_ping(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.PING:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_64() # Destination
	res["sender"] = buf.get_64() # sender ID
	res["local_time"] = buf.get_64()
	
	return res

func serialize_ping_back(dest_id: int, msg: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(25) #byte 1 int 8 int 8, int 8
	buffer.put_u8(Constants.MessageType.PING_BACK)
	
	buffer.put_64(dest_id) # Destination
	buffer.put_64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	
	#message contents
	buffer.put_64(msg["local_time"])
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_ping_back(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.PING_BACK:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_64() # Destination
	res["sender"] = buf.get_64() # sender ID
	res["local_time"] = buf.get_64()
	
	return res

func serialize_start(peer_id: int) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(17) #byte 1 int 8 int 8
	buffer.put_u8(Constants.MessageType.START)
	
	buffer.put_64(peer_id) # Destination
	buffer.put_64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_start(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.START:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_64() # Destination
	res["sender"] = buf.get_64() # sender ID
	
	return res

func serialize_stop(peer_id: int) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(17) #byte 1 int 8 int 8
	buffer.put_u8(Constants.MessageType.STOP)
	
	buffer.put_64(peer_id) # Destination
	buffer.put_64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

func unserialize_stop(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.STOP:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_64() # Destination
	res["sender"] = buf.get_64() # sender ID
	
	return res
