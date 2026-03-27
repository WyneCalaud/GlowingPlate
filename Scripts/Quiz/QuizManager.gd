extends Control

# --- CUSTOM MESSAGES ---
@export_group("Custom Feedback Messages")
@export var msg_correct_fast: Array[String] = ["Wow! You answered that super fast!"]
@export var msg_correct_normal: Array[String] = ["Good job! That's correct."]
@export var msg_correct_slow: Array[String] = ["Correct! But try to be a bit faster."]
@export var msg_incorrect: Array[String] = ["Oops! Let's review this concept."]

# --- REPEAT POPUP UI ---
@export_group("Repeat Question Popup")
@export var repeat_popup_rect: TextureRect
@export var repeat_texture: Texture2D
var repeat_tween: Tween

# --- EXTERNAL UI REFERENCES ---
@export_group("External UI")
@export var sound_control_ui: Control 

# --- AUDIO REFERENCES ---
@onready var sfx_correct: AudioStreamPlayer2D = get_node_or_null("SfxCorrect")
@onready var sfx_incorrect: AudioStreamPlayer2D = get_node_or_null("SfxIncorrect")

# --- GAME DATA REFERENCE ---
@onready var game_data = get_node_or_null("/root/GameData")

# --- UI NODE REFERENCES ---
@onready var quiz_panel: Control = get_node_or_null("QuizPanel")
@onready var question_label: Label = get_node_or_null("QuizPanel/Questionaire/HBoxContainer/QuestionText")
@onready var image_display: TextureRect = get_node_or_null("QuizPanel/Questionaire/HBoxContainer/QuestionImage")

# --- MESSAGE BOX REFERENCES ---
@onready var message_box: TextureRect = get_node_or_null("MessageBox")
@onready var message_label: Label = get_node_or_null("MessageBox/MessageLabel")
var message_box_original_pos: Vector2

@onready var answer_nodes = [
	{
		"button": get_node_or_null("QuizPanel/AnswersContainer/A"),
		"text": get_node_or_null("QuizPanel/AnswersContainer/A/AText"),
		"image": get_node_or_null("QuizPanel/AnswersContainer/A/AImage")
	},
	{
		"button": get_node_or_null("QuizPanel/AnswersContainer/B"),
		"text": get_node_or_null("QuizPanel/AnswersContainer/B/BText"),
		"image": get_node_or_null("QuizPanel/AnswersContainer/B/BImage")
	},
	{
		"button": get_node_or_null("QuizPanel/AnswersContainer/C"),
		"text": get_node_or_null("QuizPanel/AnswersContainer/C/CText"),
		"image": get_node_or_null("QuizPanel/AnswersContainer/C/CImage")
	}
]

@onready var result_label: Label = get_node_or_null("Result/ResultLabel") 
@onready var exposure_label: Label = get_node_or_null("Result/ExposureLabel") 
@onready var mastery_label: Label = get_node_or_null("Result/MasteryLabel")

@onready var menu_button: BaseButton = get_node_or_null("TopBarRight/MenuGroup/MenuButton")
@onready var settings_button: BaseButton = get_node_or_null("TopBarRight/MenuGroup/MenuButton/SettingsButton")
@onready var home_button: BaseButton = get_node_or_null("TopBarRight/MenuGroup/MenuButton/HomeButton")
@onready var pause_layer: Control = get_node_or_null("PauseLayer")

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
	if not is_correct:
		return msg_incorrect.pick_random() if not msg_incorrect.is_empty() else "Incorrect!"
	
	if response_time <= 1.5:
		return msg_correct_fast.pick_random() if not msg_correct_fast.is_empty() else "Correct!"
	elif response_time <= 3.0:
		return msg_correct_normal.pick_random() if not msg_correct_normal.is_empty() else "Correct!"
	else:
		return msg_correct_slow.pick_random() if not msg_correct_slow.is_empty() else "Correct!"

# ==========================================================
# INITIALIZATION
# ==========================================================

