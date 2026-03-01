extends Control

@export_group("Animation Speeds")
@export var principal_enter_speed: float = 2.0  # (Was 3.5) Time for Principal to slide in
@export var principal_exit_speed: float = 0.3   # (Was 0.4) Time for Principal to slide out
@export var jenna_enter_speed: float = 1.2      # (Was 2.0) Time for Jenna to slide in
@export var transition_delay: float = 0.5       # (Was 1.0) Wait time between Principal leaving and Jenna spawning

var step := 0
var player_name := ""
var is_transitioning := false # NEW: Prevents spam-clicking from breaking the intro

# --- SAFELY FETCH NODES ---
@onready var dialogue_box = get_node_or_null("DialogueBox")
@onready var dialogue_text = get_node_or_null("DialogueBox/DialogueText")
@onready var btn_next = get_node_or_null("DialogueBox/BtnNext")
@onready var btn_choice1 = get_node_or_null("DialogueBox/BtnChoice1")
@onready var btn_choice2 = get_node_or_null("DialogueBox/BtnChoice2")
@onready var btn_choice1_label = get_node_or_null("DialogueBox/BtnChoice1/Label")
@onready var btn_choice2_label = get_node_or_null("DialogueBox/BtnChoice2/Label")
@onready var btn_next_label = get_node_or_null("DialogueBox/BtnNext/Label")
@onready var name_popup = get_node_or_null("NamePopup")
@onready var line_edit = get_node_or_null("NamePopup/LineEdit")
@onready var fade_overlay = get_node_or_null("FadeOverlay")
@onready var principal = get_node_or_null("PrincipalPortrait")
@onready var jenna = get_node_or_null("JennaPortrait")
@onready var dim_background = get_node_or_null("DimBackground")
@onready var background = get_node_or_null("Background")

var current_character := "principal"
var active_tween: Tween 

func _ready() -> void:
	# ⭐ TDR MONITOR FREEZE PROTECTION
	# If these are TextureRects with Keep Aspect Centered, a 0x0 size will crash the GPU!
	if is_instance_valid(principal) and principal is Control:
		if principal.size.x <= 1 or principal.size.y <= 1: principal.size = Vector2(300, 500)
	if is_instance_valid(jenna) and jenna is Control:
		if jenna.size.x <= 1 or jenna.size.y <= 1: jenna.size = Vector2(300, 500)

	# Safely hide elements to start
	if is_instance_valid(dialogue_box): dialogue_box.hide()
	if is_instance_valid(background): background.hide()
	if is_instance_valid(principal): principal.hide()
	if is_instance_valid(jenna): jenna.hide()
	if is_instance_valid(dim_background): dim_background.hide()

	if is_instance_valid(fade_overlay):
		fade_overlay.show()
		fade_overlay.modulate.a = 1.0

	call_deferred("_start_intro_sequence")

