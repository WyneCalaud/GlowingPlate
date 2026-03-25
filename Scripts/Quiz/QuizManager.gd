extends Control

# --- CUSTOM MESSAGES (EDIT THESE IN THE INSPECTOR!) ---
@export_group("Custom Feedback Messages")
@export var msg_correct_fast: Array[String] = ["Wow! You answered that super fast!"]
@export var msg_correct_normal: Array[String] = ["Good job! That's correct."]
@export var msg_correct_slow: Array[String] = ["Correct! But try to be a bit faster."]
@export var msg_incorrect: Array[String] = ["Oops! Let's review this concept."]

# --- REPEAT POPUP UI (ASSIGN IN INSPECTOR) ---
@export_group("Repeat Question Popup")
@export var repeat_popup_rect: TextureRect
@export var repeat_texture: Texture2D
var repeat_tween: Tween

# --- EXTERNAL UI REFERENCES ---
@export_group("External UI")
@export var sound_control_ui: Control # Assign your SoundControl node here in the Inspector!

# --- AUDIO REFERENCES ---
@onready var sfx_correct: AudioStreamPlayer2D = $SfxCorrect
@onready var sfx_incorrect: AudioStreamPlayer2D = $SfxIncorrect

# --- GAME DATA REFERENCE ---
@onready var game_data = $"/root/GameData"

# --- UI NODE REFERENCES ---
@onready var quiz_panel: Control = $QuizPanel
@onready var question_label: Label = $QuizPanel/Questionaire/HBoxContainer/QuestionText
@onready var image_display: TextureRect = $QuizPanel/Questionaire/HBoxContainer/QuestionImage

# --- MESSAGE BOX REFERENCES ---
@onready var message_box: TextureRect = $MessageBox
@onready var message_label: Label = $MessageBox/MessageLabel
var message_box_original_pos: Vector2

@onready var answer_nodes = [
	{
		"button": $QuizPanel/AnswersContainer/A,
		"text": $QuizPanel/AnswersContainer/A/AText,
		"image": $QuizPanel/AnswersContainer/A/AImage
	},
	{
		"button": $QuizPanel/AnswersContainer/B,
		"text": $QuizPanel/AnswersContainer/B/BText,
		"image": $QuizPanel/AnswersContainer/B/BImage
	},
	{
		"button": $QuizPanel/AnswersContainer/C,
		"text": $QuizPanel/AnswersContainer/C/CText,
		"image": $QuizPanel/AnswersContainer/C/CImage
	}
]

# 🔥 NEW UI REFS: Added the two extra labels required by the professor
@onready var result_label: Label = $Result/ResultLabel # Serves as Performance Feedback
@onready var exposure_label: Label = get_node_or_null("Result/ExposureLabel") 
@onready var mastery_label: Label = get_node_or_null("Result/MasteryLabel")

# --- MENU & PAUSE NODE REFERENCES ---
@onready var menu_button: BaseButton = $TopBarRight/MenuGroup/MenuButton
@onready var settings_button: BaseButton = $TopBarRight/MenuGroup/MenuButton/SettingsButton
@onready var home_button: BaseButton = $TopBarRight/MenuGroup/MenuButton/HomeButton
@onready var pause_layer: Control = $PauseLayer

# --- AGE GROUP REFERENCES ---
@onready var sixtonine: TextureRect = get_node_or_null("UI/TopBarLeft/HBoxContainer/AgeGroup/6-9")
@onready var tentotwelve: TextureRect = get_node_or_null("UI/TopBarLeft/HBoxContainer/AgeGroup/10-12")

# --- QUIZ STATE ---
var current_quiz_set: Array = []
var current_question_index: int = 0
var total_correct_answers: int = 0
var MAX_QUESTIONS: int = 0 
var is_mechanic_active: bool = true
var current_day: int = 1
var original_panel_pos: Vector2
var correct_button_index: int = -1
var current_concept: String = ""

