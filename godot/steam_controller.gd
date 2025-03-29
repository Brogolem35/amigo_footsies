extends Node

func _ready() -> void:
	var res := Steam.steamInit()
	assert(res["status"] == 1, str(res))
	
	assert(Steam.isSteamRunning(), "Steam is not running")
	print(Steam.getFriendPersonaName(Steam.getSteamID()))

func _process(_delta: float) -> void:
	Steam.run_callbacks()
