extends Control # Use Control for UI scenes

# --- CONFIGURATION & EXTERNAL DATA ---
@export var quiz_data_resource: QuizDataResource

# --- GAME DATA REFERENCE ---
@onready var game_data = $"/root/GameData"

# --- UI NODE REFERENCES ---
@onready var quiz_background: TextureRect = $QuizBackground/BGImage
@onready var quiz_panel: TextureRect = $QuizPanel/BackgroundPanel
@onready var question_label: Label = $QuizPanel/BackgroundPanel/QuestionPanel/QuestionLabel
@onready var image_display: TextureRect = $QuizPanel/BackgroundPanel/QuestionPanel/ImageDisplay
@onready var answer_buttons_container: GridContainer = $AnswerPanel
@onready var result_label: Label = $Result/ResultLabel

# --- QUIZ STATE ---
var current_quiz_set: Array[QuizQuestionResource] = [] 
var current_question_index: int = 0
var total_correct_answers: int = 0
var MAX_QUESTIONS: int = 3
var is_mechanic_active: bool = true
var current_day: int = 1

# ====================================================================
# --- INITIALIZATION ---
# ====================================================================

func _ready():
	# Access current day from GameData
	current_day = game_data.current_day
	
	if not is_instance_valid(quiz_data_resource) or quiz_data_resource.questions.size() == 0:
		printerr("FATAL: Quiz resource missing/empty. Skipping.")
		# Use the new QuizSystem to handle the early exit flow
		QuizSystem.apply_quiz_results({"correct_count": 0, "bonus_money": 0, "bonus_reputation": 0.0})
		queue_free()
		return

	# 1. Initialize tracking in the QuizSystem Autoload
	_initialize_srs_progress()
	
	# 2. Filter questions based on SRS due dates
	_get_review_questions()
	
	if current_quiz_set.size() > 0:
		# Limit the session to 3 questions or the total due count
		MAX_QUESTIONS = min(current_quiz_set.size(), 3)
		start_quiz()
	else:
		question_label.text = "No questions due for review today!"
		QuizSystem.apply_quiz_results({"correct_count": 0, "bonus_money": 0, "bonus_reputation": 0.0})
		queue_free()
		return
		
	result_label.visible = false
	
	# Connect buttons dynamically
	for i in range(answer_buttons_container.get_child_count()):
		var child = answer_buttons_container.get_child(i)
		var button = _find_button_in_node(child)
		if button:
			button.connect("pressed", Callable(self, "_on_answer_button_pressed").bind(i))

# Helper to find a button even if it's inside a MarginContainer/VBox
func _find_button_in_node(node: Node) -> BaseButton:
	if node is BaseButton: return node
	for child in node.get_children():
		var found = _find_button_in_node(child)
		if found: return found
	return null

func _initialize_srs_progress():
	# Ensure every question in the resource has an entry in the QuizSystem progress
	for q in quiz_data_resource.questions:
		if not QuizSystem.quiz_progress.has(q.question_id):
			QuizSystem.quiz_progress[q.question_id] = {
				"streak": 0,
				"next_review_day": current_day 
			}
			
func _get_review_questions():
	current_quiz_set.clear()
	
	for q in quiz_data_resource.questions:
		# Access progress from the new QuizSystem Autoload
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
		
	var q_data: QuizQuestionResource = current_quiz_set[current_question_index]
	print("\n--- LOADING QUESTION ID: ", q_data.question_id, " ---")
	
	# 1. Update Question Text
	question_label.text = "Question %d of %d: %s" % [current_question_index + 1, MAX_QUESTIONS, q_data.question_text]
	
	# 2. Update Visual Prompt Image
	image_display.modulate = Color.WHITE 
	image_display.texture = null
	
	var q_img_path = q_data.image_path.strip_edges()
	if not q_img_path.is_empty() and FileAccess.file_exists(q_img_path):
		image_display.texture = load(q_img_path)
	
	# 3. Update Answer Buttons
	for i in range(answer_buttons_container.get_child_count()):
		var container_child = answer_buttons_container.get_child(i)
		var button = _find_button_in_node(container_child)
		
		if not button:
			continue
		
		if i >= q_data.answers.size():
			container_child.visible = false
			continue
			
		var answer: QuizAnswerResource = q_data.answers[i]
		container_child.visible = true
		button.disabled = false
		button.modulate = Color.WHITE 
		
		# --- SMART NODE DISCOVERY ---
		var icon_node = button.find_child("AnswerIcon", true, false)
		var label_node = button.find_child("AnswerLabel", true, false)
		
		# Handle Image Icon
		if icon_node and icon_node is TextureRect:
			var ans_img_path = answer.texture_path.strip_edges()
			if not ans_img_path.is_empty() and FileAccess.file_exists(ans_img_path):
				icon_node.texture = load(ans_img_path)
				icon_node.visible = true
			else:
				icon_node.visible = false
				
		# Handle Text Label
		if label_node and label_node is Label:
			if not answer.text_label.is_empty():
				label_node.text = answer.text_label
				label_node.visible = true
			else:
				label_node.visible = false


# ====================================================================
# --- INPUT AND SCORING ---
# ====================================================================

func _on_answer_button_pressed(button_index: int):
	if not is_mechanic_active: return
	is_mechanic_active = false # Lock input
	
	var q_data: QuizQuestionResource = current_quiz_set[current_question_index]
	if button_index >= q_data.answers.size():
		is_mechanic_active = true
		return

	var selected_key = q_data.answers[button_index].answer_key
	var correct_key = q_data.correct_answer_key
	var is_correct = (selected_key == correct_key)
	
	# CRITICAL: Call the SRS update logic in the QuizSystem Autoload
	var next_day = QuizSystem.update_question_progress(q_data.question_id, is_correct, current_day)
	
	# Show result feedback
	if is_correct:
		total_correct_answers += 1
		result_label.text = "CORRECT! Review in %d days." % (next_day - current_day)
	else:
		result_label.text = "INCORRECT. The right answer was %s." % correct_key

	result_label.visible = true
	
	# Highlight buttons
	for i in range(answer_buttons_container.get_child_count()):
		var container_child = answer_buttons_container.get_child(i)
		var button = _find_button_in_node(container_child)
		if not button: continue
		
		button.disabled = true
		if i < q_data.answers.size():
			if q_data.answers[i].answer_key == correct_key:
				button.modulate = Color.GREEN
			elif i == button_index and not is_correct:
				button.modulate = Color.RED
	
	# Advance to next question
	await get_tree().create_timer(2.0).timeout
	is_mechanic_active = true
	result_label.visible = false
	current_question_index += 1
	load_question()

func finish_quiz():
	# Calculate results based on performance
	var quiz_results = {
		"correct_count": total_correct_answers,
		"bonus_money": total_correct_answers * 20,
		"bonus_reputation": float(total_correct_answers) * 0.1
	}
	
	# CRITICAL: Finalize rewards and scene transition via QuizSystem
	QuizSystem.apply_quiz_results(quiz_results)
	
	# Cleanup this scene
	queue_free()