# 🔥 NEW: Timer Variable to track Response Speed
var question_start_time: float = 0.0

# --- MENU STATE ---
var is_menu_open: bool = false
var menu_tween: Tween
const BUTTON_SPACING: float = 70.0
const ANIM_DURATION: float = 0.3

# ==========================================================
# CUSTOM MESSAGE LOGIC
# ==========================================================

func _get_custom_message(is_correct: bool, response_time: float) -> String:
	var my_message = ""
	
	if is_correct:
		if response_time <= 1.5:
			my_message = msg_correct_fast.pick_random() if msg_correct_fast.size() > 0 else "Correct!"
		elif response_time <= 3.0:
			my_message = msg_correct_normal.pick_random() if msg_correct_normal.size() > 0 else "Correct!"
		else:
			my_message = msg_correct_slow.pick_random() if msg_correct_slow.size() > 0 else "Correct!"
	else:
		my_message = msg_incorrect.pick_random() if msg_incorrect.size() > 0 else "Incorrect!"
		
	return my_message

# ==========================================================
# INITIALIZATION
# ==========================================================

func _ready():
	_lower_music_volume()
	
	current_day = game_data.current_day - 1
	if current_day < 1:
		current_day = 1
	original_panel_pos = quiz_panel.position

	# Safe Initialization for the Message Box
	await get_tree().process_frame # Ensures correct layout calculation before hiding
	if is_instance_valid(message_box):
		message_box_original_pos = message_box.position
		message_box.pivot_offset = message_box.size / 2
		message_box.visible = false

	# Safe Initialization for Repeat Popup
	if is_instance_valid(repeat_popup_rect):
		repeat_popup_rect.visible = false
		repeat_popup_rect.pivot_offset = repeat_popup_rect.size / 2.0

	_setup_menu_buttons()
	update_age_group_display()
	QuizSystem.initialize_concepts(current_day)

	if GameData.saved_quiz_sets.has(current_day):
		current_quiz_set = GameData.saved_quiz_sets[current_day].duplicate(true)
		MAX_QUESTIONS = current_quiz_set.size()
		print("📦 Loaded saved quiz set for day", current_day)
	else:
		_get_due_concept_questions()

	if current_quiz_set.is_empty():
		if is_instance_valid(question_label):
			question_label.text = "No questions due today!"
		await get_tree().create_timer(2.0).timeout
		finish_quiz()
		return

	start_quiz()

	if is_instance_valid(result_label):
		result_label.visible = false
		result_label.pivot_offset = result_label.size / 2
	
	if is_instance_valid(exposure_label): exposure_label.visible = false
	if is_instance_valid(mastery_label): mastery_label.visible = false

	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		if is_instance_valid(btn):
			var connections = btn.get_signal_connection_list("pressed")
			for conn in connections:
				btn.disconnect("pressed", conn.callable)
			btn.pressed.connect(_on_answer_button_pressed.bind(i))
			btn.pivot_offset = btn.size / 2

# This built-in function safely triggers right before the node is destroyed/scene is changed
func _exit_tree() -> void:
	_restore_music_volume()

func _lower_music_volume() -> void:
	if has_node("/root/BGMusic"):
		var bg_music = get_node("/root/BGMusic")
		if is_instance_valid(bg_music):
			bg_music.volume_db -= 10.0

func _restore_music_volume() -> void:
	if has_node("/root/BGMusic"):
		var bg_music = get_node("/root/BGMusic")
		if is_instance_valid(bg_music):
			# Safely restore based on the saved user setting if available
			if has_node("/root/GameData") and "music_volume" in get_node("/root/GameData"):
				bg_music.volume_db = linear_to_db(get_node("/root/GameData").music_volume)
			else:
				# Fallback just in case GameData is missing
				bg_music.volume_db += 10.0