func _ready():
	_lower_music_volume()
	
	if is_instance_valid(game_data):
		var day_val = game_data.get("current_day")
		if day_val == null: day_val = 2
		current_day = day_val - 1
		if current_day < 1: current_day = 1
	
	if is_instance_valid(quiz_panel):
		original_panel_pos = quiz_panel.position

	await get_tree().process_frame 
	if is_instance_valid(message_box):
		message_box_original_pos = message_box.position
		message_box.pivot_offset = message_box.size / 2
		message_box.visible = false

	if is_instance_valid(repeat_popup_rect):
		repeat_popup_rect.visible = false
		repeat_popup_rect.pivot_offset = repeat_popup_rect.size / 2.0

	_setup_menu_buttons()
	update_age_group_display()
	
	var q_sys = get_node_or_null("/root/QuizSystem")
	if is_instance_valid(q_sys):
		q_sys.initialize_concepts(current_day)

	var has_saved = false
	if is_instance_valid(game_data) and "saved_quiz_sets" in game_data:
		if game_data.saved_quiz_sets.has(current_day):
			var saved = game_data.saved_quiz_sets[current_day]
			if typeof(saved) == TYPE_ARRAY and not saved.is_empty():
				current_quiz_set = saved.duplicate(true)
				MAX_QUESTIONS = current_quiz_set.size()
				has_saved = true
	
	if not has_saved:
		_get_due_concept_questions()

	if current_quiz_set.is_empty():
		push_error("QuizManager: No questions found in Database for day " + str(current_day))
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
			for conn in btn.get_signal_connection_list("pressed"): 
				btn.disconnect("pressed", conn.callable)
			btn.pressed.connect(_on_answer_button_pressed.bind(i))
			btn.pivot_offset = btn.size / 2

func _exit_tree() -> void:
	_restore_music_volume()

func _lower_music_volume() -> void:
	var bg_music = get_node_or_null("/root/BGMusic")
	if is_instance_valid(bg_music): bg_music.volume_db -= 10.0

func _restore_music_volume() -> void:
	var bg_music = get_node_or_null("/root/BGMusic")
	if is_instance_valid(bg_music):
		if is_instance_valid(game_data) and "music_volume" in game_data:
			bg_music.volume_db = linear_to_db(game_data.music_volume)
		else:
			bg_music.volume_db += 10.0

func _setup_menu_buttons():
	if is_instance_valid(menu_button):
		if not menu_button.pressed.is_connected(_on_menu_button_pressed):
			menu_button.pressed.connect(_on_menu_button_pressed)
	
	if is_instance_valid(settings_button):
		settings_button.visible = false
		settings_button.modulate.a = 0.0
		if not settings_button.pressed.is_connected(_on_settings_button_pressed):
			settings_button.pressed.connect(_on_settings_button_pressed)
		
	if is_instance_valid(home_button):
		home_button.visible = false
		home_button.modulate.a = 0.0
		
	if is_instance_valid(pause_layer): pause_layer.visible = false

func update_age_group_display():
	var age = "6-9"
	if is_instance_valid(game_data):
		var age_val = game_data.get("current_customer_age_group")
		if age_val != null: age = str(age_val)
	
	if is_instance_valid(sixtonine): sixtonine.visible = (age == "6-9")
	if is_instance_valid(tentotwelve): tentotwelve.visible = (age == "10-12")

# ==========================================================
# DYNAMIC QUESTION SELECTION
# ==========================================================

