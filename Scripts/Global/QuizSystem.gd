extends Node

# Stores the SRS progress: {"Q_ID": {"streak": 0, "next_review_day": 1}}
var quiz_progress: Dictionary = {} 

const SRS_INTERVALS: Dictionary = {
	0: 1,  # Wrong answer: Review in 1 day
	1: 3,  # Correct once: Review in 3 days
	2: 7,  # Correct twice: Review in 7 days
	3: 14, # Correct three times: Review in 14 days
}

func update_question_progress(question_id: String, is_correct: bool, current_day: int) -> int:
	if not quiz_progress.has(question_id):
		quiz_progress[question_id] = {"streak": 0, "next_review_day": current_day}
		
	var progress = quiz_progress[question_id]
	var current_streak = progress.streak
	
	var new_streak: int
	if is_correct:
		var max_streak = SRS_INTERVALS.keys().max()
		new_streak = min(current_streak + 1, max_streak)
	else:
		new_streak = 0
		
	var interval = SRS_INTERVALS.get(new_streak, 1) 
	var next_day = current_day + interval
	
	progress.streak = new_streak
	progress.next_review_day = next_day
	quiz_progress[question_id] = progress
	
	return next_day

func apply_quiz_results(results: Dictionary):
	var bonus_money = results.get("bonus_money", 0)
	
	# Apply only money as reputation was removed from GameData
	GameData.money += bonus_money
	
	# Update daily tracking so it shows up in results if needed
	GameData.daily_money_earned += bonus_money
	
	print("QUIZ SYSTEM: Applied bonus money: $", bonus_money)
	
	# Trigger the next day cycle
	GameData.start_new_day()