func _setup_menu_buttons():
	if is_instance_valid(menu_button): 
		if not menu_button.pressed.is_connected(_on_menu_button_pressed):
			menu_button.pressed.connect(_on_menu_button_pressed)
	
	if is_instance_valid(settings_button):
		settings_button.top_level = false
		settings_button.show_behind_parent = true
		settings_button.z_index = 0
		settings_button.position = Vector2.ZERO
		settings_button.visible = false
		settings_button.modulate.a = 0.0
		settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 🔥 Connect settings button safely
		if not settings_button.pressed.is_connected(_on_settings_button_pressed):
			settings_button.pressed.connect(_on_settings_button_pressed)
		
	if is_instance_valid(home_button):
		home_button.top_level = false
		home_button.show_behind_parent = true
		home_button.z_index = 0
		home_button.position = Vector2.ZERO
		home_button.visible = false
		home_button.modulate.a = 0.0
		home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if is_instance_valid(pause_layer): 
		pause_layer.visible = false

# ==========================================================
# AGE GROUP DISPLAY
# ==========================================================

func update_age_group_display():
	if not has_node("/root/GameData"): return
	var GD = get_node("/root/GameData")
	var age: String = GD.get("current_customer_age_group") if "current_customer_age_group" in GD else "6-9"
	
	if is_instance_valid(sixtonine): sixtonine.visible = false
	if is_instance_valid(tentotwelve): tentotwelve.visible = false

	match age:
		"6-9": if is_instance_valid(sixtonine): sixtonine.visible = true
		"10-12": if is_instance_valid(tentotwelve): tentotwelve.visible = true

# ==========================================================
# DYNAMIC QUESTION SELECTION
# ==========================================================

func _get_due_concept_questions():
	current_quiz_set.clear()
	var review_questions: Array = []
	var daily_questions = QuestionDatabase.get_questions_for_day(current_day)
	var due_concepts = QuizSystem.get_due_concepts(current_day)

	for concept in due_concepts:
		var review_q = QuestionDatabase.get_question_by_id(concept)

		if typeof(review_q) == TYPE_DICTIONARY and not review_q.is_empty():
			var is_dup = false
			for existing in review_questions:
				if existing.get("id") == review_q.get("id"):
					is_dup = true
					break
			if not is_dup: review_questions.append(review_q)

	review_questions.shuffle()
	review_questions = review_questions.slice(0, 10)

	for q in daily_questions:
		var is_dup = false
		for existing in review_questions:
			if existing.get("id") == q.get("id"):
				is_dup = true
				break
		if not is_dup: current_quiz_set.append(q)

	current_quiz_set = review_questions + current_quiz_set
	MAX_QUESTIONS = current_quiz_set.size()

	if not GameData.saved_quiz_sets.has(current_day):
		GameData.saved_quiz_sets[current_day] = current_quiz_set.duplicate(true)
		GameData.save_game()

# ==========================================================
# QUIZ FLOW
# ==========================================================

func start_quiz():
	current_question_index = 0
	total_correct_answers = 0
	load_question()