func _get_due_concept_questions():
	current_quiz_set.clear()
	var q_db = get_node_or_null("/root/QuestionDatabase")
	var q_sys = get_node_or_null("/root/QuizSystem")

	if not is_instance_valid(q_db):
		push_error("QuizManager: QuestionDatabase node is missing.")
		return

	var daily_questions = q_db.get_questions_for_day(current_day)
	var due_concepts = []
	
	# FIX: Only fetch due/repeated concepts if it's Day 3 or later
	if current_day > 2 and is_instance_valid(q_sys):
		due_concepts = q_sys.get_due_concepts(current_day)

	var review_pool: Array = []
	var new_pool: Array = []

	# Populate review_pool (Day 3+)
	for concept in due_concepts:
		var q = q_db.get_question_by_id(concept)
		if not q.is_empty():
			var q_copy = q.duplicate(true)
			q_copy["is_review"] = true 
			review_pool.append(q_copy)

	review_pool.shuffle()
	review_pool = review_pool.slice(0, 3)

	for q in daily_questions:
		var is_dup = false
		for r in review_pool:
			if str(r.get("id", "")) == str(q.get("id", "")):
				is_dup = true
				break
		if not is_dup:
			var q_copy = q.duplicate(true)
			q_copy["is_review"] = false 
			new_pool.append(q_copy)

	new_pool.shuffle()
	new_pool = new_pool.slice(0, 3)

	current_quiz_set = review_pool + new_pool
	
	# Fallback if pools are empty
	if current_quiz_set.is_empty():
		var fallback_questions = q_db.get_questions_for_day(1)
		if not fallback_questions.is_empty():
			current_quiz_set = fallback_questions.slice(0, 3)

	current_quiz_set.shuffle()
	MAX_QUESTIONS = current_quiz_set.size()

	if is_instance_valid(game_data) and "saved_quiz_sets" in game_data:
		game_data.saved_quiz_sets[current_day] = current_quiz_set.duplicate(true)
		if game_data.has_method("save_game"): game_data.save_game()

# ==========================================================
# QUIZ FLOW
# ==========================================================

func start_quiz():
	current_question_index = 0
	total_correct_answers = 0
	if current_quiz_set.is_empty():
		finish_quiz()
		return
	load_question()

func load_question():
	# RESET UI Defensive
	for nodes in answer_nodes:
		if is_instance_valid(nodes.button):
			nodes.button.visible = false
			nodes.button.disabled = false
			nodes.button.modulate = Color.WHITE
			nodes.button.scale = Vector2.ONE
		if is_instance_valid(nodes.text): 
			nodes.text.text = ""
			nodes.text.visible = false
		if is_instance_valid(nodes.image): 
			nodes.image.texture = null
			nodes.image.visible = false

	if current_question_index >= MAX_QUESTIONS or current_quiz_set.is_empty():
		finish_quiz()
		return

	if is_instance_valid(quiz_panel): quiz_panel.position = original_panel_pos
	question_start_time = Time.get_unix_time_from_system()

	var q_data: Dictionary = current_quiz_set[current_question_index]
	var q_id = str(q_data.get("id", ""))
	current_concept = q_data.get("concept", q_id)
	var is_review_type: bool = q_data.get("is_review", false)
	
	if is_instance_valid(question_label): 
		question_label.text = q_data.get("q", "Question missing text.")
		
	if is_instance_valid(image_display):
		image_display.texture = q_data.get("q_img", null)
		image_display.visible = (image_display.texture != null)

	# --- OPTION GENERATION ---
	var options = []
	var ans_text = q_data.get("ans")
	options.append({
		"text": str(ans_text) if ans_text != null else "", 
		"img": q_data.get("ans_img"), 
		"is_correct": true
	})

	var wrong_pool = []
	for k in ["wrong1", "wrong2"]:
		var w_val = q_data.get(k)
		var w_img = q_data.get(k + "_img")
		if (w_val != null and str(w_val) != "") or w_img != null:
			wrong_pool.append({
				"text": str(w_val) if w_val != null else "", 
				"img": w_img, 
				"is_correct": false
			})

	# DETERMINE TARGET COUNT
	var target_wrong_count = 2 
	var progress_node = get_node_or_null("/root/QuizProgress")
	
	if is_review_type:
		target_wrong_count = 1
	elif is_instance_valid(progress_node) and progress_node.has_method("get_wrong_options_count"):
		target_wrong_count = progress_node.get_wrong_options_count(q_id)
	else:
		target_wrong_count = 2 

	wrong_pool.shuffle()
	for i in range(min(target_wrong_count, wrong_pool.size())):
		options.append(wrong_pool[i])

	options.shuffle()

	# --- UI BINDING ---
	for i in range(options.size()):
		if i >= answer_nodes.size(): break
		
		var nodes = answer_nodes[i]
		var opt = options[i]
		if opt.is_correct: correct_button_index = i
		
		if is_instance_valid(nodes.button):
			nodes.button.visible = true 
			if is_instance_valid(nodes.text): 
				nodes.text.text = opt.text
				nodes.text.visible = (opt.text != "")
			if is_instance_valid(nodes.image):
				nodes.image.texture = opt.img
				nodes.image.visible = (opt.img != null)

	if is_review_type: _show_repeat_popup()

