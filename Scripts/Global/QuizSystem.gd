# QuizSystem.gd
extends Node

var concept_progress: Dictionary = {}

const MIN_EF: float = 1.3
const MAX_INTERVAL: int = 7 # Capped for 14-day game

func _ready():
	# Restore saved concepts from GameData
	if not GameData.quiz_concept_progress.is_empty():
		concept_progress = GameData.quiz_concept_progress

func initialize_concepts(current_day: int) -> void:
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

func get_due_concepts(current_day: int, max_per_day: int = 5) -> Array:
	var due: Array = []
	for concept in concept_progress.keys():
		var data = concept_progress[concept]
		if data.next_review_day <= current_day:
			due.append(concept)
	
	due.sort_custom(func(a, b): return concept_progress[a].interval < concept_progress[b].interval)
	if due.size() > max_per_day: due = due.slice(0, max_per_day)
	return due

func update_concept_progress(concept: String, quality: int, current_day: int) -> int:
	if not concept_progress.has(concept):
		concept_progress[concept] = {
			"repetition": 0, "interval": 0, "ease_factor": 2.5, "next_review_day": current_day
		}
	
	var data = concept_progress[concept]
	var R = data.repetition
	var I = data.interval
	var EF = data.ease_factor
	
	if quality < 3:
		R = 0
		I = 1
	else:
		if R == 0: I = 1
		elif R == 1: I = 3
		else: I = round(I * EF)
		
		EF = EF + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
		if EF < MIN_EF: EF = MIN_EF
		R += 1
	
	I = min(I, MAX_INTERVAL)
	var next_day = current_day + I
	
	data.repetition = R
	data.interval = I
	data.ease_factor = EF
	data.next_review_day = next_day
	
	concept_progress[concept] = data
	return next_day

func apply_quiz_results(results: Dictionary):
	var bonus_money = results.get("bonus_money", 0)
	GameData.money += bonus_money
	GameData.daily_money_earned += bonus_money
	GameData.start_new_day()
