extends Node2D

func _on_btn_finish_pressed() -> void:
	var GD := get_node("/root/GameData")
	GD.force_hide_accept_buttons = true
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