func load_question():
	if current_question_index >= MAX_QUESTIONS:
		finish_quiz()
		return

	if is_instance_valid(quiz_panel):
		quiz_panel.position = original_panel_pos
	question_start_time = Time.get_unix_time_from_system()

	var q_data: Dictionary = current_quiz_set[current_question_index]
	current_concept = q_data.get("concept", q_data.get("id", "")) 
	
	if is_instance_valid(question_label):
		question_label.text = q_data.get("q", "")

	if is_instance_valid(image_display):
		image_display.texture = q_data.get("q_img", null)
		image_display.visible = (image_display.texture != null)

	# 🔥 ADVISOR UPDATE: Check if this is a repeated question (exposure > 0)
	var is_repeated_question: bool = false
	if has_node("/root/QuizSystem"):
		var c_progress = QuizSystem.get("concept_progress")
		if typeof(c_progress) == TYPE_DICTIONARY and c_progress.has(current_concept):
			var c_data = c_progress[current_concept]
			if typeof(c_data) == TYPE_DICTIONARY and c_data.has("exposure") and c_data["exposure"] > 0:
				is_repeated_question = true

	# Assemble the options
	var options = []
	options.append({"text": q_data.get("ans", ""), "img": q_data.get("ans_img"), "is_correct": true})
	options.append({"text": q_data.get("wrong1", ""), "img": q_data.get("wrong1_img"), "is_correct": false})
	
	# 🔥 ADVISOR UPDATE: Only append the second wrong answer if it's NOT a repeated question
	if not is_repeated_question:
		options.append({"text": q_data.get("wrong2", ""), "img": q_data.get("wrong2_img"), "is_correct": false})
		
	options.shuffle()

	# Map options to available buttons
	for i in range(answer_nodes.size()):
		var nodes = answer_nodes[i]
		var btn = nodes.button
		
		# If we have an option for this button slot
		if i < options.size():
			var opt = options[i]
			if opt.is_correct: correct_button_index = i

			if is_instance_valid(btn):
				btn.visible = true
				btn.disabled = false
				btn.modulate = Color.WHITE
				btn.scale = Vector2.ONE
				btn.rotation_degrees = 0
				btn.pivot_offset = btn.size / 2

			if is_instance_valid(nodes.text):
				nodes.text.text = str(opt.text)
				nodes.text.visible = (str(opt.text) != "") 
			if is_instance_valid(nodes.image):
				nodes.image.texture = opt.img
				nodes.image.visible = (opt.img != null)
		else:
			# 🔥 DEFENSIVE / ADVISOR UPDATE: Hide any remaining buttons (e.g. the 3rd button if repeated)
			if is_instance_valid(btn):
				btn.visible = false

	# 🔥 TRIGGER REPEAT POPUP BEFORE ANSWERING
	if is_repeated_question:
		_show_repeat_popup()

# ==========================================================
# ANSWER HANDLING
# ==========================================================

func _on_answer_button_pressed(button_index: int):
	if not is_mechanic_active: return
	is_mechanic_active = false
	
	# 🔥 ANIMATE POPUP AWAY ONCE THEY CLICK AN ANSWER
	_hide_repeat_popup()
	
	var actual_response_time = Time.get_unix_time_from_system() - question_start_time
	var q_data: Dictionary = current_quiz_set[current_question_index]
	var is_correct = (button_index == correct_button_index)

	if has_node("/root/QuizProgress"):
		QuizProgress.record_attempt(q_data.get("id", ""), is_correct, current_day)

	var feedback_dict = {}
	if has_node("/root/QuizSystem"):
		feedback_dict = QuizSystem.update_concept_progress(current_concept, is_correct, actual_response_time, current_day)
		GameData.quiz_concept_progress = QuizSystem.concept_progress
		GameData.save_game()

	# --- UI POPUP VISUALS ---
	if is_instance_valid(result_label):
		result_label.visible = true
		result_label.scale = Vector2.ZERO
		var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		pop_tween.tween_property(result_label, "scale", Vector2.ONE, 0.3)
	
	if is_instance_valid(exposure_label):
		exposure_label.visible = true
		exposure_label.text = str(feedback_dict.get("exposure", ""))
	if is_instance_valid(mastery_label):
		mastery_label.visible = true
		mastery_label.text = str(feedback_dict.get("mastery", ""))

	# --- GET YOUR CUSTOM TEXT AND SHOW THE ANIMATED BOX ---
	var final_custom_text = _get_custom_message(is_correct, actual_response_time)
	_show_message_box(final_custom_text)

	# --- BUTTON COLOR UPDATES ---
	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		if is_instance_valid(btn) and btn.visible: # Only update visible buttons safely
			btn.disabled = true
			if i == correct_button_index:
				btn.modulate = Color.GREEN
			elif i == button_index and not is_correct:
				btn.modulate = Color.RED

	# --- PROFESSOR'S TEXT & SOUNDS ---
	if is_correct:
		total_correct_answers += 1
		if is_instance_valid(result_label): 
			result_label.text = str(feedback_dict.get("performance", "CORRECT!"))
			result_label.modulate = Color.GREEN
		if is_instance_valid(exposure_label): exposure_label.modulate = Color.GREEN
		if is_instance_valid(sfx_correct): sfx_correct.play()
		_animate_correct_feedback(button_index)
	else:
		if is_instance_valid(result_label): 
			result_label.text = str(feedback_dict.get("performance", "INCORRECT."))
			result_label.modulate = Color.RED
		if is_instance_valid(exposure_label): exposure_label.modulate = Color.RED
		if is_instance_valid(sfx_incorrect): sfx_incorrect.play()
		_animate_incorrect_feedback(button_index)

	await get_tree().create_timer(2.5).timeout # Slightly longer to read the new text
	if not is_inside_tree(): return 

	# Hide everything safely
	if is_instance_valid(result_label): 
		result_label.visible = false
		result_label.modulate.a = 1.0
	if is_instance_valid(exposure_label): exposure_label.visible = false
	if is_instance_valid(mastery_label): mastery_label.visible = false
	if is_instance_valid(message_box): message_box.visible = false
	
	is_mechanic_active = true
	current_question_index += 1
	load_question()

