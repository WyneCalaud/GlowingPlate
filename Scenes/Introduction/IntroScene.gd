extends Control

@export_group("Animation Speeds")
@export var principal_enter_speed: float = 2.0  
@export var principal_exit_speed: float = 0.3   
@export var jenna_enter_speed: float = 1.2      
@export var transition_delay: float = 0.5       

# NEW: Dialogue Settings & Texture Slots
@export_group("Dialogue Box & Text Settings")
@export var text_speed_per_word: float = 0.15 # Equivalent to typing_speed

@export_subgroup("Box Textures")
@export var box_texture_small: Texture2D      # Slot for the Small Box
@export var box_texture_medium: Texture2D     # Slot for the Medium Box
@export var box_texture_large: Texture2D      # Slot for the Large Box

@export_subgroup("Box Offsets (Tweaks)")
# These values will just NUDGE the box from its original position
@export var box_offset_small: Vector2 = Vector2(0, 20)   
@export var box_offset_large: Vector2 = Vector2(0, 0)   

var step := 0
var player_name := ""
var is_transitioning := false 
var base_box_position := Vector2.ZERO # Saves the original position from the editor

# NEW: Saves the original button positions
var base_btn_next_pos := Vector2.ZERO
var base_btn_choice1_pos := Vector2.ZERO
var base_btn_choice2_pos := Vector2.ZERO

# Typewriter state variables
var is_typing := false
var full_dialogue_text := ""
var typewriter_id := 0

# --- SAFELY FETCH NODES ---
@onready var dialogue_box = get_node_or_null("DialogueBox")
@onready var dialogue_text = get_node_or_null("DialogueText")
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
	if is_instance_valid(principal) and principal is Control:
		if principal.size.x <= 1 or principal.size.y <= 1: principal.size = Vector2(300, 500)
	if is_instance_valid(jenna) and jenna is Control:
		if jenna.size.x <= 1 or jenna.size.y <= 1: jenna.size = Vector2(300, 500)

	if is_instance_valid(dialogue_box): 
		# Save the exact position you set up in the editor!
		base_box_position = dialogue_box.position
		dialogue_box.hide()

	# Save the default positions of the buttons so we can revert back to them
	if is_instance_valid(btn_next): base_btn_next_pos = btn_next.position
	if is_instance_valid(btn_choice1): base_btn_choice1_pos = btn_choice1.position
	if is_instance_valid(btn_choice2): base_btn_choice2_pos = btn_choice2.position

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
	active_tween = create_tween().bind_node(self)
	active_tween.set_parallel(true)

	if is_instance_valid(fade_overlay):
		active_tween.tween_property(fade_overlay, "modulate:a", 0.0, 0.6)

	if is_instance_valid(principal):
		active_tween.tween_property(
			principal,
			"position",
			final_pos,
			principal_enter_speed
		).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	active_tween.chain().tween_callback(func():
		if not is_inside_tree(): return 
		if is_instance_valid(fade_overlay): fade_overlay.hide()
		if is_instance_valid(dialogue_box): dialogue_box.show()
		show_step()
	)

