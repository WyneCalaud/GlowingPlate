# QuizProgress.gd
extends Node

# ==========================================================
# QUESTION UNLOCK TRACKING SYSTEM
# ==========================================================
#
# This script tracks:
# - Which questions have been unlocked
# - Which questions were attempted
# - Optional future stats (accuracy, attempts)
#
# This is separate from QuizSystem (SM-2 scheduler).
# ==========================================================


# Structure:
# {
#   "Q_ID": {
#       "unlocked": true,
#       "attempts": 1,
#       "correct_attempts": 1
#   }
# }

var question_progress: Dictionary = {}


# ==========================================================
# INITIALIZATION
# ==========================================================

func initialize_all_questions():
	var all_questions = QuestionDatabase.get_all_questions()
	
	for q in all_questions:
		var q_id = q["id"]
		
		if not question_progress.has(q_id):
			question_progress[q_id] = {
				"unlocked": false,
				"attempts": 0,
				"correct_attempts": 0
			}


# ==========================================================
# UNLOCK SYSTEM
# ==========================================================

func unlock_question(question_id: String):
	if not question_progress.has(question_id):
		initialize_all_questions()
	
	question_progress[question_id]["unlocked"] = true


func is_unlocked(question_id: String) -> bool:
	if not question_progress.has(question_id):
		return false
	
	return question_progress[question_id]["unlocked"]


func get_unlocked_questions() -> Array:
	var unlocked := []
	
	for q_id in question_progress.keys():
		if question_progress[q_id]["unlocked"]:
			var q_data = QuestionDatabase.get_question_by_id(q_id)
			if not q_data.is_empty():
				unlocked.append(q_data)
	
	return unlocked


# ==========================================================
# ATTEMPT TRACKING
# ==========================================================

func record_attempt(question_id: String, is_correct: bool):
	if not question_progress.has(question_id):
		initialize_all_questions()
	
	var data = question_progress[question_id]
	
	data["attempts"] += 1
	
	if is_correct:
		data["correct_attempts"] += 1
	
	data["unlocked"] = true  # Auto-unlock on first attempt
	
	question_progress[question_id] = data


func get_attempts(question_id: String) -> int:
	if not question_progress.has(question_id):
		return 0
	
	return question_progress[question_id]["attempts"]


func get_accuracy(question_id: String) -> float:
	if not question_progress.has(question_id):
		return 0.0
	
	var data = question_progress[question_id]
	
	if data["attempts"] == 0:
		return 0.0
	
	return float(data["correct_attempts"]) / float(data["attempts"])


# ==========================================================
# DEBUG
# ==========================================================

func print_unlocked():
	print("=== UNLOCKED QUESTIONS ===")
	for q_id in question_progress.keys():
		if question_progress[q_id]["unlocked"]:
			print(q_id)
