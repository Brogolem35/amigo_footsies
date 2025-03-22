extends Node2D
class_name BattleScene

const STAGE_START := -200

@onready var stage_borders = $CanvasLayer/Panel/StageBorders
@onready var player_1 = $CanvasLayer/Panel/StageBorders/Player1
@onready var player_2 = $CanvasLayer/Panel/StageBorders/Player2
@onready var p1_round1 = $CanvasLayer/Rounds/P1Round1
@onready var p1_round2 = $CanvasLayer/Rounds/P1Round2
@onready var p1_round3 = $CanvasLayer/Rounds/P1Round3
@onready var p2_round3 = $CanvasLayer/Rounds/P2Round3
@onready var p2_round2 = $CanvasLayer/Rounds/P2Round2
@onready var p2_round1 = $CanvasLayer/Rounds/P2Round1
@onready var player1_input_dummy: PlayerInputDummy = $Player1InputDummy
@onready var player2_input_dummy: PlayerInputDummy = $Player2InputDummy
@onready var p1_meter: Label = $CanvasLayer/Panel/Meters/P1Meter
@onready var p2_meter: Label = $CanvasLayer/Panel/Meters/P2Meter

@onready var round0 = preload("res://art/round_0.png")
@onready var round1 = preload("res://art/round_1.png")

var simulator: Match

@export var graphics : bool = true
@export var player1_bot: bool = false
@export var player2_bot: bool = false

var p1_input_type: PlayerType
var p2_input_type: PlayerType

# Called when the node enters the scene tree for the first time.
func _ready():
	simulator = Match.gd_new(player1_bot, player1_bot)
	
	p1_input_type = PlayerType.Player1 if !player1_bot else PlayerType.Ai1
	p2_input_type = PlayerType.Player2 if !player2_bot else PlayerType.Ai2

func _process(delta: float) -> void:
	var stage_size = stage_borders.size
	player_1.position.x = ((simulator.p1_pos() + STAGE_START) as float) * (stage_size.x / 1872.0)
	player_2.position.x = ((simulator.p2_pos() + STAGE_START) as float) * (stage_size.x / 1872.0)
	
	player_1.texture = load("res://art/fighter/" + simulator.p1_sprite() + ".png")
	player_2.texture = load("res://art/fighter/" + simulator.p2_sprite() + ".png")
	
	meter_ui_update(simulator.p1_meter(), simulator.p2_meter())
	round_ui_update(simulator.p1_wins(), simulator.p2_wins())

func _get_local_input() -> Dictionary:
	return {}

func _network_postprocess(_input: Dictionary) -> void:
	var p1_input := get_inputs(p1_input_type)
	var p2_input := get_inputs(p2_input_type)
	
	# var start = Time.get_ticks_usec()
	var res := simulator.frame_update(p1_input, p2_input)
	var cont := res == Result.Continue || res == Result.Pause
	for audio in simulator.audio():
		play_audio(audio)
	
	# var end = Time.get_ticks_usec()
	# print(end - start)
	if !cont:
		simulator.new_round()
		if simulator.continues():
			cont = true
		else:
			simulator = Match.gd_new(p1_input_type != PlayerType.Player1, p2_input_type != PlayerType.Player2)

func _save_state() -> Dictionary:
	return { "match_state": simulator.serialize_bin() }

func _load_state(state: Dictionary) -> void:
	simulator.deserialize_bin(state["match_state"])


enum Result {
	Continue,
	Pause,
	Player1,
	Player2,
	Draw,
	Timeout,
}

enum PlayerType {
	Player1,
	Player2,
	Ai1,
	Ai2,
}

func get_inputs(type: PlayerType) -> FgInput:
		match type:
			PlayerType.Player1:
				return player1_input_dummy.NetInput
			PlayerType.Player2:
				return player2_input_dummy.NetInput
			_:
				assert(false, "wait what???")
				return null

func play_audio(audio_id: String):
	var split := audio_id.split(":")
	var player_id := split[0]
	var audio_path := split[1]
	
	var audio_stream = load("res://audio/" + audio_path + ".wav") as AudioStream
	if audio_stream:
		SyncManager.play_sound(audio_id, audio_stream)

func round_ui_update(p1: int, p2: int):
	p1_round3.texture = round1 if p1 >= 3 else round0
	p1_round2.texture = round1 if p1 >= 2 else round0
	p1_round1.texture = round1 if p1 >= 1 else round0
	
	p2_round3.texture = round1 if p2 >= 3 else round0
	p2_round2.texture = round1 if p2 >= 2 else round0
	p2_round1.texture = round1 if p2 >= 1 else round0

func meter_ui_update(p1: int, p2: int):
	p1_meter.text = "%d.%d%%" % [p1 / 10, p1 % 10]
	p2_meter.text = "%d.%d%%" % [p2 / 10, p2 % 10]

func get_player_obs(p1: bool) -> Array:
	return simulator.player_obs(p1)

func get_punish_obs(p1: bool) -> Array:
	return simulator.punish_obs(p1)
	
