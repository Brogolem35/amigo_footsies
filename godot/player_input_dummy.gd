extends Node
class_name PlayerInputDummy

var NetInput :FgInput = null

func _get_local_input() -> Dictionary:
	var movement := (Input.is_action_pressed("p1_forward") as int) - (Input.is_action_pressed("p1_backward") as int)
	var attack_press := Input.is_action_just_pressed("p1_attack")
	var attack_hold := Input.is_action_pressed("p1_attack")
	
	return {"movement": movement,
			"attack_press": attack_press,
			"attack_hold": attack_hold,
	}

func _network_process(input: Dictionary) -> void:
	NetInput = FgInput.gd_new(input.get("movement", 0), input.get("attack_press", false), input.get("attack_hold", false))
	pass
