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
