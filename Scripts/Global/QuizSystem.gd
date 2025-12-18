extends Node

# --- DATA PERSISTENCE ---
# Stores the SRS progress: {"Q_ID": {"streak": 0, "next_review_day": 1}}
# This is saved globally and persists between quiz sessions.
var quiz_progress: Dictionary = {} 

# --- SRS CONFIGURATION ---
# Determines how many days to wait before the next review based on current streak
const SRS_INTERVALS: Dictionary = {
	0: 1,  # Wrong answer: Review in 1 day (tomorrow)
	1: 3,  # Correct once: Review in 3 days
	2: 7,  # Correct twice: Review in 7 days
	3: 14, # Correct three times: Review in 14 days
}

# --- LOGIC: UPDATE PROGRESS ---
# Called by the QuizManager after each question answer
func update_question_progress(question_id: String, is_correct: bool, current_day: int) -> int:
	if not quiz_progress.has(question_id):
		quiz_progress[question_id] = {"streak": 0, "next_review_day": current_day}
		
	var progress = quiz_progress[question_id]
	var current_streak = progress.streak
	
	# 1. Update Streak
	var new_streak: int
	if is_correct:
		var max_streak = SRS_INTERVALS.keys().max()
		new_streak = min(current_streak + 1, max_streak)
	else:
		new_streak = 0
		
	# 2. Determine Interval and Next Review Day
	var interval = SRS_INTERVALS.get(new_streak, 1) 
	var next_day = current_day + interval
	
	# 3. Save back to dictionary
	progress.streak = new_streak
	progress.next_review_day = next_day
	quiz_progress[question_id] = progress
	
	print("SRS Update [%s]: Correct: %s, New Streak: %d, Next Review: Day %d" % [question_id, is_correct, new_streak, next_day])
	return next_day

# --- LOGIC: APPLY FINAL REWARDS ---
# Called when the quiz scene is finished
func apply_quiz_results(results: Dictionary):
	var bonus_money = results.get("bonus_money", 0)
	var bonus_reputation = results.get("bonus_reputation", 0.0)
	
	# Update Global GameData (Assumes GameData is an Autoload)
	GameData.money += bonus_money
	GameData.reputation_score += bonus_reputation
	
	print("QUIZ SYSTEM: Results applied. Returning to Lobby.")
	
	# Return to the next day flow
	GameData.start_new_day()
