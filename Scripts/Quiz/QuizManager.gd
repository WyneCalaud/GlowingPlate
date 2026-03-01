extends Control

# --- AUDIO REFERENCES ---
@onready var sfx_correct: AudioStreamPlayer2D = $SfxCorrect
@onready var sfx_incorrect: AudioStreamPlayer2D = $SfxIncorrect

# --- GAME DATA REFERENCE ---
@onready var game_data = $"/root/GameData"

# --- UI NODE REFERENCES ---
@onready var quiz_panel: Control = $QuizPanel
@onready var question_label: Label = $QuizPanel/Questionaire/HBoxContainer/QuestionText
@onready var image_display: TextureRect = $QuizPanel/Questionaire/HBoxContainer/QuestionImage

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

@onready var result_label: Label = $Result/ResultLabel

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
var MAX_QUESTIONS: int = 3
var is_mechanic_active: bool = true
var current_day: int = 1
var original_panel_pos: Vector2
var correct_button_index: int = -1
var current_concept: String = ""

# --- MENU STATE ---
var is_menu_open: bool = false
var menu_tween: Tween
const BUTTON_SPACING: float = 70.0
const ANIM_DURATION: float = 0.3

# ==========================================================
# INITIALIZATION
# ==========================================================

func _ready():
	current_day = game_data.current_day
	original_panel_pos = quiz_panel.position

	# Setup Menu, Pause Layer & Age Display
	_setup_menu_buttons()
	update_age_group_display()

	# Initialize concept scheduler
	QuizSystem.initialize_concepts(current_day)

	# Get questions safely
	_get_due_concept_questions()

	if current_quiz_set.is_empty():
		question_label.text = "No questions due today!"
		await get_tree().create_timer(2.0).timeout
		finish_quiz() # Safe finish
		return

	MAX_QUESTIONS = min(current_quiz_set.size(), 3)
	start_quiz()

	result_label.visible = false
	result_label.pivot_offset = result_label.size / 2

	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		if btn:
			var connections = btn.get_signal_connection_list("pressed")
			for conn in connections:
				btn.disconnect("pressed", conn.callable)
			btn.pressed.connect(_on_answer_button_pressed.bind(i))
			btn.pivot_offset = btn.size / 2

func _setup_menu_buttons():
	if menu_button:
		menu_button.pressed.connect(_on_menu_button_pressed)
		
	if settings_button:
		settings_button.top_level = false
		settings_button.show_behind_parent = true
		settings_button.z_index = 0
		settings_button.position = Vector2.ZERO
		settings_button.visible = false
		settings_button.modulate.a = 0.0
		settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if home_button:
		home_button.top_level = false
		home_button.show_behind_parent = true
		home_button.z_index = 0
		home_button.position = Vector2.ZERO
		home_button.visible = false
		home_button.modulate.a = 0.0
		home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		
	if pause_layer:
		pause_layer.visible = false

# ==========================================================
# AGE GROUP DISPLAY
# ==========================================================

func update_age_group_display():
	if not has_node("/root/GameData"):
		return

	var GD = get_node("/root/GameData")
	var age: String = GD.get("current_customer_age_group") if "current_customer_age_group" in GD else "6-9"

	if sixtonine: sixtonine.visible = false
	if tentotwelve: tentotwelve.visible = false

	match age:
		"6-9":
			if sixtonine: sixtonine.visible = true
		"10-12":
			if tentotwelve: tentotwelve.visible = true

# ==========================================================
# CONCEPT-BASED QUESTION SELECTION
# ==========================================================

func _get_due_concept_questions():
	current_quiz_set.clear()

	var daily_questions = QuestionDatabase.get_questions_for_day(current_day)
	current_quiz_set.append_array(daily_questions)

	var due_concepts = QuizSystem.get_due_concepts(current_day, 2)
	for concept in due_concepts:
		var questions = QuestionDatabase.get_questions_by_concept(concept)
		if questions.size() > 0:
			questions.shuffle()
			var q = questions[0]
			var is_dup = false
			for existing in current_quiz_set:
				if existing["id"] == q["id"]: is_dup = true
			if not is_dup:
				current_quiz_set.append(q)

	current_quiz_set.shuffle()

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

	quiz_panel.position = original_panel_pos

	var q_data: Dictionary = current_quiz_set[current_question_index]
	current_concept = q_data.get("concept", q_data["id"]) 

	question_label.text = q_data["q"]

	image_display.texture = q_data.get("q_img", null)
	image_display.visible = (image_display.texture != null)

	var options = []
	options.append({"text": q_data.get("ans") if q_data.get("ans") != null else "", "img": q_data.get("ans_img"), "is_correct": true})
	options.append({"text": q_data.get("wrong1") if q_data.get("wrong1") != null else "", "img": q_data.get("wrong1_img"), "is_correct": false})
	options.append({"text": q_data.get("wrong2") if q_data.get("wrong2") != null else "", "img": q_data.get("wrong2_img"), "is_correct": false})
	options.shuffle()

	for i in range(answer_nodes.size()):
		var nodes = answer_nodes[i]
		var btn = nodes.button
		var opt = options[i]
		
		if opt.is_correct: correct_button_index = i

		btn.visible = true
		btn.disabled = false
		btn.modulate = Color.WHITE
		btn.scale = Vector2.ONE
		btn.rotation_degrees = 0
		btn.pivot_offset = btn.size / 2

		nodes.text.text = opt.text
		nodes.text.visible = (opt.text != "") 
		nodes.image.texture = opt.img
		nodes.image.visible = (opt.img != null)

