extends Node2D

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

@onready var round0 = preload("res://art/round_0.png")
@onready var round1 = preload("res://art/round_1.png")

var cont := true
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

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var p1_input := get_inputs(p1_input_type)
	var p2_input := get_inputs(p2_input_type)
	
	if cont:
		var start = Time.get_ticks_usec()
		var res := simulator.frame_update(p1_input, p2_input)
		var s:= simulator.serialize()
		simulator.deserialize(s)
		cont = res == Result.Continue || res == Result.Pause
		
		if graphics:
			var stage_size = stage_borders.size
			player_1.position.x = ((simulator.p1_pos() + STAGE_START) as float) * (stage_size.x / 1872.0)
			player_2.position.x = ((simulator.p2_pos() + STAGE_START) as float) * (stage_size.x / 1872.0)
			
			player_1.texture = load("res://art/fighter/" + simulator.p1_sprite() + ".png")
			player_2.texture = load("res://art/fighter/" + simulator.p2_sprite() + ".png")
			
			round_ui_update(simulator.p1_wins(), simulator.p2_wins())
			
			for audio in simulator.audio():
				play_audio(audio)
		
		var end = Time.get_ticks_usec()
		print(end - start)
	else:
		simulator.new_round()
		if simulator.continues():
			cont = true
		else:
			simulator = Match.gd_new(p1_input_type != PlayerType.Player1, p2_input_type != PlayerType.Player2)

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
				var p1_movement := (Input.is_action_pressed("p1_forward") as int) - (Input.is_action_pressed("p1_backward") as int)
				var p1_attack_press := Input.is_action_just_pressed("p1_attack")
				var p1_attack_hold := Input.is_action_pressed("p1_attack")
				var p1_input := FgInput.gd_new(p1_movement, p1_attack_press, p1_attack_hold)
				return p1_input
			PlayerType.Player2:
				var p2_movement := (Input.is_action_pressed("p2_forward") as int) - (Input.is_action_pressed("p2_backward") as int)
				var p2_attack_press := Input.is_action_just_pressed("p2_attack")
				var p2_attack_hold := Input.is_action_pressed("p2_attack")
				var p2_input := FgInput.gd_new(p2_movement, p2_attack_press, p2_attack_hold)
				return p2_input
			_:
				assert(false, "wait what???")
				return null

func play_audio(audio_path: String):
	var audio_stream = load("res://audio/" + audio_path + ".wav") as AudioStream
	if audio_stream:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = audio_stream
		add_child(audio_player)
		audio_player.play()
		audio_player.finished.connect(func() -> void:
			audio_player.queue_free()
		)

func round_ui_update(p1: int, p2: int):
	p1_round3.texture = round1 if p1 >= 3 else round0
	p1_round2.texture = round1 if p1 >= 2 else round0
	p1_round1.texture = round1 if p1 >= 1 else round0
	
	p2_round3.texture = round1 if p2 >= 3 else round0
	p2_round2.texture = round1 if p2 >= 2 else round0
	p2_round1.texture = round1 if p2 >= 1 else round0

func get_player_obs(p1: bool) -> Array:
	return simulator.player_obs(p1)

func get_punish_obs(p1: bool) -> Array:
	return simulator.punish_obs(p1)
	
