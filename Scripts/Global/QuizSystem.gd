extends Node

var concept_progress: Dictionary = {}

func initialize_concepts(current_day: int) -> void:
	if not has_node("/root/QuestionDatabase"):
		return

	# 🔥 ALWAYS START FROM SAVED DATA
	if GameData.quiz_concept_progress != null and GameData.quiz_concept_progress.size() > 0:
		concept_progress = GameData.quiz_concept_progress.duplicate(true)
		print("✅ Loaded saved concept progress:", concept_progress.size())
	else:
		concept_progress.clear()
		print("⚠️ No saved concept progress found")

	var all_questions = QuestionDatabase.get_all_questions()

	for q in all_questions:
		var concept = q.get("concept", q["id"])

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
		if data.next_review_day <= current_day:
			due.append(concept)
	return due

# ==========================================================
# UPDATE (FORMULA BASED + FEEDBACK GENERATION)
# ==========================================================

# 🔥 CHANGED: Now returns a Dictionary with all the UI strings + next_day
func update_concept_progress(concept: String, is_correct: bool, response_time: float, current_day: int) -> Dictionary:
	
	if not concept_progress.has(concept):
		concept_progress[concept] = {
			"correct": 0, "incorrect": 0, "exposure": 0,
			"last_seen_day": current_day, "next_review_day": current_day
		}
	
	var data = concept_progress[concept]
	
	# --- UPDATE COUNTS ---
	data.exposure += 1
	if is_correct:
		data.correct += 1
	else:
		data.incorrect += 1
	
	# --- SPEED FACTOR ---
	var S := 0
	if response_time <= 1.5:
		S = 2 # Fast
	elif response_time <= 3.0:
		S = 1 # Moderate
	else:
		S = 0 # Slow
	
	var C = data.correct
	var I = data.incorrect
	var E = max(1, data.exposure)
	
	# --- MASTERY FORMULA ---
	var M = float((C * 2) + S - (I * 2)) / float(E)
	
	# --- SCHEDULING ---
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
	
	concept_progress[concept] = data
	GameData.quiz_concept_progress = concept_progress
	
	# --- GENERATE STRINGS FOR THE UI POPUP ---
	var performance_msg = ""
	if is_correct:
		if S == 2: performance_msg = "Nice! That was quick!"
		elif S == 1: performance_msg = "Good job!"
		else: performance_msg = "Correct! Try to be a bit faster."
	else:
		performance_msg = "Let's try that again."
		
	var exposure_msg = ""
	if E == 1: exposure_msg = "First time seeing this!"
	elif E <= 3: exposure_msg = "You're getting familiar with this"
	else: exposure_msg = "You've seen this %d times" % E
	
	# --- DEBUG (For thesis proof) ---
	print("📊 CONCEPT UPDATE: ", concept)
	print("Time: ", response_time, "s | C:", C, " I:", I, " E:", E, " S:", S)
	print("Mastery Score (M): ", M)
	print("--------------------")
	
	return {
		"next_day": next_day,
		"performance": performance_msg,
		"exposure": exposure_msg,
		"mastery": mastery_msg
	}
