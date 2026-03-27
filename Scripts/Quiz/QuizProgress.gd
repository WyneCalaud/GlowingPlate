# QuizProgress.gd
extends Node

# Tracks: Unlocked questions, attempts, and difficulty scaling (wrong_options_left)
var question_progress: Dictionary = {}

func _ready():
	# Defensive check for GameData singleton and its property
	if is_instance_valid(GameData) and GameData.get("quiz_question_progress") != null:
		var saved = GameData.quiz_question_progress
		if typeof(saved) == TYPE_DICTIONARY and not saved.is_empty():
			question_progress = saved.duplicate(true)
			return
	
	initialize_all_questions()

# ==========================================================
# INITIALIZATION
# ==========================================================

func initialize_all_questions():
	var q_db = get_node_or_null("/root/QuestionDatabase")
	if not q_db:
		push_warning("QuizProgress: QuestionDatabase not found.")
		return

	var all_questions = q_db.get_all_questions()
	for q in all_questions:
		if typeof(q) != TYPE_DICTIONARY or not q.has("id"): continue
		
		var q_id = q["id"]
		if not question_progress.has(q_id):
			question_progress[q_id] = {
				"unlocked": false,
				"attempts": 0,
				"correct_attempts": 0,
				"streak": 0,
				"next_review_day": 1,
				"wrong_options_left": 2 # Default: 1 Correct + 2 Wrong = 3 Options
			}

# ==========================================================
# UNLOCK SYSTEM
# ==========================================================

func unlock_question(question_id: String):
	if not question_progress.has(question_id):
		initialize_all_questions()
	
	if question_progress.has(question_id):
		question_progress[question_id]["unlocked"] = true

func is_unlocked(question_id: String) -> bool:
	return question_progress.get(question_id, {}).get("unlocked", false)

func get_unlocked_questions() -> Array:
	var unlocked := []
	var q_db = get_node_or_null("/root/QuestionDatabase")
	if not q_db: return []
	
	for q_id in question_progress.keys():
		var data = question_progress[q_id]
		if typeof(data) == TYPE_DICTIONARY and data.get("unlocked", false):
			var q_data = q_db.get_question_by_id(q_id)
			if typeof(q_data) == TYPE_DICTIONARY and not q_data.is_empty():
				unlocked.append(q_data)
	
	return unlocked

# ==========================================================
# ATTEMPT TRACKING & DIFFICULTY SCALING
# ==========================================================

func record_attempt(question_id: String, is_correct: bool, current_day: int = 1):
	if not question_progress.has(question_id):
		initialize_all_questions()
	
	if not question_progress.has(question_id): return
	
	var data = question_progress[question_id]
	data["attempts"] = data.get("attempts", 0) + 1
	
	if is_correct:
		data["correct_attempts"] = data.get("correct_attempts", 0) + 1
		data["streak"] = min(data.get("streak", 0) + 1, 3)
		# 🔥 RESET difficulty if correct (Back to 3 options)
		data["wrong_options_left"] = 2
	else:
		data["streak"] = 0
		# 🔥 REDUCE wrong options (min = 1 for a 50/50 choice)
		var current_wrong = data.get("wrong_options_left", 2)
		data["wrong_options_left"] = max(1, current_wrong - 1)
	
	# Simple SRS scheduling
	var intervals = { 0: 1, 1: 3, 2: 7, 3: 14 }
	data["next_review_day"] = current_day + intervals.get(data["streak"], 1)
	data["unlocked"] = true
	
	question_progress[question_id] = data
	
	# Sync to GameData
	if is_instance_valid(GameData):
		GameData.quiz_question_progress = question_progress

func get_wrong_options_count(question_id: String) -> int:
	return question_progress.get(question_id, {}).get("wrong_options_left", 2)

func get_accuracy(question_id: String) -> float:
	var data = question_progress.get(question_id)
	if typeof(data) != TYPE_DICTIONARY or data.get("attempts", 0) == 0:
		return 0.0
	return float(data["correct_attempts"]) / float(data["attempts"])

# ==========================================================
# DEBUG
# ==========================================================

func print_unlocked():
	print("=== UNLOCKED QUESTIONS ===")
	for q_id in question_progress.keys():
		if question_progress[q_id].get("unlocked", false):
			print("- ", q_id, " (Wrong options left: ", question_progress[q_id].get("wrong_options_left"), ")")
