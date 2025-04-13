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

static func message_type(serialized: PackedByteArray) -> Constants.MessageType:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	
	return buf.get_u8()

func serialize_input(all_input: Dictionary) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.resize(16)
	
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

func serialize_message(msg: Dictionary) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.resize(DEFAULT_MESSAGE_BUFFER_SIZE)
	buf.put_u8(Constants.MessageType.MATCH_INPUT)

	buf.put_u32(msg[InputMessageKey.NEXT_INPUT_TICK_REQUESTED])

	if msg.has(InputMessageKey.INPUT):
		var input_ticks = msg[InputMessageKey.INPUT]
		buf.put_u8(input_ticks.size())
		if input_ticks.size() > 0:
			var input_keys = input_ticks.keys()
			input_keys.sort()
			buf.put_u32(input_keys[0])
			for input_key in input_keys:
				var input = input_ticks[input_key]
				buf.put_u16(input.size())
				buf.put_data(input)
	else:
		buf.put_u8(0)

	buf.put_u32(msg[InputMessageKey.NEXT_HASH_TICK_REQUESTED])

	if msg.has(InputMessageKey.STATE_HASHES):
		var state_hashes = msg[InputMessageKey.STATE_HASHES]
		buf.put_u8(state_hashes.size())
		if state_hashes.size() > 0:
			var state_hash_keys = state_hashes.keys()
			state_hash_keys.sort()
			buf.put_u32(state_hash_keys[0])
			for state_hash_key in state_hash_keys:
				buf.put_u32(state_hashes[state_hash_key])
	else:
		buf.put_u8(0)

	buf.resize(buf.get_position())
	return buf.data_array

func unserialize_message(serialized) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)

	if buf.get_u8() != Constants.MessageType.MATCH_INPUT:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}

	var msg := {
		InputMessageKey.INPUT: {},
		InputMessageKey.STATE_HASHES: {},
	}

	msg[InputMessageKey.NEXT_INPUT_TICK_REQUESTED] = buf.get_u32()

	var input_tick_count = buf.get_u8()
	if input_tick_count > 0:
		var input_tick = buf.get_u32()
		for input_tick_index in range(input_tick_count):
			var input_size = buf.get_u16()
			msg[InputMessageKey.INPUT][input_tick] = buf.get_data(input_size)[1]
			input_tick += 1

	msg[InputMessageKey.NEXT_HASH_TICK_REQUESTED] = buf.get_u32()

	var hash_tick_count = buf.get_u8()
	if hash_tick_count > 0:
		var hash_tick = buf.get_u32()
		for hash_tick_index in range(hash_tick_count):
			msg[InputMessageKey.STATE_HASHES][hash_tick] = buf.get_u32()
			hash_tick += 1

	return msg

static func serialize_handshake(peer_id: int) -> PackedByteArray:
	var buf := StreamPeerBuffer.new()
	buf.resize(9)
	buf.put_u8(Constants.MessageType.HANDSHAKE)
	buf.put_u64(peer_id)
	
	return buf.data_array

# 0 if error
static func unserialize_handshake(serialized: PackedByteArray) -> int:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	
	if buf.get_u8() != Constants.MessageType.HANDSHAKE:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return 0
	
	return buf.get_u64()

# https://github.com/hislittlecuzin/Snopek-Rollback-Steamworks-FP-Template/blob/main/Scripts/Netcode/SteamMessageSerializer.gd
static func serialize_ping(peer_id: int, msg: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(25) #byte 1 int 8 int 8, int 8
	buffer.put_u8(Constants.MessageType.PING)
	
	buffer.put_u64(peer_id) # Destination
	buffer.put_u64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	buffer.put_u64(msg["local_time"])
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

static func unserialize_ping(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.PING:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_u64() # Destination
	res["sender"] = buf.get_u64() # sender ID
	res["local_time"] = buf.get_u64()
	
	return res

static func serialize_ping_back(peer_id: int, msg: Dictionary) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(33) #byte 1 int 8 int 8 int 8 int 8
	buffer.put_u8(Constants.MessageType.PING_BACK)
	
	buffer.put_u64(peer_id) # Destination
	buffer.put_u64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	buffer.put_u64(msg["local_time"])
	buffer.put_u64(msg["remote_time"])
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

static func unserialize_ping_back(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.PING_BACK:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_u64() # Destination
	res["sender"] = buf.get_u64() # sender ID
	res["local_time"] = buf.get_u64()
	res["remote_time"] = buf.get_u64()
	
	return res

static func serialize_start(peer_id: int) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(17) #byte 1 int 8 int 8
	buffer.put_u8(Constants.MessageType.START)
	
	buffer.put_u64(peer_id) # Destination
	buffer.put_u64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

static func unserialize_start(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.START:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_u64() # Destination
	res["sender"] = buf.get_u64() # sender ID
	
	return res

static func serialize_stop(peer_id: int) -> PackedByteArray:
	var buffer := StreamPeerBuffer.new()
	buffer.resize(17) #byte 1 int 8 int 8
	buffer.put_u8(Constants.MessageType.STOP)
	
	buffer.put_u64(peer_id) # Destination
	buffer.put_u64(SyncManager.network_adaptor.get_unique_id()) # sender ID
	
	#resize and return.
	buffer.resize(buffer.get_position())
	return buffer.data_array

static func unserialize_stop(serialized: PackedByteArray) -> Dictionary:
	var buf := StreamPeerBuffer.new()
	buf.put_data(serialized)
	buf.seek(0)
	# Type check
	if buf.get_u8() != Constants.MessageType.STOP:
		SyncManager._handle_fatal_error("Invalid PackedByteArray tag")
		return {}
	
	var res = {}
	res["receiver"] = buf.get_u64() # Destination
	res["sender"] = buf.get_u64() # sender ID
	
	return res