func _start_intro_sequence() -> void:
	if is_instance_valid(background): background.show()
	if is_instance_valid(principal): principal.show()

	var final_pos = Vector2.ZERO
	if is_instance_valid(principal):
		final_pos = principal.position
		principal.position.x += 700 

	_kill_active_tween()
	# ⭐ CRASH FIX: bind_node(self) ensures the tween dies INSTANTLY if the scene changes
	active_tween = create_tween().bind_node(self)
	active_tween.set_parallel(true)

	if is_instance_valid(fade_overlay):
		active_tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.6)

	if is_instance_valid(principal):
		active_tween.tween_property(
			principal,
			"position",
			final_pos,
			principal_enter_speed # <--- Changed to Export Variable
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	active_tween.chain().tween_callback(func():
		if not is_inside_tree(): return # Safey check
		if is_instance_valid(fade_overlay): fade_overlay.hide()
		if is_instance_valid(dialogue_box): dialogue_box.show()
		show_step()
	)

# ===================================================
# MAIN DIALOGUE SYSTEM
# ===================================================

func show_step():
	if not is_instance_valid(dialogue_text): return 
	
	if is_instance_valid(btn_next): btn_next.show()
	if is_instance_valid(btn_choice1): btn_choice1.hide()
	if is_instance_valid(btn_choice2): btn_choice2.hide()
	if is_instance_valid(name_popup): name_popup.hide()

	match step:
		0:
			dialogue_text.text = "Wow! The canteen looks so much better now."
			_set_next_btn("Next")
		1:
			dialogue_text.text = "Our students will surely enjoy eating here."
			_set_next_btn("Next")
		2:
			dialogue_text.text = "Well, hello there! I’m Principal Reyes."
			_set_next_btn("Next")
		3:
			dialogue_text.text = "And you must be the new canteen cook..."
			_set_next_btn("Yes?")
		4:
			show_name_input()
		5:
			dialogue_text.text = "Welcome, %s! Our school is very excited to have you here." % player_name
			_set_next_btn("Thank you!")
		6:
			dialogue_text.text = "You know, our students are in need of meals that are tasty... and healthy too!"
			_set_next_btn("Got it!")
		7:
			dialogue_text.text = "Because we want them to grow strong and healthy so they can learn well."
			_set_next_btn("Uh huh")
		8:
			dialogue_text.text = "That’s why I’ve chosen you for this important job."
			_set_next_btn("Alright")
		9:
			dialogue_text.text = "Ready to start your first day?"
			_setup_choices("I'm ready!", "I'm nervous...")
		10:
			dialogue_text.text = "Don’t worry, I know you will do great, %s!" % player_name
			_set_next_btn("Thanks!")
		11:
			dialogue_text.text = "Ok! See you next time, %s. Have fun serving our students!" % player_name
			_set_next_btn("See you!")

		# ===== JENNA =====
		12:
			dialogue_text.text = "Hello there! My name’s Jenna!"
			_setup_choices("Hi Jenna!", "Hello!")
		13:
			dialogue_text.text = "Anyway, my classroom is just across."
			_set_next_btn("Okay")
		14:
			dialogue_text.text = "Hehe, I saw the new look of the canteen, so I came here."
			_set_next_btn("Nice")
		15:
			dialogue_text.text = "I'd like to try the rice, chicken, sitaw, and mango combo please. Cold water is fine, and don't forget my milk too!"
			_setup_choices("Okay", "What")
		16:
			dialogue_text.text = "Give me rice, chicken, sitaw, and mango. My water is cold. And don’t forget my milk please."
			_set_next_btn("Next")

func _set_next_btn(txt: String):
	if is_instance_valid(btn_next_label): btn_next_label.text = txt

func _setup_choices(txt1: String, txt2: String):
	if is_instance_valid(btn_next): btn_next.hide()
	if is_instance_valid(btn_choice1): btn_choice1.show()
	if is_instance_valid(btn_choice2): btn_choice2.show()
	if is_instance_valid(btn_choice1_label): btn_choice1_label.text = txt1
	if is_instance_valid(btn_choice2_label): btn_choice2_label.text = txt2

# ===================================================
# BUTTONS
# ===================================================

func _on_btn_next_pressed() -> void:
	if is_transitioning: return # Prevent spam click issues

	if step == 11 and current_character == "principal":
		principal_exit_and_spawn_jenna()
		return

	if step == 16 and current_character == "jenna":
		_finish_intro_and_load_canteen()
		return

	step += 1
	show_step()

func _on_btn_choice_1_pressed() -> void:
	if is_transitioning: return
	
	if current_character == "principal":
		step = 11
		show_step()
		return
	elif current_character == "jenna":
		if step == 15:
			_finish_intro_and_load_canteen()
			return
		step = 14

	show_step()

func _on_btn_choice_2_pressed() -> void:
	if is_transitioning: return
	
	if current_character == "principal":
		step = 10
	elif current_character == "jenna":
		if step == 15:
			step = 16
			show_step()
			return
		step = 13

	show_step()

func _finish_intro_and_load_canteen():
	is_transitioning = true
	_kill_active_tween() 
	
	var err = get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
	if err != OK:
		printerr("Failed to load Canteen scene from Intro! Error Code: ", err)

# ===================================================
# NAME INPUT
# ===================================================

func show_name_input():
	if is_instance_valid(btn_next): btn_next.hide()
	if is_instance_valid(dim_background): dim_background.show()
	if is_instance_valid(name_popup): name_popup.show()
	
	if is_instance_valid(line_edit):
		line_edit.text = ""
		line_edit.grab_focus()

func _on_confirmbutton_pressed() -> void:
	if not is_instance_valid(line_edit): return
	
	player_name = line_edit.text.strip_edges() 
	if player_name == "":
		return

	if has_node("/root/GameData"):
		GameData.player_name = player_name
		GameData.save_game()
	else:
		printerr("GameData AutoLoad missing! Cannot save player name.")

	get_tree().call_group("HUD", "update_all_labels")

	if is_instance_valid(dim_background): dim_background.hide()

	step += 1
	show_step()

# ===================================================
# CHARACTER ANIMATIONS
# ===================================================

func principal_exit_and_spawn_jenna():
	is_transitioning = true # Lock inputs
	
	if not is_instance_valid(principal): 
		spawn_jenna()
		return

	_kill_active_tween()
	active_tween = create_tween().bind_node(self)
	
	var exit_pos = principal.position
	exit_pos.x += 700

	# ⭐ CRASH FIX: Using tween_callback instead of .finished.connect guarantees 
	# that the tween safely unloads without dangling signal calls.
	active_tween.tween_property(principal, "position", exit_pos, principal_exit_speed).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	active_tween.tween_callback(func():
		if is_instance_valid(principal): principal.hide()
	)
	
	# Incorporating the "wait_tween" directly into the active tween chain
	active_tween.tween_interval(transition_delay) # <--- Changed to Export Variable
	
	active_tween.tween_callback(func():
		if is_inside_tree(): spawn_jenna()
	)

func spawn_jenna():
	current_character = "jenna"
	
	if not is_instance_valid(jenna):
		is_transitioning = false
		step = 12
		show_step()
		return

	jenna.show()
	var final_pos = jenna.position
	jenna.position.x += 700

	_kill_active_tween()
	active_tween = create_tween().bind_node(self)

	active_tween.tween_property(jenna, "position", final_pos, jenna_enter_speed).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT) # <--- Changed to Export Variable

	active_tween.tween_callback(func():
		if is_inside_tree():
			is_transitioning = false # Unlock inputs
			step = 12
			show_step()
	)

# ===================================================
# UTILITIES
# ===================================================
func _kill_active_tween():
	if active_tween and active_tween.is_valid():
		active_tween.kill()

func _exit_tree() -> void:
	_kill_active_tween()
