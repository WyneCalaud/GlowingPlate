extends Control

var step := 0
var player_name := ""

@onready var video = $VideoStreamPlayer
@onready var dialogue_text = $DialogueBox/DialogueText
@onready var btn_next = $DialogueBox/BtnNext
@onready var btn_choice1 = $DialogueBox/BtnChoice1
@onready var btn_choice2 = $DialogueBox/BtnChoice2
@onready var btn_choice1_label = $DialogueBox/BtnChoice1/Label
@onready var btn_choice2_label = $DialogueBox/BtnChoice2/Label
@onready var btn_next_label = $DialogueBox/BtnNext/Label
@onready var name_popup = $NamePopup
@onready var line_edit = $NamePopup/LineEdit
@onready var fade_overlay = $FadeOverlay
@onready var principal = $PrincipalPortrait
@onready var jenna = $JennaPortrait
@onready var dim_background = $DimBackground

var current_character := "principal"


func _ready():
	video.play()
	$DialogueBox.hide()
	$Background.hide()

	principal.hide()
	jenna.hide()

	fade_overlay.modulate.a = 0.0
	dim_background.hide()


func _on_video_stream_player_finished() -> void:

	var tween = create_tween()

	tween.tween_property(fade_overlay, "modulate:a", 10.0, 0.9)

	tween.tween_callback(func():

		video.hide()
		$Background.show()

		fade_overlay.hide()
		principal.show()

		var final_pos = principal.position
		principal.position.x += 700

		var slide_tween = create_tween()
		slide_tween.tween_property(
			principal,
			"position",
			final_pos,
			3.5
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

		slide_tween.finished.connect(func():
			$DialogueBox.show()
			show_step()
		)
	)

	tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.6)


# ===================================================
# MAIN DIALOGUE SYSTEM
# ===================================================

func show_step():

	btn_next.show()
	btn_choice1.hide()
	btn_choice2.hide()
	name_popup.hide()

	match step:

		# ===== NEW INTRO DIALOGUES =====
		0:
			dialogue_text.text = "Wow! The canteen looks so much better now."
			btn_next_label.text = "Next"
		1:
			dialogue_text.text = "Our students will surely enjoy eating here."
			btn_next_label.text = "Next"
		2:
			dialogue_text.text = "Well, hello there! I’m Principal Reyes."
			btn_next_label.text = "Next"
		3:
			dialogue_text.text = "And you must be the new canteen cook..."
			btn_next_label.text = "Yes?"

		4:
			show_name_input()

		5:
			dialogue_text.text = "Welcome, %s! Our school is very excited to have you here." % player_name
			btn_next_label.text = "Thank you!"

		6:
			dialogue_text.text = "You know, our students are in need of meals that are tasty... and healthy too!"
			btn_next_label.text = "Got it!"

		7:
			dialogue_text.text = "Because we want them to grow strong and healthy so they can learn well."
			btn_next_label.text = "Uh huh"

		8:
			dialogue_text.text = "That’s why I’ve chosen you for this important job."
			btn_next_label.text = "Alright"

		9:
			dialogue_text.text = "Ready to start your first day?"
			btn_next.hide()
			btn_choice1.show()
			btn_choice2.show()
			btn_choice1_label.text = "I'm ready!"
			btn_choice2_label.text = "I'm nervous..."

		10:
			dialogue_text.text = "Don’t worry, I know you will do great, %s!" % player_name
			btn_next_label.text = "Thanks!"

		11:
			dialogue_text.text = "Ok! See you next time, %s. Have fun serving our students!" % player_name
			btn_next_label.text = "See you!"

		# ===== JENNA =====
		12:
			dialogue_text.text = "Hello there! My name’s Jenna!"
			btn_next.hide()
			btn_choice1.show()
			btn_choice2.show()
			btn_choice1_label.text = "Hi Jenna!"
			btn_choice2_label.text = "Hello!"

		13:
			dialogue_text.text = "Anyway, my classroom is just across."
			btn_next_label.text = "Okay"

		14:
			dialogue_text.text = "Hehe, I saw the new look of the canteen, so I came here."
			btn_next_label.text = "Nice"

		15:
			dialogue_text.text = "I'd like to try the rice, chicken, sitaw, and mango combo please. Cold water is fine, and don't forget my milk too!"
			btn_next.hide()
			btn_choice1.show()
			btn_choice2.show()
			btn_choice1_label.text = "Okay"
			btn_choice2_label.text = "What"

		16:
			dialogue_text.text = "Give me rice, chicken, sitaw, and mango. My water is cold. And don’t forget my milk please."
			btn_next.show()


# ===================================================
# BUTTONS
# ===================================================

func _on_btn_next_pressed() -> void:

	# --- PRINCIPAL END ---
	if step == 11 and current_character == "principal":
		principal_exit_and_spawn_jenna()
		return

	# --- JENNA FINAL STEP ---
	if step == 16 and current_character == "jenna":
		get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
		return

	step += 1
	show_step()


func _on_btn_choice_1_pressed() -> void:

	if current_character == "principal":
		step = 11
		show_step()
		return

	elif current_character == "jenna":
		if step == 15:
			get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
			return
		step = 14

	show_step()


func _on_btn_choice_2_pressed() -> void:

	if current_character == "principal":
		step = 10

	elif current_character == "jenna":
		if step == 15:
			step = 16
			show_step()
			return
		step = 13

	show_step()


# ===================================================
# NAME INPUT
# ===================================================

func show_name_input():
	btn_next.hide()
	dim_background.show()
	name_popup.show()
	line_edit.text = ""
	line_edit.grab_focus()


func _on_confirmbutton_pressed() -> void:
	player_name = line_edit.text
	if player_name == "":
		return

	GameData.player_name = player_name
	GameData.save_game()
	get_tree().call_group("HUD", "update_all_labels")

	dim_background.hide()

	step += 1
	show_step()


# ===================================================
# CHARACTER ANIMATIONS
# ===================================================

func principal_exit_and_spawn_jenna():

	var exit_tween = create_tween()
	var exit_pos = principal.position
	exit_pos.x += 700

	exit_tween.tween_property(
		principal,
		"position",
		exit_pos,
		0.4
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)

	exit_tween.finished.connect(func():
		principal.hide()
		await get_tree().create_timer(1.0).timeout
		spawn_jenna()
	)


func spawn_jenna():

	current_character = "jenna"
	jenna.show()

	var final_pos = jenna.position
	jenna.position.x += 700

	var enter_tween = create_tween()

	enter_tween.tween_property(
		jenna,
		"position",
		final_pos,
		2.0
	).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	enter_tween.finished.connect(func():
		step = 12
		show_step()
	)
