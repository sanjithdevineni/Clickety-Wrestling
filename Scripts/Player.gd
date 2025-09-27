extends Node
@export var player_id := 1  # set 1 on Player1, 2 on Player2
var input_map := {
	1: {"up":"p1_up","down":"p1_down","left":"p1_left","right":"p1_right"},
	2: {"up":"p2_up","down":"p2_down","left":"p2_left","right":"p2_right"}
}
@onready var gm := $"../GameManager"

func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and event is InputEventKey:
		for dir in ["up","down","left","right"]:
			if Input.is_action_just_pressed(input_map[player_id][dir]):
				gm.on_player_tap(player_id, dir)