# ==========================================================
# ANSWER HANDLING
# ==========================================================

func _on_answer_button_pressed(button_index: int):
	if not is_mechanic_active: return
	is_mechanic_active = false
	_hide_repeat_popup()
	
	var actual_response_time = Time.get_unix_time_from_system() - question_start_time
	
	if current_question_index >= current_quiz_set.size():
		is_mechanic_active = true
		finish_quiz()
		return

	var q_data: Dictionary = current_quiz_set[current_question_index]
	var is_correct = (button_index == correct_button_index)

	var progress_node = get_node_or_null("/root/QuizProgress")
	if is_instance_valid(progress_node):
		progress_node.record_attempt(str(q_data.get("id", "")), is_correct, current_day)

	var feedback_dict = {}
	var q_sys = get_node_or_null("/root/QuizSystem")
	if is_instance_valid(q_sys):
		feedback_dict = q_sys.update_concept_progress(current_concept, is_correct, actual_response_time, current_day)
		if is_instance_valid(game_data):
			game_data.quiz_concept_progress = q_sys.concept_progress
			if game_data.has_method("save_game"): game_data.save_game()

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

	_show_message_box(_get_custom_message(is_correct, actual_response_time))

	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		if is_instance_valid(btn):
			btn.disabled = true
			if i == correct_button_index: btn.modulate = Color.GREEN
			elif i == button_index: btn.modulate = Color.RED

	if is_correct:
		total_correct_answers += 1
		if is_instance_valid(result_label): 
			result_label.text = feedback_dict.get("performance", "CORRECT!")
			result_label.modulate = Color.GREEN
		if is_instance_valid(exposure_label): exposure_label.modulate = Color.GREEN
		if is_instance_valid(sfx_correct): sfx_correct.play()
		_animate_correct_feedback(button_index)
	else:
		if is_instance_valid(result_label): 
			result_label.text = feedback_dict.get("performance", "INCORRECT.")
			result_label.modulate = Color.RED
		if is_instance_valid(exposure_label): exposure_label.modulate = Color.RED
		if is_instance_valid(sfx_incorrect): sfx_incorrect.play()
		_animate_incorrect_feedback(button_index)

	await get_tree().create_timer(2.5).timeout
	if not is_inside_tree(): return 

	if is_instance_valid(result_label): result_label.visible = false
	if is_instance_valid(exposure_label): exposure_label.visible = false
	if is_instance_valid(mastery_label): mastery_label.visible = false
	if is_instance_valid(message_box): message_box.visible = false
	
	is_mechanic_active = true
	current_question_index += 1
	load_question()

# ==========================================================
# ANIMATIONS & UI
# ==========================================================

func _show_repeat_popup():
	if not is_instance_valid(repeat_popup_rect): return
	if repeat_tween and repeat_tween.is_valid(): repeat_tween.kill()
	if repeat_texture != null: repeat_popup_rect.texture = repeat_texture
	repeat_popup_rect.visible = true
	repeat_popup_rect.scale = Vector2.ZERO
	repeat_popup_rect.move_to_front()
	repeat_tween = create_tween().bind_node(self)
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2(1.15, 1.15), 0.2).set_trans(Tween.TRANS_BACK)
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BOUNCE)

