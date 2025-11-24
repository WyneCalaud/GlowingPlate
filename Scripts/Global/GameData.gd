# GameData.gd
extends Node

# --- Core Progression Variables ---
var current_day: int = 1         # The current day the player is on (starts at 1)
const TOTAL_DAYS: int = 30       # Total duration of the game
var money: int = 0               # Player's currency
var reputation_score: float = 0.0 # Customer satisfaction/reputation (influences difficulty/reactions)

# --- Tracking Data ---
var customer_history: Array = [] # Array to store results of previous days

# --- Food Database (Populated in Task 1.2) ---
# Preloads all FoodItemData resources for instant access
const FOOD_DB: Dictionary = {
	# NOTE: The keys must match the 'internal_key' property set in your .tres files!
	"RICE": preload("res://Data/Food/Rice.tres"),
	"CHICKEN_LEG": preload("res://Data/Food/Chicken.tres"),
	"MIXED_VEGGIES": preload("res://Data/Food/MixedVeggies.tres"),
	"WATERMELON": preload("res://Data/Food/Watermelon.tres"),
}

# --- Core Methods ---

# Called to start the next day's gameplay loop
func start_new_day():
	if current_day <= TOTAL_DAYS:
		print("Starting Day %s" % current_day)
		
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
	
	# Use GDScript's % format for clean output
	var day_end_message = "Day %s ended. New Money: %s, New Reputation: %s" % [current_day - 1, money, reputation_score]
	print(day_end_message)
	
	# Optional: Wait for a summary screen before starting the next day
	# start_new_day() 
	
# Called by the GameplayManager to fetch the required order
# Returns a dictionary where keys are slot types ("Go", "Grow") and values are 
# the required food's internal key strings ("RICE", "CHICKEN_LEG").
func generate_order_for_day(day: int) -> Dictionary:
	print("Generating order for Day %s" % day)
	
	# Placeholder for Day 1 Order (Uses the internal_key strings from FOOD_DB)
	if day == 1:
		return {
			"Go": "RICE",
			"Grow": "CHICKEN_LEG",
			"GlowVeg": "MIXED_VEGGIES",
			"GlowFru": "WATERMELON"
		}
	
	# Future: Add logic here for more complex days (Day 2, Day 3, etc.)
	return {}
