extends Node

# Stores concept mastery data: { "concept_name": { "correct": 0, "incorrect": 0, ... } }
var concept_progress: Dictionary = {}

func initialize_concepts(current_day: int) -> void:
	var q_db = get_node_or_null("/root/QuestionDatabase")
	if not q_db:
		push_warning("QuizSystem: QuestionDatabase node not found.")
		return

	# 🔥 ALWAYS START FROM SAVED DATA
	# Using 1-argument get() for Object/Node safety in Godot 4
	var saved_data = null
	if is_instance_valid(GameData):
		saved_data = GameData.get("quiz_concept_progress")

	if saved_data != null and typeof(saved_data) == TYPE_DICTIONARY:
		concept_progress = saved_data.duplicate(true)
		print("✅ QuizSystem: Loaded %d concepts from save." % concept_progress.size())
	else:
		concept_progress.clear()
		print("⚠️ QuizSystem: No saved progress found, starting fresh.")

	# Sync with Database to ensure all concepts exist in the dictionary
	if q_db.has_method("get_all_questions"):
		var all_questions = q_db.get_all_questions()
		for q in all_questions:
			if typeof(q) != TYPE_DICTIONARY or not (q.has("id") or q.has("concept")):
				continue
				
			var concept = str(q.get("concept", q.get("id", "unknown")))

			if not concept_progress.has(concept):
				concept_progress[concept] = {
					"correct": 0,
					"incorrect": 0,
					"exposure": 0,
					"last_seen_day": current_day,
					"next_review_day": current_day
				}

# ==========================================================
# GET DUE CONCEPTS
# ==========================================================

func get_due_concepts(current_day: int) -> Array:
	var due: Array = []
	for concept in concept_progress.keys():
		var data = concept_progress[concept]
		# Ensure data is valid before checking date
		if typeof(data) == TYPE_DICTIONARY:
			var review_day = data.get("next_review_day", 0)
			if review_day <= current_day:
				due.append(concept)
	return due

# ==========================================================
# UPDATE (MASTERY FORMULA + FEEDBACK)
# ==========================================================

func update_concept_progress(concept: String, is_correct: bool, response_time: float, current_day: int) -> Dictionary:
	# Ensure the concept exists in our tracking dictionary
	if not concept_progress.has(concept):
		concept_progress[concept] = {
			"correct": 0, "incorrect": 0, "exposure": 0,
			"last_seen_day": current_day, "next_review_day": current_day
		}
	
	var data = concept_progress[concept]
	
	# --- UPDATE COUNTS ---
	data.exposure = data.get("exposure", 0) + 1
	if is_correct:
		data.correct = data.get("correct", 0) + 1
	else:
		data.incorrect = data.get("incorrect", 0) + 1
	
	# --- SPEED FACTOR (S) ---
	var S: int = 0
	if response_time <= 1.5:
		S = 2 # Fast
	elif response_time <= 3.0:
		S = 1 # Moderate
	else:
		S = 0 # Slow
	
	var C = data.correct
	var I = data.incorrect
	var E = max(1, data.exposure)
	
	# --- MASTERY FORMULA (M) ---
	# Formula provided for thesis: (Correct*2 + Speed - Incorrect*2) / Exposure
	var M = float((C * 2) + S - (I * 2)) / float(E)
	
	# --- SCHEDULING LOGIC ---
	var next_day: int
	var mastery_msg = ""
	
	if not is_correct:
		next_day = current_day + 1
		mastery_msg = "Mastery: Needs practice"
	elif M >= 1.5:
		next_day = current_day + 3
		mastery_msg = "Mastery: Improving (High)"
	elif M >= 0.5:
		next_day = current_day + 2
		mastery_msg = "Mastery: Moderate"
	else:
		next_day = current_day + 1
		mastery_msg = "Mastery: Needs practice"
	
	data.next_review_day = next_day
	data.last_seen_day = current_day
	
	# Save back to progress and global GameData
	concept_progress[concept] = data
	if is_instance_valid(GameData):
		GameData.quiz_concept_progress = concept_progress
	
	# --- GENERATE FEEDBACK STRINGS ---
	var performance_msg = ""
	if is_correct:
		if S == 2: performance_msg = "Nice! That was quick!"
		elif S == 1: performance_msg = "Good job!"
		else: performance_msg = "Correct! Try to be a bit faster."
	else:
		performance_msg = "Let's try that again."
		
	var exposure_msg = ""
	var is_repeat = false
	
	if E <= 1: 
		exposure_msg = "First time seeing this!"
		is_repeat = false
	elif E <= 3: 
		exposure_msg = "You're getting familiar with this"
		is_repeat = true
	else: 
		exposure_msg = "You've seen this %d times" % E
		is_repeat = true
	
	# Debug print for verification
	print("📊 Concept: %s | M: %.2f | Next Day: %d" % [concept, M, next_day])
	
	return {
		"next_day": next_day,
		"performance": performance_msg,
		"exposure": exposure_msg,
		"mastery": mastery_msg,
		"is_repeat": is_repeat
	}
