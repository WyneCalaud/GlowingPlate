extends Control

# --- CONFIGURATION & EXTERNAL DATA ---
# Removed: @export var quiz_data_resource
# We now use QuestionDatabase directly

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
var current_quiz_set: Array = [] # Now an Array of Dictionaries
var current_question_index: int = 0
var total_correct_answers: int = 0
var MAX_QUESTIONS: int = 3
var is_mechanic_active: bool = true
var current_day: int = 1
var original_panel_pos: Vector2
var current_correct_answer: String = "" # Tracks current answer

# ====================================================================
# --- INITIALIZATION ---
# ====================================================================

func _ready():
	current_day = game_data.current_day
	original_panel_pos = quiz_panel.position
	
	# 1. Initialize Progress for NEW questions in the database
	_initialize_srs_progress()
	
	# 2. Get questions for today
	_get_review_questions()
	
	if current_quiz_set.size() > 0:
		# Ensure we don't exceed the number of available questions
		MAX_QUESTIONS = min(current_quiz_set.size(), 3)
		start_quiz()
	else:
		question_label.text = "No questions due for review today!"
		# Give a small consolation reward or just close
		await get_tree().create_timer(2.0).timeout
		QuizSystem.apply_quiz_results({"correct_count": 0, "bonus_money": 0})
		queue_free()
		return
		
	result_label.visible = false
	result_label.pivot_offset = result_label.size / 2
	
	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		if btn:
			btn.pressed.connect(_on_answer_button_pressed.bind(i))
			btn.pivot_offset = btn.size / 2

func _initialize_srs_progress():
	# Loop through ALL questions in the database
	var all_questions = QuestionDatabase.get_all_questions()
	for q in all_questions:
		var q_id = q["id"]
		if not QuizSystem.quiz_progress.has(q_id):
			# Initialize if new
			QuizSystem.quiz_progress[q_id] = {
				"streak": 0,
				"next_review_day": current_day 
			}
			
func _get_review_questions():
	current_quiz_set.clear()
	
	# --- STRATEGY: Get Daily Questions + Due Reviews ---
	
	# 1. Get NEW questions assigned to this specific day
	var new_qs = QuestionDatabase.get_questions_for_day(current_day)
	
	# 2. Get DUE review questions from ALL questions
	var all_qs = QuestionDatabase.get_all_questions()
	var due_qs = []
	
	for q in all_qs:
		var id = q.get("id", "??")
		var progress = QuizSystem.quiz_progress.get(id, null)
		if progress and progress.next_review_day <= current_day:
			due_qs.append(q)
			
	# 3. Combine them
	current_quiz_set.append_array(due_qs)
	current_quiz_set.append_array(new_qs)
	
	# 4. Shuffle
	current_quiz_set.shuffle()

func start_quiz():
	current_question_index = 0
	total_correct_answers = 0
	load_question()

func load_question():
	if current_question_index >= MAX_QUESTIONS or current_question_index >= current_quiz_set.size():
		finish_quiz()
		return
		
	quiz_panel.position = original_panel_pos 
	
	# Get current question Dictionary
	var q_data: Dictionary = current_quiz_set[current_question_index]
	
	# Set Question Text
	question_label.text = q_data["q"]
	current_correct_answer = q_data["ans"]
	
	# Set Image
	image_display.texture = q_data.get("q_img", null)
	image_display.visible = (image_display.texture != null)
	
	# --- GENERATE OPTIONS (Correct + 2 Explicit Wrongs) ---
	var options = []
	
	# Correct Answer
	options.append({ 
		"text": q_data["ans"], 
		"img": q_data.get("ans_img"),
		"is_correct": true
	})
	
	# Wrong 1 (Explicit or Fallback)
	var w1_txt = q_data.get("wrong1", "Wrong")
	options.append({ 
		"text": w1_txt, 
		"img": q_data.get("wrong1_img"),
		"is_correct": false
	})
	
	# Wrong 2 (Explicit or Fallback)
	var w2_txt = q_data.get("wrong2", "Incorrect")
	options.append({ 
		"text": w2_txt, 
		"img": q_data.get("wrong2_img"),
		"is_correct": false
	})
	
	options.shuffle()
	
	# --- SETUP BUTTONS ---
	for i in range(answer_nodes.size()):
		var nodes = answer_nodes[i]
		var btn = nodes.button
		var opt = options[i]
		
		btn.visible = true
		btn.disabled = false
		btn.modulate = Color.WHITE 
		btn.scale = Vector2.ONE
		
		if nodes.text:
			nodes.text.text = opt.text
		
		# Set Image (and toggle visibility)
		if nodes.image:
			nodes.image.texture = opt.img
			nodes.image.visible = (opt.img != null)

