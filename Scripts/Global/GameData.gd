extends Node

# --- Core Progression Variables ---
var current_day: int = 1         # The current day the player is on (starts at 1)
const TOTAL_DAYS: int = 7        # Total duration of the game (Updated from 30)
var money: int = 0               # Player's currency
var reputation_score: float = 0.0 # Customer satisfaction/reputation

# --- Tracking Data ---
var customer_history: Array = [] # Array to store results of previous days

# --- SERVICE STATE MANAGEMENT ---
var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}

var prepared_is_correct: bool = false

# Placeholder for the current customer's requirements 
var current_customer_order: Dictionary = {
	"age_group": "6-9",
	"required_plate": {}, # Actual food internal keys (e.g., "RICE")
	"required_beverage": "" # Beverage internal key (e.g., "MILK")
}

# --- Food Database (User's Existing + Milk/Almond Milk) ---
# Preloads all FoodItemData resources for instant access
const FOOD_DB: Dictionary = {
	# Food Items
	"RICE": preload("res://Data/Food/Rice.tres"),
	"CHICKEN_LEG": preload("res://Data/Food/Chicken.tres"),
	"MIXED_VEGGIES": preload("res://Data/Food/MixedVeggies.tres"),
	"WATERMELON": preload("res://Data/Food/Watermelon.tres"),
	
	# NEW BEVERAGE ITEMS
	"REGULAR_MILK": preload("res://Data/Drink/RegularMilk.tres"),
	"ALMOND_MILK": preload("res://Data/Drink/AlmondMilk.tres"),
}

# --- SCENE PATHS (Critical for transitions) ---
const KITCHEN_SCENE_PATH = "res://Scenes/Gameplay/fullgameplay.tscn"
const BEVERAGE_SCENE_PATH = "res://Scenes/Gameplay/BeveragesStation.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"


# ====================================================================
# --- DATA TRANSFER FUNCTIONS ---
# ====================================================================

# 1. Called by the Plate's script in the Kitchen scene when dropped on the Serve Zone.
# GameData.gd
# Call store_plate_contents(contents, go_to_beverage=false) to return to canteen.
func store_plate_contents(contents: Array, go_to_beverage: bool = true) -> void:
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
	
	transition_to_canteen_serve() 

# Called from BeverageStation when a glass is completed (or skipped)
func add_beverage_to_plate(beverage_resource: Resource):
	if beverage_resource == null:
		print("ERROR: Tried to add null beverage")
		return
	
	var key = beverage_resource.internal_key
	prepared_beverage_data[key] = beverage_resource
	print("GAME_DATA: Added beverage to prepared_beverage_data:", key)


# ====================================================================
# --- SCENE TRANSITION FUNCTIONS (Standardized to use constants) ---
# ====================================================================

func transition_to_plate_prep():
	get_tree().change_scene_to_file(KITCHEN_SCENE_PATH)

func transition_to_beverage_prep():
	get_tree().change_scene_to_file("res://Scenes/Gameplay/BeverageStation.tscn")

func transition_to_canteen_serve():
	get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)


# ====================================================================
# --- Core Methods ---
# ====================================================================

# Called to start the next day's gameplay loop
func start_new_day():
	if current_day <= TOTAL_DAYS:
		print("Starting Day %s" % current_day)
		
		get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
		
	else:
		print("Game finished! Showing results.")
		# NOTE: Transition to the final score/ending scene

# Called by the Canteen scene AFTER the customer interaction and scoring is complete
func finalize_service(day_result: Dictionary):
	# 1. Update Game State
	customer_history.append(day_result)
	money += day_result.get("earned_money", 0)
	reputation_score += day_result.get("reputation_change", 0.0)
	
	# 2. Clear stored preparation data for the next customer/service
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()
	current_customer_order.required_plate.clear()
	current_customer_order.required_beverage = ""
	
	# 3. Advance the Day 
	current_day += 1
	
	var day_end_message = "Service finalized. New Money: %s, New Reputation: %s" % [money, reputation_score]
	print(day_end_message)
	
	# TODO: Trigger Quiz/Next Customer/Day transition here.
	# Example: start_new_day()

# NOTE: Retaining this function name for compatibility.
func end_day(day_result: Dictionary):
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
			"Beverage": "ALMOND_MILK" # Using Almond Milk as the example beverage
		}
	
	# Store the required order in the global state for later scoring
	current_customer_order.required_plate.clear()
	current_customer_order.required_beverage = order_data.get("Beverage", "")
	for k in order_data.keys():
		if k != "Beverage":
			current_customer_order.required_plate[k] = order_data[k]
	
	return order_data

var saved_customer_order: CustomerOrder = null
var saved_customer_texture: Texture2D = null

func save_customer(order: CustomerOrder, tex: Texture2D):
	saved_customer_order = order
	saved_customer_texture = tex

func clear_customer():
	saved_customer_order = null
	saved_customer_texture = null
	
func is_plate_correct() -> bool:
	print("PLATED:", prepared_plate_contents)
	print("REQUIRED:", current_customer_order.required_plate)

	var plated_map := {
		"Go": "",
		"Grow": "",
		"GlowVeg": "",
		"GlowFru": ""
	}

	for entry in prepared_plate_contents:
		var res := entry["item"] as CustomItemData
		var slot : String = entry["accepted_type"].strip_edges() # remove accidental whitespace
		print("DEBUG SLOT:", slot, "| internal_key:", res.internal_key)
		plated_map[slot] = res.internal_key

	for key in current_customer_order.required_plate.keys():
		var required : String = current_customer_order.required_plate[key].strip_edges()
		var plated : String = plated_map.get(key, "").strip_edges()
		print("COMPARING:", key, "| plated:", plated, "| required:", required)
		if plated != required:
			print("❌ MISMATCH:", key)
			return false

	print("✅ Plate correct!")
	return true
