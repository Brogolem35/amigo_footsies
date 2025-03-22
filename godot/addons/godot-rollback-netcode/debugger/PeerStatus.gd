extends Control

@onready var peer_id_field = $VBoxContainer/GridContainer/PeerIdValue
@onready var rtt_field = $VBoxContainer/GridContainer/RTTValue
@onready var local_lag_field = $VBoxContainer/GridContainer/LocalLagValue
@onready var remote_lag_field = $VBoxContainer/GridContainer/RemoteLagValue
@onready var advantage_field = $VBoxContainer/GridContainer/AdvantageValue
@onready var messages_field = $VBoxContainer/MessagesValue

func update_peer(peer: SyncManager.Peer) -> void:
	peer_id_field.text = str(peer.peer_id)
	rtt_field.text = str(peer.rtt) + " ms"
	local_lag_field.text = str(peer.local_lag)
	remote_lag_field.text = str(peer.remote_lag)
	advantage_field.text = str(peer.calculated_advantage)

# Ring buffer at home
var _messages := PackedStringArray()
const _messages_len := 100
func add_message(msg: String) -> void:
	_messages.append("* " + msg)
	if len(_messages) > _messages_len:
		_messages.remove_at(0)
	
	messages_field.text = "\n".join(_messages)