func _hide_repeat_popup():
	if not is_instance_valid(repeat_popup_rect) or not repeat_popup_rect.visible: return
	if repeat_tween and repeat_tween.is_valid(): repeat_tween.kill()
	repeat_tween = create_tween().bind_node(self)
	repeat_tween.tween_property(repeat_popup_rect, "scale", Vector2.ZERO, 0.2).set_ease(Tween.EASE_IN)
	repeat_tween.tween_callback(func(): if is_instance_valid(repeat_popup_rect): repeat_popup_rect.visible = false)

func _show_message_box(text: String):
	if not is_instance_valid(message_box) or not is_instance_valid(message_label): return
	message_box.move_to_front()
	message_label.text = text
	message_box.visible = true
	message_box.modulate.a = 1.0
	message_box.position = message_box_original_pos + Vector2(0, 400)
	var tween = create_tween()
	tween.tween_property(message_box, "position", message_box_original_pos, 0.4).set_trans(Tween.TRANS_QUART)
	tween.parallel().tween_property(message_box, "scale", Vector2.ONE, 0.3).from(Vector2.ZERO)

func _animate_correct_feedback(idx: int):
	var btn = answer_nodes[idx].button
	if not is_instance_valid(btn): return
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE)

func _animate_incorrect_feedback(idx: int):
	var btn = answer_nodes[idx].button
	if not is_instance_valid(btn): return
	var shake_tween = create_tween()
	for i in range(4):
		shake_tween.tween_property(btn, "rotation_degrees", 4.0, 0.04)
		shake_tween.tween_property(btn, "rotation_degrees", -4.0, 0.04)
	shake_tween.tween_property(btn, "rotation_degrees", 0.0, 0.04)

func _on_menu_button_pressed():
	if not is_instance_valid(settings_button) or not is_instance_valid(home_button): return
	is_menu_open = !is_menu_open
	if menu_tween and menu_tween.is_valid(): menu_tween.kill()
	menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	if is_menu_open:
		if is_instance_valid(pause_layer): pause_layer.visible = true
		settings_button.visible = true
		menu_tween.tween_property(settings_button, "position:y", BUTTON_SPACING, ANIM_DURATION)
		menu_tween.tween_property(settings_button, "modulate:a", 1.0, ANIM_DURATION)
		home_button.visible = true
		menu_tween.tween_property(home_button, "position:y", BUTTON_SPACING * 2, ANIM_DURATION).set_delay(0.05)
		menu_tween.tween_property(home_button, "modulate:a", 1.0, ANIM_DURATION).set_delay(0.05)
	else:
		if is_instance_valid(pause_layer): pause_layer.visible = false
		menu_tween.tween_property(settings_button, "position:y", 0.0, ANIM_DURATION)
		menu_tween.tween_property(settings_button, "modulate:a", 0.0, ANIM_DURATION)
		menu_tween.tween_property(home_button, "position:y", 0.0, ANIM_DURATION)
		menu_tween.tween_property(home_button, "modulate:a", 0.0, ANIM_DURATION)
		menu_tween.chain().tween_callback(func():
			if is_instance_valid(settings_button): settings_button.visible = false
			if is_instance_valid(home_button): home_button.visible = false
		)

func _on_settings_button_pressed():
	if is_menu_open: _on_menu_button_pressed()
	if is_instance_valid(sound_control_ui): sound_control_ui.show()
	else:
		var sc = get_node_or_null("/root/SoundControl")
		if is_instance_valid(sc): sc.show()

# ==========================================================
# FINISH
# ==========================================================

func finish_quiz():
	var reward_money = total_correct_answers * 50
	if is_instance_valid(game_data):
		if game_data.has_method("add_money"): game_data.add_money(reward_money)
		
		var current_earned = game_data.get("daily_money_earned")
		if current_earned == null: current_earned = 0
		game_data.set("daily_money_earned", current_earned + reward_money)
		
		if game_data.has_method("save_game"): game_data.save_game()
	call_deferred("_continue_after_quiz")

func _continue_after_quiz():
	if is_instance_valid(game_data) and game_data.has_method("start_next_day_flow"):
		game_data.start_next_day_flow()
