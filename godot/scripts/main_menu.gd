extends Node

const BATTLE_SCENE = preload("res://battle_scene.tscn")
const DUMMY_NETWORK_ADAPTER = preload("res://addons/godot-rollback-netcode/DummyNetworkAdaptor.gd")

@onready var mode_menu: HBoxContainer = $CanvasLayer/ModeMenu
@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var lobby_field = $CanvasLayer/ConnectionPanel/GridContainer/LobbyField
@onready var message_label = $CanvasLayer/MessageLabel
@onready var reset_button: Button = $CanvasLayer/ResetButton
@onready var sync_label: Label = $CanvasLayer/SyncLabel
@onready var fps_label: Label = $CanvasLayer/FPSLabel

func _ready() -> void:
	Steam.lobby_created.connect(_on_lobby_created)
	Steam.lobby_joined.connect(_on_lobby_joined)
	Steam.lobby_chat_update.connect(_on_lobby_updated)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	SyncManager.sync_started.connect(_on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(_on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(_on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(_on_SyncManager_sync_error)

func _process(_delta: float) -> void:
	fps_label.text = str(Engine.get_frames_per_second())

func _on_host_button_pressed() -> void:
	Steam.createLobby(Steam.LOBBY_TYPE_PUBLIC, 2)

func _on_connect_button_pressed() -> void:
	Steam.joinLobby(int(lobby_field.text))
	mode_menu.visible = false
	connection_panel.visible = false

func _on_network_peer_disconnected(peer_id: int):
	message_label.text = "Disconnected!"
	SyncManager.remove_peer(peer_id)

func _on_server_disconnected():
	_on_network_peer_disconnected(1)

func _on_reset_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	if SteamManagerStatic.current_lobby:
		SteamManagerStatic.leave_lobby()
	get_tree().reload_current_scene()
	
func _on_SyncManager_sync_started():
	message_label.text = "Started"
	
func _on_SyncManager_sync_stopped():
	pass

func _on_SyncManager_sync_lost():
	sync_label.visible = true

func _on_SyncManager_sync_regained():
	sync_label.visible = false

func _on_SyncManager_sync_error(msg: String):
	sync_label.text = "Fatal sync error: " + msg
	sync_label.visible = true
	
	var peer = multiplayer.multiplayer_peer
	if peer:
		peer.close()
	SyncManager.clear_peers()

@warning_ignore("shadowed_variable_base_class")
func _on_lobby_created(connect: int, lobby_id: int):
	print("On lobby created")
	if connect != 1:
		printerr("Something went wrong on _on_lobby_created: ", connect)
		return
	
	Steam.setLobbyJoinable(lobby_id, true)
	Steam.setLobbyData(lobby_id, "name", "LOBBY_NAME")
	Steam.setLobbyData(lobby_id, "mode", "LOBBY_MODE")
	print("Created lobby: %s" % lobby_id)
	message_label.text = "Created lobby: %s" % lobby_id
	DisplayServer.clipboard_set(str(lobby_id))
	
	mode_menu.visible = false
	connection_panel.visible = false

func _on_lobby_joined(lobby: int, _permissions: int, _locked: bool, response: int):
	print("On lobby joined")
	
	if response == Steam.CHAT_ROOM_ENTER_RESPONSE_SUCCESS:
		SteamManagerStatic.current_lobby = lobby
		SteamManagerStatic.get_lobby_members()
		SteamManagerStatic.make_p2p_handshake()
		
		if SteamManagerStatic.lobby_members.size() == 2:
			start_game()
	else:
		# Get the failure reason
		var FAIL_REASON: String
		match response:
			2:  FAIL_REASON = "This lobby no longer exists."
			3:  FAIL_REASON = "You don't have permission to join this lobby."
			4:  FAIL_REASON = "The lobby is now full."
			5:  FAIL_REASON = "Uh... something unexpected happened!"
			6:  FAIL_REASON = "You are banned from this lobby."
			7:  FAIL_REASON = "You cannot join due to having a limited account."
			8:  FAIL_REASON = "This lobby is locked or disabled."
			9:  FAIL_REASON = "This lobby is community locked."
			10: FAIL_REASON = "A user in the lobby has blocked you from joining."
			11: FAIL_REASON = "A user you have blocked is in the lobby."
		print(FAIL_REASON)

func _on_lobby_updated(_lobby: int, changer_id: int, _making_change_id: int, chat_state: int):
	var changer_name: String = Steam.getFriendPersonaName(changer_id)
	
	if !SteamManagerStatic.is_me(changer_id) && SteamManagerStatic.state_left(chat_state):
		Steam.closeP2PSessionWithUser(changer_id)
	
	match chat_state:
		Steam.CHAT_MEMBER_STATE_CHANGE_ENTERED:
			print("%s has joined the lobby." % changer_name)
		Steam.CHAT_MEMBER_STATE_CHANGE_LEFT:
			print("%s has left the lobby." % changer_name)
		Steam.CHAT_MEMBER_STATE_CHANGE_KICKED:
			print("%s has been kicked from the lobby." % changer_name)
		Steam.CHAT_MEMBER_STATE_CHANGE_BANNED:
			print("%s has been kicked from the lobby." % changer_name)
	
	if SteamManagerStatic.current_lobby == 0:
		return
	
	SteamManagerStatic.get_lobby_members()
	printerr(SyncManager.started)
	if !SyncManager.started && SteamManagerStatic.lobby_members.size() == 2:
		start_game()

func start_game():
	message_label.text = "Connected!"
	
	for m in SteamManagerStatic.lobby_members:
		var id: int = m['steam_id']
		if id != SteamManagerStatic.steam_id:
			SyncManager.add_peer(id)
	print(SyncManager.peers)
	
	var game = BATTLE_SCENE.instantiate()
	add_child(game)
	game.player1_input_dummy.steam_mp_id = SteamManagerStatic.lobby_members[0]['steam_id']
	game.player2_input_dummy.steam_mp_id = SteamManagerStatic.lobby_members[1]['steam_id']
	
	if SyncManager.network_adaptor.is_network_host():
		message_label.text = "Starting..."
		# Give a little time to get ping data.
		await get_tree().create_timer(5.0).timeout
		SyncManager.start()

func _on_online_button_pressed() -> void:
	mode_menu.visible = false
	connection_panel.visible = true
	SyncManager.reset_network_adaptor()


func _on_local_button_pressed() -> void:
	mode_menu.visible = false
	SyncManager.network_adaptor = DUMMY_NETWORK_ADAPTER.new()
	var game = BATTLE_SCENE.instantiate()
	add_child(game)
	game.player2_input_dummy.input_prefix = "p2_"
	SyncManager.start()