# ===================================================
# TYPEWRITER & MANUAL TEXTURE SWAP LOGIC
# ===================================================
func _play_dialogue(text_content: String, box_size_type: String = "medium"):
	if not is_instance_valid(dialogue_text): return
	
	# 1. Determine which texture to use and apply the NUDGE offset
	var target_texture: Texture2D = null
	var target_position: Vector2 = base_box_position # Start at the default editor position
	
	match box_size_type.to_lower():
		"small": 
			target_texture = box_texture_small
			target_position = base_box_position + box_offset_small # Apply the tweak!
		"large": 
			target_texture = box_texture_large
			target_position = base_box_position + box_offset_large # Apply the tweak!
		_: 
			target_texture = box_texture_medium 
			# Medium stays exactly at the base_box_position (no offset applied)
		
	# 2. Apply the texture, nudged position, and add a small bouncy effect
	if is_instance_valid(dialogue_box):
		if target_texture != null and "texture" in dialogue_box:
			dialogue_box.texture = target_texture
			
		# Apply the nudged position
		dialogue_box.position = target_position
		
		# Move the buttons specifically for the large box, otherwise reset them to normal
		if box_size_type.to_lower() == "large":
			if is_instance_valid(btn_next): btn_next.position = Vector2(261.0, 296.0)
			if is_instance_valid(btn_choice1): btn_choice1.position = Vector2(116.0, 295.0)
			if is_instance_valid(btn_choice2): btn_choice2.position = Vector2(419.0, 296.0)
		else:
			if is_instance_valid(btn_next): btn_next.position = base_btn_next_pos
			if is_instance_valid(btn_choice1): btn_choice1.position = base_btn_choice1_pos
			if is_instance_valid(btn_choice2): btn_choice2.position = base_btn_choice2_pos
		
		# Update the pivot offset dynamically so the bounce is always centered
		dialogue_box.pivot_offset = dialogue_box.size / 2.0 
			
		# Little pop animation to make the box swap feel alive
		dialogue_box.scale = Vector2(0.95, 0.95)
		var box_tween = create_tween().bind_node(self)
		box_tween.tween_property(dialogue_box, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 3. Call your custom typewriter animation
	typewriter_words(text_content)

# Your requested typewriter function
func typewriter_words(text: String) -> void:
	is_typing = true
	full_dialogue_text = text
	
	if is_instance_valid(dialogue_text):
		dialogue_text.text = ""
		# Ensure we show all characters instead of relying on visible_characters
		dialogue_text.visible_characters = -1 

	# Update ID to cancel any previously running typewriter loop
	typewriter_id += 1
	var current_id = typewriter_id

	var words: PackedStringArray = text.split(" ")
	var built_text: String = ""

	for i in words.size():
		# Safety check: Break loop if skipped OR if a new dialogue started
		if not is_typing or current_id != typewriter_id:
			break
			
		built_text += words[i]

		if i < words.size() - 1:
			built_text += " "

		if is_instance_valid(dialogue_text):
			dialogue_text.text = built_text

		await get_tree().create_timer(text_speed_per_word).timeout

	# Only set to false if it finished naturally (wasn't interrupted)
	if current_id == typewriter_id:
		is_typing = false

func _skip_typing():
	# Setting this to false instantly breaks the loop inside typewriter_words()
	is_typing = false
	
	if is_instance_valid(dialogue_text):
		dialogue_text.text = full_dialogue_text

# ===================================================
# MAIN DIALOGUE SYSTEM
# ===================================================

func show_step():
	if is_instance_valid(btn_next): btn_next.show()
	if is_instance_valid(btn_choice1): btn_choice1.hide()
	if is_instance_valid(btn_choice2): btn_choice2.hide()
	if is_instance_valid(name_popup): name_popup.hide()

	match step:
		0:
			_play_dialogue("Wow! The canteen looks so much better now.", "medium")
			_set_next_btn("I Agree")
		1:
			_play_dialogue("Our students will surely enjoy eating here.", "medium")
			_set_next_btn("Yes")
		2:
			_play_dialogue("Well, hello there! I’m Principal Reyes.", "medium")
			_set_next_btn("Yes")
		3:
			_play_dialogue("And you must be the new canteen cook...", "small")
			_set_next_btn("Yes")
		4:
			show_name_input()
		5:
			_play_dialogue("Welcome, %s! Our school is very excited to have you here." % player_name, "medium")
			_set_next_btn("Thank you!")
		6:
			_play_dialogue("You know, our students are in need of meals that are tasty... and healthy too!", "medium")
			_set_next_btn("Got it!")
		7:
			_play_dialogue("We want them to grow strong and healthy so they can learn well.", "medium")
			_set_next_btn("Okay")
		8:
			_play_dialogue("That’s why I’ve chosen you for this important job.", "medium")
			_set_next_btn("Okay")
		9:
			_play_dialogue("Ready to start your first day?", "small")
			btn_next.hide()
			btn_choice1.show()
			btn_choice2.show()
			btn_choice1_label.text = "I'm ready!"
			btn_choice2_label.text = "I'm nervous"
		10:
			_play_dialogue("Don’t worry, I know you will do great, %s!" % player_name, "medium")
			_set_next_btn("Thanks!")
		11:
			_play_dialogue("Ok! See you next time, %s. Have fun serving our students!" % player_name, "medium")
			_set_next_btn("See you!")

		# ===== JENNA =====
		12:
			_play_dialogue("Hello there! My name’s Jenna!", "small")
			_setup_choices("Hi Jenna!", "Okay...")
		13:
			_play_dialogue("Anyway, my classroom is just across.", "small")
			_set_next_btn("Okay")
		14:
			_play_dialogue("Hehe, I saw the new look of the canteen, so I came here.", "medium")
			_set_next_btn("Okay")
		15:
			_play_dialogue("I'd like to try the rice, chicken, sitaw, and mango combo please. Cold water is fine, and don't forget my milk too!", "large")
			_setup_choices("Okay", "What")
		16:
			_play_dialogue("Give me rice, chicken, sitaw, and mango. My water is cold. And don’t forget my milk please.", "large")
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
	if is_transitioning: return 
	
	if is_typing:
		_skip_typing()
		return

	if step == 11 and current_character == "principal":
		principal_exit_and_spawn_jenna()
		return

	if step == 16 and current_character == "jenna":
		GameData.intro_completed = true
		GameData.current_phase = GameData.GamePhase.LOBBY
		GameData.save_game()
		get_tree().change_scene_to_file("res://Scenes/Tutorial/KitchenTutorial.tscn")
		return

	step += 1
	show_step()

func _on_btn_choice_1_pressed() -> void:
	if is_transitioning: return
	
	if is_typing:
		_skip_typing()
		return
	
	if current_character == "principal":
		step = 11
		show_step()
		return
	elif current_character == "jenna":
		if step == 15:
			GameData.intro_completed = true
			GameData.current_phase = GameData.GamePhase.LOBBY
			GameData.save_game()
			get_tree().change_scene_to_file("res://Scenes/Tutorial/KitchenTutorial.tscn")
			return
		step = 14
	show_step()

func _on_btn_choice_2_pressed() -> void:
	if is_transitioning: return
	
	if is_typing:
		_skip_typing()
		return
	
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

	get_tree().call_group("HUD", "update_all_labels")

	if is_instance_valid(dim_background): dim_background.hide()

	step += 1
	show_step()

# ===================================================
# CHARACTER ANIMATIONS
# ===================================================

func principal_exit_and_spawn_jenna():
	is_transitioning = true 
	
	if not is_instance_valid(principal): 
		spawn_jenna()
		return

	_kill_active_tween()
	active_tween = create_tween().bind_node(self)
	
	var exit_pos = principal.position
	exit_pos.x += 700

	active_tween.tween_property(principal, "position", exit_pos, principal_exit_speed).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	
	active_tween.tween_callback(func():
		if is_instance_valid(principal): principal.hide()
	)
	
	active_tween.tween_interval(transition_delay) 
	
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

	active_tween.tween_property(jenna, "position", final_pos, jenna_enter_speed).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

	active_tween.tween_callback(func():
		if is_inside_tree():
			is_transitioning = false 
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
