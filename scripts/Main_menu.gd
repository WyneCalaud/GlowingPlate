extends Control
@onready var btn_settings: BaseButton = $Background/TopBarRight/SettingsButton
@onready var sound_control: Control = $SoundControl
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
	if button_type == "start":

		var GD = get_node("/root/GameData")

		# 👇 NEW GAME → SHOW INTRO ONLY ONCE
		if not GD.intro_completed and GD.current_day == 1:
			get_tree().change_scene_to_file("res://Scenes/Introduction/intro_scene.tscn")
			return

		match GD.current_phase:

			GD.GamePhase.END_DAY:
				get_tree().change_scene_to_file(GD.END_DAY_SCENE_PATH)

			GD.GamePhase.QUIZ:
				get_tree().change_scene_to_file(GD.QUIZ_SCENE_PATH)

			GD.GamePhase.MATCHING:
				get_tree().change_scene_to_file("res://Scenes/MiniGame/matching_game.tscn")

			GD.GamePhase.NEWS:
				get_tree().change_scene_to_file("res://Scenes/News/news_scene.tscn")

			_:
				get_tree().change_scene_to_file(GD.LOBBY_CANTEEN_PATH)

func _on_settings_button_pressed() -> void:
	if sound_control:
		sound_control.visible = true
		sound_control.move_to_front()
	else:
		printerr("GlowDeskManager: SoundControl node is missing!")
