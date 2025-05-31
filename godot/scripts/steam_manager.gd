extends Node

var is_owned: bool = false
var steam_app_id: int = 480 # Test game app id
var steam_id: int = 0
var steam_username: String = ""
var current_lobby: int = 0
var lobby_members: Array = []
var ready_members: Dictionary[int, Variant] = {}

signal game_start_message(peer_id: int)

func _init():
	print("Init Steam")
	OS.set_environment("SteamAppId", str(steam_app_id))
	OS.set_environment("SteamGameId", str(steam_app_id))

func _ready() -> void:
	var initialize_response: Dictionary = Steam.steamInitEx()
	print("Did Steam Initialize?: %s " % initialize_response)
	
	if initialize_response['status'] > 0:
		printerr("Failed to init Steam! Shutting down. %s" % initialize_response)
		get_tree().quit()
		
	is_owned = Steam.isSubscribed()
	steam_id = Steam.getSteamID()
	steam_username = Steam.getPersonaName()

	print("steam_id %s" % steam_id)
	
	if is_owned == false:
		print("Kinda based")

	Steam.p2p_session_request.connect(_on_p2p_session_request)
	Steam.p2p_session_connect_fail.connect(_on_p2p_session_connect_fail)

func _process(_delta: float) -> void:
	Steam.run_callbacks()
	read_all_p2p_packets()

func is_host() -> bool:
	if !Steam.isLobby(current_lobby):
		return false
	
	return Steam.getLobbyOwner(current_lobby) == Steam.getSteamID()

func is_me(id: int) -> bool:
	return self.steam_id == id

func send_p2p_packet(target: int, packet_data: PackedByteArray) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_UNRELIABLE
	var channel: int = 0
	
	# if target == 45248963703799814:
	# 	printerr(CustomMessageSerializer.message_type(packet_data))
	
	# If sending a packet to everyone
	if target == 0:
		# Loop through all members that aren't you
		for this_member in lobby_members:
			if this_member['steam_id'] != steam_id:
				Steam.sendP2PPacket(this_member['steam_id'], packet_data, send_type, channel)
	# Else send it to someone specific
	else:
		Steam.sendP2PPacket(target, packet_data, send_type, channel)

func make_p2p_handshake() -> void:
	print("Sending P2P handshake to the lobby")
	var packet: PackedByteArray = CustomMessageSerializer.serialize_handshake(steam_id)
	send_p2p_packet(0, packet)

func send_start_message() -> void:
	print("Sending start message to the lobby")
	var host_id := Steam.getLobbyOwner(self.current_lobby)
	var packet: PackedByteArray = CustomMessageSerializer.serialize_menu_start(steam_id)
	send_p2p_packet(host_id, packet)

func read_all_p2p_packets():
	const PACKET_READ_LIMIT := 32
	
	for _i in PACKET_READ_LIMIT:
		if Steam.getAvailableP2PPacketSize(0) == 0:
			break
		
		read_p2p_packet()

func read_p2p_packet() -> void:
	var packet_size: int = Steam.getAvailableP2PPacketSize(0)
	# There is no packet
	if packet_size == 0:
		return
		
	var this_packet: Dictionary = Steam.readP2PPacket(packet_size, 0)
	if this_packet.is_empty() or this_packet == null:
		printerr("WARNING: read an empty packet with non-zero size!")

	var packet_sender: int = this_packet['remote_steam_id']
	var packet_code: PackedByteArray = this_packet['data']
	
	# Identify the message type to parse them properly
	match CustomMessageSerializer.message_type(packet_code):
		Constants.MessageType.HANDSHAKE:
			var handshake: int = CustomMessageSerializer.unserialize_handshake(packet_code)
			print("Received handshake from: ", handshake)
		Constants.MessageType.PING:
			var ping: Dictionary = CustomMessageSerializer.unserialize_ping(packet_code)
			SyncManager.network_adaptor.received_ping.emit(ping["sender"], ping)
		Constants.MessageType.PING_BACK:
			var ping_back: Dictionary = CustomMessageSerializer.unserialize_ping_back(packet_code)
			SyncManager.network_adaptor.received_ping_back.emit(ping_back["sender"], ping_back)
		Constants.MessageType.START:
			print("Constants.MessageType.START")
			var _pack: Dictionary = CustomMessageSerializer.unserialize_start(packet_code)
			SyncManager.network_adaptor.received_remote_start.emit()
		Constants.MessageType.STOP:
			var _pack: Dictionary = CustomMessageSerializer.unserialize_stop(packet_code)
			SyncManager.network_adaptor.received_remote_stop.emit()
		Constants.MessageType.MATCH_INPUT:
			SyncManager.network_adaptor.received_input_tick.emit(packet_sender, packet_code)
		Constants.MessageType.MENU_START:
			# await get_tree().create_timer(5.0).timeout # To test delay related issues
			var _sender: int = CustomMessageSerializer.unserialize_menu_start(packet_code)
			game_start_message.emit(packet_sender)

func leave_lobby() -> void:
	# If in a lobby, leave it
	if current_lobby == 0:
		return
	
	Steam.leaveLobby(current_lobby)
	current_lobby = 0
	
	# Close session with all users
	for this_member in lobby_members:
		# Make sure this isn't your Steam ID
		var member_id: int = this_member['steam_id']
		if member_id != steam_id:
			# Close the P2P session using the Networking class
			Steam.closeP2PSessionWithUser(member_id)
	
	# Clear the local lobby list
	lobby_members.clear()
	ready_members.clear()

func get_lobby_members() -> void:
	# Clear your previous lobby list
	lobby_members.clear()
	# Get the number of members from this lobby from Steam
	var num_of_members: int = Steam.getNumLobbyMembers(current_lobby)
	# Get the data of these players from Steam
	for i in range(0, num_of_members):
		# Get the member's Steam ID
		var member_steam_id: int = Steam.getLobbyMemberByIndex(current_lobby, i)
		# Get the member's Steam name
		var member_steam_name: String = Steam.getFriendPersonaName(member_steam_id)
		# Add them to the list
		lobby_members.append({"steam_id":member_steam_id, "steam_name":member_steam_name})

func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester := Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)
	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)
	# Make the initial handshake
	make_p2p_handshake()

func _on_p2p_session_connect_fail(_steam_id: int, session_error: int) -> void:
	match session_error:
	# If no error was given
		0:
			print("WARNING: Session failure with %s: no error given" % steam_id)
	# Else if target user was not running the same game
		1:
			print("WARNING: Session failure with %s: target user not running the same game" % steam_id)
	# Else if local user doesn't own app / game
		2:
			print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)
	# Else if target user isn't connected to Steam
		3:
			print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)
	# Else if connection timed out
		4:
			print("WARNING: Session failure with %s: connection timed out" % steam_id)
	# Else if unused
		5:
			print("WARNING: Session failure with %s: unused" % steam_id)
	# Else no known error
		_:
			print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])

func state_left(chat_state: int) -> bool:
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT|Steam.CHAT_MEMBER_STATE_CHANGE_KICKED|Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			return true
		_:
			return false
