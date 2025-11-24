extends Node2D

var button_type = null

func _on_start_pressed() -> void:
	button_type = "start"
	$fade_transition.show()
	$fade_transition/Fade_timer.start()
	$fade_transition/AnimationPlayer.play("Fade_In")


func _on_settings_pressed() -> void:
	button_type = "options"
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_In")


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_fade_timer_timeout() -> void:
	if button_type == "start" :
		get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
	
