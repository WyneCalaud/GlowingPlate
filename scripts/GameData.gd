# GameData.gd
extends Node

# --- Core Progression Variables ---
var current_day: int = 1         # The current day the player is on (starts at 1)
const TOTAL_DAYS: int = 30       # Total duration of the game
var money: int = 0               # Player's currency
var reputation_score: float = 0.0 # Customer satisfaction/reputation (influences difficulty/reactions)

# --- Tracking Data ---
# Array to store results of previous days (e.g., accuracy, money earned)
var customer_history: Array = [] 

# --- Food Database Placeholder (To be completed in Task 1.2) ---
# This dictionary will hold preloaded FoodItemData resources
const FOOD_DB: Dictionary = {}

# --- Core Methods ---

# Called to start the next day's gameplay loop
func start_new_day():
	if current_day <= TOTAL_DAYS:
		print("Starting Day " + str(current_day))
		
		# NOTE: In a finished game, you would change scenes here
		# get_tree().change_scene_to_file("res://Scenes/LobbyCanteen.tscn")
		
	else:
		print("Game finished! Showing results.")
		# NOTE: Transition to the final score/ending scene

# Called by the GameplayManager when a plate is served and scored
func end_day(day_result: Dictionary):
	# 1. Update Game State
	customer_history.append(day_result)
	money += day_result.get("earned_money", 0)
	reputation_score += day_result.get("reputation_change", 0.0)
	
	# 2. Advance the Day
	current_day += 1
	
	var day_end_message = "Day %s ended. New Money: %s, New Reputation: %s" % [current_day - 1, money, reputation_score]
	print(day_end_message)
	
	# Optional: Wait for a summary screen before starting the next day
	# start_new_day() 
	
# Called by the GameplayManager to fetch the required order
func generate_order_for_day(day: int) -> Dictionary:
	# This will be fully implemented in Task 1.2, but we need the placeholder
	print("Generating order for Day %s" % day)
	
	# Placeholder for Day 1 Order (uses temporary strings)
	if day == 1:
		return {
			"Go": "RICE",
			"Grow": "CHICKEN_LEG",
			"GlowVeg": "MIXED_VEGGIES",
			"GlowFru": "WATERMELON"
		}
	return {}
