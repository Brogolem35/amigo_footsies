extends Node

var is_owned: bool = false
var steam_app_id: int = 480 # Test game app id
var steam_id: int = 0
var steam_username: String = ""
var current_lobby: int = 0

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

func is_host() -> bool:
	if Steam.isLobby(current_lobby):
		return false
	
	return Steam.getLobbyOwner(current_lobby) == Steam.getSteamID()

func send_p2p_packet(target: int, packet_data: PackedByteArray, lobby_members: Array = []) -> void:
	# Set the send_type and channel
	var send_type: int = Steam.P2P_SEND_RELIABLE
	var channel: int = 0

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

	var packet := PackedByteArray()
	packet.append_array(var_to_bytes({"message": "handshake", "from": steam_id}))

	send_p2p_packet(0, packet)

func _on_p2p_session_request(remote_id: int) -> void:
	# Get the requester's name
	var this_requester := Steam.getFriendPersonaName(remote_id)
	print("%s is requesting a P2P session" % this_requester)
	
	# Accept the P2P session; can apply logic to deny this request if needed
	Steam.acceptP2PSessionWithUser(remote_id)
	
	# Make the initial handshake
	make_p2p_handshake()

func _on_p2p_session_connect_fail(_steam_id: int, session_error: int) -> void:
	# If no error was given
	if session_error == 0:
		print("WARNING: Session failure with %s: no error given" % steam_id)

	# Else if target user was not running the same game
	elif session_error == 1:
		print("WARNING: Session failure with %s: target user not running the same game" % steam_id)

	# Else if local user doesn't own app / game
	elif session_error == 2:
		print("WARNING: Session failure with %s: local user doesn't own app / game" % steam_id)

	# Else if target user isn't connected to Steam
	elif session_error == 3:
		print("WARNING: Session failure with %s: target user isn't connected to Steam" % steam_id)

	# Else if connection timed out
	elif session_error == 4:
		print("WARNING: Session failure with %s: connection timed out" % steam_id)

	# Else if unused
	elif session_error == 5:
		print("WARNING: Session failure with %s: unused" % steam_id)

	# Else no known error
	else:
		print("WARNING: Session failure with %s: unknown error %s" % [steam_id, session_error])
