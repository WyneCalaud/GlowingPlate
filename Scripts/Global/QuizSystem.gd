# QuizSystem.gd
extends Node

# ==========================================================
# CONCEPT-BASED BOUNDED SM-2 ALGORITHM
# Tracks "Ideas" (Concepts), not individual questions.
# ==========================================================

var concept_progress: Dictionary = {}

const MIN_EF: float = 1.3
const MAX_INTERVAL: int = 7 # Capped for 14-day game

# ==========================================================
# INITIALIZATION
# ==========================================================

func initialize_concepts(current_day: int) -> void:
	# Fallback safety: initialize any known concepts
	if not has_node("/root/QuestionDatabase"): return
	var concepts = QuestionDatabase.get_all_concepts()
	
	for concept in concepts:
		if not concept_progress.has(concept):
			concept_progress[concept] = {
				"repetition": 0,
				"interval": 0,
				"ease_factor": 2.5,
				"next_review_day": current_day
			}

# ==========================================================
# GET DUE CONCEPTS (The "Folders")
# ==========================================================

func get_due_concepts(current_day: int, max_per_day: int = 5) -> Array:
	var due: Array = []
	
	for concept in concept_progress.keys():
		var data = concept_progress[concept]
		if data.next_review_day <= current_day:
			due.append(concept)
	
	# Prioritize weakest concepts (lowest interval first)
	due.sort_custom(func(a, b):
		return concept_progress[a].interval < concept_progress[b].interval
	)
	
	if due.size() > max_per_day:
		due = due.slice(0, max_per_day)
	
	return due

# ==========================================================
# UPDATE CONCEPT (BOUNDED SM-2 MATH)
# ==========================================================
# Quality: 4 = Correct, 2 = Partial, 0 = Incorrect

func update_concept_progress(concept: String, quality: int, current_day: int) -> int:
	# Dynamically add concept if it's new
	if not concept_progress.has(concept):
		concept_progress[concept] = {
			"repetition": 0,
			"interval": 0,
			"ease_factor": 2.5,
			"next_review_day": current_day
		}
	
	var data = concept_progress[concept]
	
	var R = data.repetition
	var I = data.interval
	var EF = data.ease_factor
	
	# --- SM-2 LOGIC ---
	if quality < 3:
		# WRONG: Reset tracking, review tomorrow
		R = 0
		I = 1
	else:
		# CORRECT: Multiplicative expansion
		if R == 0:
			I = 1
		elif R == 1:
			I = 3
		else:
			I = round(I * EF)
		
		# Update Ease Factor (Hardness)
		EF = EF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
		if EF < MIN_EF:
			EF = MIN_EF
		
		R += 1
	
	# Bound the maximum interval to fit the 14-day game cycle
	I = min(I, MAX_INTERVAL)
	
	var next_day = current_day + I
	
	data.repetition = R
	data.interval = I
	data.ease_factor = EF
	data.next_review_day = next_day
	
	concept_progress[concept] = data
	return next_day

# ==========================================================
# REWARDS
# ==========================================================

func apply_quiz_results(results: Dictionary):
	var bonus_money = results.get("bonus_money", 0)
	GameData.money += bonus_money
	GameData.daily_money_earned += bonus_money
	GameData.start_new_day()
