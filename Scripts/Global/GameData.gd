extends Node

# --- Core Progression Variables (User's Existing) ---
var current_day: int = 1         # The current day the player is on (starts at 1)
const TOTAL_DAYS: int = 30       # Total duration of the game
var money: int = 0               # Player's currency
var reputation_score: float = 0.0 # Customer satisfaction/reputation

# --- Tracking Data (User's Existing) ---
var customer_history: Array = [] # Array to store results of previous days

# --- SERVICE STATE MANAGEMENT (NEW: Data Transfer and Customer Order) ---

# Stores the results of the preparation stages (set by Kitchen/Beverage scenes)
var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}

# Placeholder for the current customer's requirements 
var current_customer_order: Dictionary = {
	"age_group": "6-9",
	"required_plate": {}, # Actual food internal keys (e.g., "RICE")
	"required_beverage": "" # Beverage internal key (e.g., "MILK")
}

# --- Food Database (User's Existing) ---
# Preloads all FoodItemData resources for instant access
const FOOD_DB: Dictionary = {
	# NOTE: The keys must match the 'internal_key' property set in your .tres files!
	"RICE": preload("res://Data/Food/Rice.tres"),
	"CHICKEN_LEG": preload("res://Data/Food/Chicken.tres"),
	"MIXED_VEGGIES": preload("res://Data/Food/MixedVeggies.tres"),
	"WATERMELON": preload("res://Data/Food/Watermelon.tres"),
}

# --- SCENE PATHS (NEW: Critical for transitions) ---
const KITCHEN_SCENE_PATH = "res://Scenes/Gameplay/fullgameplay.tscn"
const BEVERAGE_SCENE_PATH = "res://Scenes/Gameplay/BeveragesStation.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"


# ====================================================================
# --- DATA TRANSFER FUNCTIONS: Used by preparation scenes (Kitchen/Beverage) ---
# ====================================================================

# 1. Called by the Plate's script in the Kitchen scene when dropped on the Serve Zone.
# GameData.gd
# Call store_plate_contents(contents, go_to_beverage=false) to return to canteen.
func store_plate_contents(contents: Array, go_to_beverage: bool = false) -> void:
	prepared_plate_contents = contents
	print("GAME_DATA: Plate contents stored. go_to_beverage=%s" % go_to_beverage)

	# Decide next scene depending on the flag
	if go_to_beverage:
		transition_to_beverage_prep()
	else:
		transition_to_canteen_serve()


# 2. Called by the Beverage scene when the drink is completed.
func store_beverage_data(data: Dictionary):
	prepared_beverage_data = data
	print("GAME_DATA: Beverage data stored. Transitioning to Canteen Serve.")
	
	# Transition back to the Canteen for final assembly and serving
	transition_to_canteen_serve() 


# ====================================================================
# --- SCENE TRANSITION FUNCTIONS ---
# ====================================================================

func transition_to_plate_prep():
	get_tree().change_scene_to_file("res://Scenes/Gameplay/fullgameplay.tscn")

func transition_to_beverage_prep():
	get_tree().change_scene_to_file("res://Scenes/Gameplay/BeverageStation.tscn")

func transition_to_canteen_serve():
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")


# ====================================================================
# --- Core Methods (User's Existing + Updates) ---
# ====================================================================

# Called to start the next day's gameplay loop
func start_new_day():
	if current_day <= TOTAL_DAYS:
		print("Starting Day %s" % current_day)
		
		# Start customer interaction flow (e.g., transition to Canteen)
		get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
		
	else:
		print("Game finished! Showing results.")
		# NOTE: Transition to the final score/ending scene

# Called by the Canteen scene AFTER the customer interaction and scoring is complete
func finalize_service(day_result: Dictionary):
	# 1. Update Game State (from original end_day logic)
	customer_history.append(day_result)
	money += day_result.get("earned_money", 0)
	reputation_score += day_result.get("reputation_change", 0.0)
	
	# 2. Clear stored preparation data for the next customer/service
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()
	current_customer_order.required_plate.clear()
	current_customer_order.required_beverage = ""
	
	# 3. Advance the Day (The quiz/day logic goes here based on your flow)
	current_day += 1
	
	# Use GDScript's % format for clean output
	var day_end_message = "Service finalized. New Money: %s, New Reputation: %s" % [money, reputation_score]
	print(day_end_message)
	
	# TODO: Trigger Quiz/Next Customer/Day transition here.
	# Example: start_new_day()

# NOTE: The original `end_day` is now repurposed to call `finalize_service` if needed, 
# or removed if all score/clear logic is moved to `finalize_service`.
func end_day(day_result: Dictionary):
	# Retaining this function name for compatibility, but its purpose is now service finalization.
	finalize_service(day_result)

# Called by the GameplayManager to fetch the required order
# Returns a dictionary where keys are slot types ("Go", "Grow") and values are 
# the required food's internal key strings ("RICE", "CHICKEN_LEG").
func generate_order_for_day(day: int) -> Dictionary:
	print("Generating order for Day %s" % day)
	
	# Placeholder for Day 1 Order (Uses the internal_key strings from FOOD_DB)
	var order_data = {}
	if day == 1:
		order_data = {
			"Go": "RICE",
			"Grow": "CHICKEN_LEG",
			"GlowVeg": "MIXED_VEGGIES",
			"GlowFru": "WATERMELON",
			"Beverage1": "WATER",
			"Beverage2": "MILK_CARTON"
		}
	
	# Store the required order in the global state for later scoring
	current_customer_order.required_plate = order_data.filter(func(k, _v): return k != "Beverage")
	current_customer_order.required_beverage = order_data.get("Beverage", "")
	
	return order_data