# ====================================================================
# --- INPUT AND SCORING ---
# ====================================================================

func _on_answer_button_pressed(button_index: int):
	if not is_mechanic_active: return
	is_mechanic_active = false 
	
	var q_data: Dictionary = current_quiz_set[current_question_index]
	var selected_text = answer_nodes[button_index].text.text
	var is_correct = (selected_text == current_correct_answer)
	
	# Update SRS Logic
	QuizSystem.update_question_progress(q_data["id"], is_correct, current_day)
	
	result_label.visible = true
	result_label.scale = Vector2.ZERO
	var feedback_tween = create_tween().set_parallel(true)
	
	if is_correct:
		total_correct_answers += 1
		result_label.text = "CORRECT!"
		result_label.modulate = Color.GREEN
		if sfx_correct: sfx_correct.play()
		_animate_correct_feedback(button_index, feedback_tween)
	else:
		result_label.text = "INCORRECT."
		result_label.modulate = Color.RED
		if sfx_incorrect: sfx_incorrect.play()
		_animate_incorrect_feedback(button_index, feedback_tween)

	# Reveal Answers visually
	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		var txt = answer_nodes[i].text.text
		btn.disabled = true
		
		if txt == current_correct_answer:
			btn.modulate = Color.GREEN
		elif i == button_index and not is_correct:
			btn.modulate = Color.RED
	
	await get_tree().create_timer(1.8).timeout
	
	var fade = create_tween()
	fade.tween_property(result_label, "modulate:a", 0.0, 0.2)
	await fade.finished
	
	result_label.visible = false
	result_label.modulate.a = 1.0
	is_mechanic_active = true
	current_question_index += 1
	load_question()

# --- IMPACT ANIMATIONS (UNCHANGED) ---

func _animate_correct_feedback(idx: int, tween: Tween):
	var btn = answer_nodes[idx].button
	tween.tween_property(result_label, "scale", Vector2.ONE * 1.2, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "position:y", btn.position.y - 20, 0.1).set_trans(Tween.TRANS_SINE)
	tween.chain().tween_property(btn, "position:y", btn.position.y, 0.1).set_trans(Tween.TRANS_SINE)

func _animate_incorrect_feedback(idx: int, tween: Tween):
	tween.tween_property(result_label, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	var shake_tween = create_tween()
	for i in range(6):
		var offset = original_panel_pos + Vector2(randf_range(-10, 10), randf_range(-5, 5))
		shake_tween.tween_property(quiz_panel, "position", offset, 0.05)
	shake_tween.tween_property(quiz_panel, "position", original_panel_pos, 0.05)
	
	var btn = answer_nodes[idx].button
	var vib_tween = create_tween()
	for i in range(4):
		vib_tween.tween_property(btn, "rotation_degrees", 2.0, 0.05)
		vib_tween.tween_property(btn, "rotation_degrees", -2.0, 0.05)
	vib_tween.tween_property(btn, "rotation_degrees", 0.0, 0.05)

func finish_quiz():
	var reward_money = total_correct_answers * 50
	var quiz_results = {
		"correct_count": total_correct_answers,
		"bonus_money": reward_money
	}
	QuizSystem.apply_quiz_results(quiz_results)
	queue_free()