# ==========================================================
# REPEAT POPUP ANIMATION
# ==========================================================

func _show_repeat_popup():
	if not is_instance_valid(repeat_popup_rect): return

	if repeat_tween and repeat_tween.is_valid():
		repeat_tween.kill()

	if repeat_texture != null:
		repeat_popup_rect.texture = repeat_texture

	repeat_popup_rect.visible = true
	repeat_popup_rect.scale = Vector2.ZERO
	repeat_popup_rect.pivot_offset = repeat_popup_rect.size / 2.0
	
	repeat_popup_rect.move_to_front()
	repeat_popup_rect.z_index = 60
	
	repeat_tween = create_tween().bind_node(self)
	# Only Pop In - No timer interval, no pop out! Stays until player answers.
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _hide_repeat_popup():
	if not is_instance_valid(repeat_popup_rect) or not repeat_popup_rect.visible: return
	
	if repeat_tween and repeat_tween.is_valid():
		repeat_tween.kill()
		
	repeat_tween = create_tween().bind_node(self)
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2(1.1, 1.1), 0.1).set_ease(Tween.EASE_IN)
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2.ZERO, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	repeat_tween.tween_callback(func():
		if is_instance_valid(repeat_popup_rect):
			repeat_popup_rect.visible = false
	)

# ==========================================================
# MESSAGE BOX ANIMATION
# ==========================================================

func _show_message_box(text: String):
	if not is_instance_valid(message_box) or not is_instance_valid(message_label): 
		return

	message_box.move_to_front()
	message_box.z_index = 50

	message_label.text = text
	message_box.visible = true
	message_box.modulate.a = 1.0
	
	message_box.position = message_box_original_pos + Vector2(0, 400)
	message_box.scale = Vector2.ONE
	
	var tween = create_tween()
	
	tween.tween_property(message_box, "position", message_box_original_pos, 0.4)\
		 .set_trans(Tween.TRANS_QUART)\
		 .set_ease(Tween.EASE_OUT)
		
	tween.tween_property(message_box, "scale", Vector2(1.1, 1.1), 0.15)\
		 .set_trans(Tween.TRANS_BACK)\
		 .set_ease(Tween.EASE_OUT)
	tween.tween_property(message_box, "scale", Vector2.ONE, 0.15)\
		 .set_trans(Tween.TRANS_BOUNCE)\
		 .set_ease(Tween.EASE_OUT)

# ==========================================================
# ANIMATIONS
# ==========================================================

