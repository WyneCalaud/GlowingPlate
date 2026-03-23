extends Node

# SM-2 (SuperMemo-2) Spaced Repetition Logic
# Tracks concepts to ensure players review missed content and space out mastered content.

var concept_progress: Dictionary = {}

const MIN_EF: float = 1.3
const MAX_INTERVAL: int = 14 # Capped for a 14-day game loop

func _ready():
	# Restore saved concepts from GameData on launch
	if GameData.get("quiz_concept_progress") != null and not GameData.quiz_concept_progress.is_empty():
		concept_progress = GameData.quiz_concept_progress

func initialize_concepts(current_day: int) -> void:
	# FIX: We no longer pre-load all concepts here. 
	# Pre-loading them was causing unseen concepts to jump the line and block missed questions.
	# Concepts will now dynamically be added inside update_concept_progress() only AFTER they are answered.
	pass

func get_due_concepts(current_day: int, max_per_day: int = 5) -> Array:
	var due: Array = []
	for concept in concept_progress.keys():
		var data = concept_progress[concept]
		# A concept is due if the current day has reached or passed the scheduled review day
		if data.next_review_day <= current_day:
			due.append(concept)
	
	# Sort: Newer/more urgent reviews (shorter intervals like wrong answers) first
	due.sort_custom(func(a, b): return concept_progress[a].interval < concept_progress[b].interval)
	
	if due.size() > max_per_day: 
		due = due.slice(0, max_per_day)
	return due

func update_concept_progress(concept: String, quality: int, current_day: int) -> int:
	# If this is the FIRST time the player has seen this concept, initialize it now!
	if not concept_progress.has(concept):
		concept_progress[concept] = {
			"repetition": 0, "interval": 0, "ease_factor": 2.5, "next_review_day": current_day
		}
	
	var data = concept_progress[concept]
	var R = data.repetition
	var I = data.interval
	var EF = data.ease_factor
	
	# QUALITY MAPPING:
	# 0-2: Incorrect/Fail -> Reset
	# 3-5: Success -> Expand Interval
	
	if quality < 3:
		# RESET LOGIC: If wrong, restart the repetition count and set interval to 1 (see tomorrow)
		R = 0
		I = 1
	else:
		# SUCCESS LOGIC: Expand the gap based on Ease Factor
		if R == 0:
			I = 1   # First time right: review tomorrow
		elif R == 1:
			I = 3   # Second time right: skip a few days
		else:
			I = ceil(I * EF) # Subsequent times: multiply by Ease Factor
		
		# Update Ease Factor based on performance (SM-2 formula)
		EF = EF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
		if EF < MIN_EF: EF = MIN_EF
		
		R += 1
	
	# Cap the interval so they don't disappear for longer than the game lasts
	I = min(I, MAX_INTERVAL)
	
	# Calculate the exact day for the next appearance
	var next_day = current_day + I
	
	data.repetition = R
	data.interval = I
	data.ease_factor = EF
	data.next_review_day = next_day
	
	concept_progress[concept] = data
	
	# Sync immediately to GameData for safety
	GameData.quiz_concept_progress = concept_progress
	
	return next_day

func apply_quiz_results(_results: Dictionary):
	# Final confirmation that data is synced to persistence
	GameData.quiz_concept_progress = concept_progress
	GameData.save_game()