# ==========================================================
# ANSWER HANDLING
# ==========================================================

func _on_answer_button_pressed(button_index: int):
	if not is_mechanic_active:
		return

	is_mechanic_active = false

	var q_data: Dictionary = current_quiz_set[current_question_index]
	var is_correct = (button_index == correct_button_index)

	if has_node("/root/QuizProgress"):
		QuizProgress.record_attempt(q_data["id"], is_correct)

	if has_node("/root/QuizSystem"):
		var quality = 4 if is_correct else 0
		QuizSystem.update_concept_progress(current_concept, quality, current_day)

	result_label.visible = true
	result_label.scale = Vector2.ZERO

	var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(result_label, "scale", Vector2.ONE, 0.3)

	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		btn.disabled = true

		if i == correct_button_index:
			btn.modulate = Color.GREEN
		elif i == button_index and not is_correct:
			btn.modulate = Color.RED

	if is_correct:
		total_correct_answers += 1
		result_label.text = "CORRECT!"
		result_label.modulate = Color.GREEN
		if sfx_correct: sfx_correct.play()
		_animate_correct_feedback(button_index)
	else:
		result_label.text = "INCORRECT."
		result_label.modulate = Color.RED
		if sfx_incorrect: sfx_incorrect.play()
		_animate_incorrect_feedback(button_index)

	await get_tree().create_timer(1.8).timeout
	
	# ⚠️ CRITICAL FIX: Prevent crash if player exits mid-timer
	if not is_inside_tree(): return 

	result_label.visible = false
	result_label.modulate.a = 1.0
	is_mechanic_active = true
	current_question_index += 1
	load_question()

# ==========================================================
# ANIMATIONS (CONTAINER-SAFE)
# ==========================================================

func _animate_correct_feedback(idx: int):
	var btn = answer_nodes[idx].button
	if not is_instance_valid(btn): return
	btn.pivot_offset = btn.size / 2
	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _animate_incorrect_feedback(idx: int):
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
	if not settings_button or not home_button: return
	
	is_menu_open = !is_menu_open
	if menu_tween and menu_tween.is_valid(): menu_tween.kill()
	menu_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	if is_menu_open:
		if pause_layer: pause_layer.visible = true
		if settings_button:
			settings_button.visible = true
			settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
			menu_tween.tween_property(settings_button, "position:y", BUTTON_SPACING, ANIM_DURATION)
			menu_tween.tween_property(settings_button, "modulate:a", 1.0, ANIM_DURATION)
		if home_button:
			home_button.visible = true
			home_button.mouse_filter = Control.MOUSE_FILTER_STOP
			menu_tween.tween_property(home_button, "position:y", BUTTON_SPACING * 2, ANIM_DURATION).set_delay(0.05)
			menu_tween.tween_property(home_button, "modulate:a", 1.0, ANIM_DURATION).set_delay(0.05)
	else:
		if pause_layer: pause_layer.visible = false
		if settings_button:
			settings_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			menu_tween.tween_property(settings_button, "position:y", 0.0, ANIM_DURATION)
			menu_tween.tween_property(settings_button, "modulate:a", 0.0, ANIM_DURATION)
		if home_button:
			home_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
			menu_tween.tween_property(home_button, "position:y", 0.0, ANIM_DURATION)
			menu_tween.tween_property(home_button, "modulate:a", 0.0, ANIM_DURATION)
			
		menu_tween.chain().tween_callback(func():
			if settings_button: settings_button.visible = false
			if home_button: home_button.visible = false
		)

# ==========================================================
# FINISH
# ==========================================================

func finish_quiz():
	var reward_money = total_correct_answers * 50

	if has_node("/root/QuizSystem"):
		QuizSystem.apply_quiz_results({}) # Update concepts in system

	if game_data:
		game_data.add_money(reward_money)
		game_data.daily_money_earned += reward_money # Manually update daily tracker
		game_data.save_game()

	call_deferred("_continue_after_quiz")

func _continue_after_quiz():
	if game_data:
		game_data.start_next_day_flow()
