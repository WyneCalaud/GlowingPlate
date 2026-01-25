extends Control

# --- CONFIGURATION & EXTERNAL DATA ---
@export var quiz_data_resource: QuizDataResource

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
var current_quiz_set: Array[QuizQuestionResource] = [] 
var current_question_index: int = 0
var total_correct_answers: int = 0
var MAX_QUESTIONS: int = 3
var is_mechanic_active: bool = true
var current_day: int = 1
var original_panel_pos: Vector2 # Added to track correct layout position

# ====================================================================
# --- INITIALIZATION ---
# ====================================================================

func _ready():
	current_day = game_data.current_day
	original_panel_pos = quiz_panel.position # Capture the layout position
	
	if not is_instance_valid(quiz_data_resource) or quiz_data_resource.questions.size() == 0:
		printerr("FATAL: Quiz resource missing/empty.")
		QuizSystem.apply_quiz_results({"correct_count": 0, "bonus_money": 0})
		queue_free()
		return

	_initialize_srs_progress()
	_get_review_questions()
	
	if current_quiz_set.size() > 0:
		MAX_QUESTIONS = min(current_quiz_set.size(), 3)
		start_quiz()
	else:
		question_label.text = "No questions due for review today!"
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
	for q in quiz_data_resource.questions:
		if not QuizSystem.quiz_progress.has(q.question_id):
			QuizSystem.quiz_progress[q.question_id] = {
				"streak": 0,
				"next_review_day": current_day 
			}
			
func _get_review_questions():
	current_quiz_set.clear()
	for q in quiz_data_resource.questions:
		var progress = QuizSystem.quiz_progress.get(q.question_id, null)
		if progress and progress.next_review_day <= current_day:
			current_quiz_set.append(q)
	current_quiz_set.shuffle()

func start_quiz():
	current_question_index = 0
	total_correct_answers = 0
	load_question()

func load_question():
	if current_question_index >= MAX_QUESTIONS or current_question_index >= current_quiz_set.size():
		finish_quiz()
		return
		
	quiz_panel.position = original_panel_pos # Reset to correct layout position
	
	var q_data: QuizQuestionResource = current_quiz_set[current_question_index]
	question_label.text = q_data.question_text
	
	image_display.texture = null
	var q_img_path = q_data.image_path.strip_edges()
	if not q_img_path.is_empty() and FileAccess.file_exists(q_img_path):
		image_display.texture = load(q_img_path)
	
	for i in range(answer_nodes.size()):
		var nodes = answer_nodes[i]
		if i >= q_data.answers.size():
			nodes.button.visible = false
			continue
			
		var answer: QuizAnswerResource = q_data.answers[i]
		nodes.button.visible = true
		nodes.button.disabled = false
		nodes.button.modulate = Color.WHITE 
		nodes.button.scale = Vector2.ONE
		
		if nodes.text:
			nodes.text.text = answer.text_label
			nodes.text.visible = !answer.text_label.is_empty()
				
		if nodes.image:
			var ans_img_path = answer.texture_path.strip_edges()
			if not ans_img_path.is_empty() and FileAccess.file_exists(ans_img_path):
				nodes.image.texture = load(ans_img_path)
				nodes.image.visible = true
			else:
				nodes.image.visible = false

# ====================================================================
# --- INPUT AND SCORING ---
# ====================================================================

func _on_answer_button_pressed(button_index: int):
	if not is_mechanic_active: return
	is_mechanic_active = false 
	
	var q_data: QuizQuestionResource = current_quiz_set[current_question_index]
	var selected_key = q_data.answers[button_index].answer_key
	var correct_key = q_data.correct_answer_key
	var is_correct = (selected_key == correct_key)
	
	QuizSystem.update_question_progress(q_data.question_id, is_correct, current_day)
	
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

	for i in range(answer_nodes.size()):
		var btn = answer_nodes[i].button
		btn.disabled = true
		if i < q_data.answers.size():
			if q_data.answers[i].answer_key == correct_key:
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

# --- IMPACT ANIMATIONS ---

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
