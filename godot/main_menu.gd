extends Node

const BATTLE_SCENE = preload("res://battle_scene.tscn")

@onready var connection_panel = $CanvasLayer/ConnectionPanel
@onready var host_field = $CanvasLayer/ConnectionPanel/GridContainer/HostField
@onready var port_field = $CanvasLayer/ConnectionPanel/GridContainer/PortField
@onready var message_label = $CanvasLayer/MessageLabel
@onready var reset_button: Button = $CanvasLayer/ResetButton
@onready var sync_label: Label = $CanvasLayer/SyncLabel

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_network_peer_connected)
	multiplayer.peer_disconnected.connect(_on_network_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	SyncManager.sync_started.connect(_on_SyncManager_sync_started)
	SyncManager.sync_stopped.connect(_on_SyncManager_sync_stopped)
	SyncManager.sync_lost.connect(_on_SyncManager_sync_lost)
	SyncManager.sync_regained.connect(_on_SyncManager_sync_regained)
	SyncManager.sync_error.connect(_on_SyncManager_sync_error)

func _on_host_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(int(port_field.text), 1)
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Listening..."


func _on_connect_button_pressed() -> void:
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(host_field.text, int(port_field.text))
	multiplayer.multiplayer_peer = peer
	connection_panel.visible = false
	message_label.text = "Connecting..."

var game: BattleScene = null
func _on_network_peer_connected(peer_id: int):
	message_label.text = "Connected!"
	SyncManager.add_peer(peer_id)
	
	game = BATTLE_SCENE.instantiate()
	get_parent().add_child(game)
	game.player1_input_dummy.set_multiplayer_authority(1)
	if SyncManager.network_adaptor.is_network_host():
		game.player2_input_dummy.set_multiplayer_authority(peer_id)
	else:
		game.player2_input_dummy.set_multiplayer_authority(SyncManager.network_adaptor.get_unique_id())
	
	if SyncManager.network_adaptor.is_network_host():
		message_label.text = "Starting..."
		# Give a little time to get ping data.
		await get_tree().create_timer(2.0).timeout
		SyncManager.start()

func _on_network_peer_disconnected(peer_id: int):
	message_label.text = "Disconnected!"
	SyncManager.remove_peer(peer_id)

func _on_server_disconnected():
	_on_network_peer_disconnected(1)

func _on_reset_button_pressed() -> void:
	SyncManager.stop()
	SyncManager.clear_peers()
	var peer := multiplayer.multiplayer_peer
	if peer:
		peer.close()
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
