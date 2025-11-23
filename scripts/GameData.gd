# GameData.gd (Autoload)
extends Node

# --- Core Progression Variables ---
var current_day: int = 1
const TOTAL_DAYS: int = 30

# --- Tracking Data ---
var customer_history: Array = [] # Stores results of previous days
var money: int = 0
var reputation_score: float = 0.0 # Influences future customer reactions/difficulty

# --- Core Methods ---
func start_new_day():
	if current_day <= TOTAL_DAYS:
		print("Starting Day " + str(current_day))
		# 1. Generate the order logic here (or call a function that does)
		var new_order = generate_order_for_day(current_day) 
		
		# 2. Transition to the main gameplay scene (e.g., LobbyCanteen.tscn)
		get_tree().change_scene_to_file("res://Scenes/LobbyCanteen.tscn")
	else:
		print("Game finished!")
		# Trigger the final results scene

func end_day(day_result: Dictionary):
	# This is called by the GameplayManager when the plate is served.
	
	# 1. Update Game State
	customer_history.append(day_result)
	money += day_result.get("earned_money", 0)
	reputation_score += day_result.get("reputation_change", 0.0)
	
	# 2. Advance the Day
	current_day += 1
	
	# 3. Transition to a break screen or start the next day
	# For now, just print the result:
	print("Day ended. Accuracy: " + str(day_result.get("accuracy", 0)))
	
	# Example: You would usually fade out, show a daily summary, then call start_new_day()
	
# --- Order Generation ---
func generate_order_for_day(day: int) -> Dictionary:
	# Use the day number, difficulty, and reputation to determine the order.
	# Day 1: Always Rice, Chicken, Veggies, Watermelon.
	if day == 1:
		return {
			"Go": "Rice",
			"Grow": "Chicken",
			"GlowVeg": "Mixed Veggies",
			"GlowFru": "Watermelon"
		}
	else:
		# Implement complex order generation based on unlocked foods or a fixed list
		return {}
