extends Control

# --- AUDIO REFERENCES ---
@onready var sfx_correct: AudioStreamPlayer2D = $SfxCorrect
@onready var sfx_incorrect: AudioStreamPlayer2D = $SfxIncorrect

# --- GAME DATA REFERENCE ---
@onready var game_data = $"/root/GameData"

# --- UI NODE REFERENCES ---
@onready var quiz_panel: Control = $QuizPanel
@onready var question_label: Label = $QuizPanel/Questionaire/QuestionText
@onready var image_display: TextureRect = $QuizPanel/Questionaire/QuestionImage

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

# --- QUIZ STATE ---
var current_quiz_set: Array = []
var current_question_index: int = 0
var total_correct_answers: int = 0
var MAX_QUESTIONS: int = 3
var is_mechanic_active: bool = true
var current_day: int = 1
var original_panel_pos: Vector2
var current_correct_answer: String = ""
var current_concept: String = ""

# ==========================================================
# INITIALIZATION
# ==========================================================

func _ready():
	current_day = game_data.current_day
	original_panel_pos = quiz_panel.position

	# Initialize concept scheduler
	QuizSystem.initialize_concepts(current_day)

	# Get questions safely
	_get_due_concept_questions()

	if current_quiz_set.is_empty():
		question_label.text = "No questions due today!"
		await get_tree().create_timer(2.0).timeout
		QuizSystem.apply_quiz_results({"correct_count": 0, "bonus_money": 0})
		queue_free()
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

# ==========================================================
# CONCEPT-BASED QUESTION SELECTION
# ==========================================================

func _get_due_concept_questions():
	current_quiz_set.clear()

	# 1. Always fetch the base daily questions so the game progresses
	var daily_questions = QuestionDatabase.get_questions_for_day(current_day)
	current_quiz_set.append_array(daily_questions)

	# 2. Add due SM-2 concepts (if implemented with concept tags in the future)
	var due_concepts = QuizSystem.get_due_concepts(current_day, 2)
	for concept in due_concepts:
		var questions = QuestionDatabase.get_questions_by_concept(concept)
		if questions.size() > 0:
			questions.shuffle()
			var q = questions[0]
			# Prevent duplicates
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

	# Safe fallback: if concept tag is missing, use the question ID as the concept
	current_concept = q_data.get("concept", q_data["id"]) 
	current_correct_answer = q_data["ans"]

	question_label.text = q_data["q"]

	image_display.texture = q_data.get("q_img", null)
	image_display.visible = (image_display.texture != null)

	var options = []

	options.append({
		"text": q_data["ans"],
		"img": q_data.get("ans_img"),
		"is_correct": true
	})

	options.append({
		"text": q_data.get("wrong1", "Wrong"),
		"img": q_data.get("wrong1_img"),
		"is_correct": false
	})

	options.append({
		"text": q_data.get("wrong2", "Incorrect"),
		"img": q_data.get("wrong2_img"),
		"is_correct": false
	})

	options.shuffle()

	for i in range(answer_nodes.size()):
		var nodes = answer_nodes[i]
		var btn = nodes.button
		var opt = options[i]

		btn.visible = true
		btn.disabled = false
		btn.modulate = Color.WHITE
		btn.scale = Vector2.ONE
		btn.rotation_degrees = 0
		btn.pivot_offset = btn.size / 2

		nodes.text.text = opt.text
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
	var selected_text = answer_nodes[button_index].text.text
	var is_correct = (selected_text == current_correct_answer)

	# Unlock question safely
	if has_node("/root/QuizProgress"):
		QuizProgress.record_attempt(q_data["id"], is_correct)

	# Update concept SM-2 safely
	if has_node("/root/QuizSystem"):
		var quality = 4 if is_correct else 0
		QuizSystem.update_concept_progress(current_concept, quality, current_day)

	result_label.visible = true
	result_label.scale = Vector2.ZERO

	var pop_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(result_label, "scale", Vector2.ONE, 0.3)

	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		var txt = answer_nodes[i].text.text
		btn.disabled = true

		if txt == current_correct_answer:
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
	
	# 1. Pop up (Scale)
	tween.tween_property(btn, "scale", Vector2(1.15, 1.15), 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	
	# 2. Come back down to normal size
	tween.tween_property(btn, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

func _animate_incorrect_feedback(idx: int):
	var btn = answer_nodes[idx].button
	if not is_instance_valid(btn): return
	
	btn.pivot_offset = btn.size / 2
	var shake_tween = create_tween()
	
	# Buzz aggressively (Use rotation to avoid layout crashes)
	for i in range(4):
		shake_tween.tween_property(btn, "rotation_degrees", 4.0, 0.04)
		shake_tween.tween_property(btn, "rotation_degrees", -4.0, 0.04)
	shake_tween.tween_property(btn, "rotation_degrees", 0.0, 0.04)
	
	# Flash bright red
	var color_tween = create_tween()
	btn.modulate = Color(2.5, 0.5, 0.5)
	color_tween.tween_property(btn, "modulate", Color.RED, 0.3)

# ==========================================================
# FINISH
# ==========================================================

func finish_quiz():
	var reward_money = total_correct_answers * 50
	var quiz_results = {
		"correct_count": total_correct_answers,
		"bonus_money": reward_money
	}
	
	if has_node("/root/QuizSystem"):
		QuizSystem.apply_quiz_results(quiz_results)
	else:
		GameData.money += reward_money
		GameData.daily_money_earned += reward_money
		GameData.start_new_day()
		
	queue_free()