func _animate_correct_feedback(idx: int):
	# Defensive check to ensure index is valid
	if idx < 0 or idx >= answer_nodes.size(): return
	var btn = answer_nodes[idx].button
	if not is_instance_valid(btn): return
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _animate_incorrect_feedback(idx: int):
	# Defensive check to ensure index is valid
	if idx < 0 or idx >= answer_nodes.size(): return
	var btn = answer_nodes[idx].button
	if not is_instance_valid(btn): return
	btn.pivot_offset = btn.size / 2
	var shake_tween = create_tween()
	for i in range(4):
		shake_tween.tween_property(btn, "rotation_degrees", 4.0, 0.04)
		shake_tween.tween_property(btn, "rotation_degrees", -4.0, 0.04)
	shake_tween.tween_property(btn, "rotation_degrees", 0.0, 0.04)
	var color_tween = create_tween()
	btn.modulate = Color(2.5, 0.5, 0.5)
	color_tween.tween_property(btn, "modulate", Color.RED, 0.3)

# ==========================================================
# MENU LOGIC
# ==========================================================

func _on_menu_button_pressed():
	if not is_instance_valid(settings_button) or not is_instance_valid(home_button): return
	
	is_menu_open = !is_menu_open
	if menu_tween and menu_tween.is_valid(): menu_tween.kill()
	menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if is_menu_open:
		if is_instance_valid(pause_layer): pause_layer.visible = true
		if is_instance_valid(settings_button):
			settings_button.visible = true
			settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
			menu_tween.tween_property(settings_button, "position:y", BUTTON_SPACING, ANIM_DURATION)
			menu_tween.tween_property(settings_button, "modulate:a", 1.0, ANIM_DURATION)
		if is_instance_valid(home_button):
			home_button.visible = true
			home_button.mouse_filter = Control.MOUSE_FILTER_STOP
			menu_tween.tween_property(home_button, "position:y", BUTTON_SPACING * 2, ANIM_DURATION).set_delay(0.05)
			menu_tween.tween_property(home_button, "modulate:a", 1.0, ANIM_DURATION).set_delay(0.05)
	else:
		if is_instance_valid(pause_layer): pause_layer.visible = false
		if is_instance_valid(settings_button):
			settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			menu_tween.tween_property(settings_button, "position:y", 0.0, ANIM_DURATION)
			menu_tween.tween_property(settings_button, "modulate:a", 0.0, ANIM_DURATION)
		if is_instance_valid(home_button):
			home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			menu_tween.tween_property(home_button, "position:y", 0.0, ANIM_DURATION)
			menu_tween.tween_property(home_button, "modulate:a", 0.0, ANIM_DURATION)
			
		menu_tween.chain().tween_callback(func():
			if is_instance_valid(settings_button): settings_button.visible = false
			if is_instance_valid(home_button): home_button.visible = false
		)

# 🔥 NEW: Defensively handle showing the sound control menu
func _on_settings_button_pressed():
	# Retract the dropdown menu for visual clean-up
	if is_menu_open:
		_on_menu_button_pressed()
		
	# Check the local inspector variable first
	if is_instance_valid(sound_control_ui):
		sound_control_ui.show()
	# Fallback to checking if it's an Autoload named "SoundControl"
	elif has_node("/root/SoundControl"):
		var sc = get_node("/root/SoundControl")
		if is_instance_valid(sc):
			sc.show()
	else:
		push_warning("SoundControl node not assigned in Inspector and not found in /root!")

# ==========================================================
# FINISH
# ==========================================================

func finish_quiz():
	var reward_money = total_correct_answers * 50
	if has_node("/root/QuizSystem"):
		GameData.quiz_concept_progress = QuizSystem.concept_progress
		GameData.save_game()

	if is_instance_valid(game_data):
		if game_data.has_method("add_money"):
			game_data.add_money(reward_money)
		
		if "daily_money_earned" in game_data:
			game_data.daily_money_earned += reward_money
			
		if game_data.has_method("save_game"):
			game_data.save_game()

	call_deferred("_continue_after_quiz")

func _continue_after_quiz():
	if is_instance_valid(game_data) and game_data.has_method("start_next_day_flow"):
		game_data.start_next_day_flow()
