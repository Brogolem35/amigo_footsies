extends Node
class_name PlayerInputDummy

@export var flipped: bool = false

var steam_mp_id: int = 1 # Setting this to 0 breaks inputs
var input_prefix := "p1_"
var NetInput :FgInput = null

func _get_local_input() -> Dictionary:
	var movement := (Input.is_action_pressed(prefix("forward")) as int) - (Input.is_action_pressed(prefix("backward")) as int)
	var attack_press := Input.is_action_just_pressed(prefix("attack"))
	var special_press := Input.is_action_just_pressed(prefix("special"))
	
	movement *= -1 if flipped else 1
	
	return {"movement": movement,
			"attack_press": attack_press,
			"special_press": special_press,
	}

func _predict_remote_input(previous_input: Dictionary, ticks_since_real_input: int) -> Dictionary:
	var input = previous_input.duplicate()
	input.set("attack_press", false)
	input.set("special_press", false)
	return input


func _network_process(input: Dictionary) -> void:
	NetInput = FgInput.gd_new(input.get("movement", 0), input.get("attack_press", false), input.get("special_press", false))
	pass

func prefix(input: String) -> String:
	return input_prefix + input
