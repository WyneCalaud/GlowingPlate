extends Node

# --- Core Progression Variables ---
var current_day: int = 1          
const TOTAL_DAYS: int = 7         
var money: int = 0                
var keys: int = 0  

# --- GLOW BOARD PROGRESSION ---
var character_progress: Dictionary = {
	"Leo": 0.0,
	"Maya": 0.0,
	"Arman": 0.0
}

# --- UPGRADABLE / EXTENSION STATS ---
var max_customers_today: int = 4  
var customer_patience_multiplier: float = 1.0 

# --- DAILY TRACKING ---
var daily_money_earned: int = 0
var daily_keys_earned: int = 0
var total_customers_served_today: int = 0
var customer_history: Array = [] 

# --- SERVICE STATE MANAGEMENT ---
var returning_from_beverage: bool = false
var force_hide_accept_buttons: bool = false

enum ServiceState { IDLE, CUSTOMER_PRESENT, IN_KITCHEN, SERVED }
var service_state: ServiceState = ServiceState.IDLE
var remaining_customers: Array = []
var day_started: bool = false

# --- SCENE PATHS ---
const KITCHEN_SCENE_PATH = "res://Scenes/Gameplay/fullgameplay.tscn"
const BEVERAGE_SCENE_PATH = "res://Scenes/Gameplay/BeveragesStation.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"
const END_DAY_SCENE_PATH = "res://Scenes/Results/EndDayResults.tscn" 
const QUIZ_SCENE_PATH = "res://Scenes/Quiz/QuizScene.tscn"

# --- NEW: HAPPINESS & TIP LOGIC ---
func calculate_tip(happiness_percent: float) -> int:
	if happiness_percent >= 90.0:
		return 25 # Max tip
	elif happiness_percent >= 70.0:
		return 15
	elif happiness_percent >= 40.0:
		return 8
	elif happiness_percent >= 20.0:
		return 4
	else:
		return 1 # Minimal tip

# --- TIME & VISUAL LOGIC ---
func get_current_time_string() -> String:
	var progress = float(total_customers_served_today) / float(max_customers_today)
	var hour = 12 + int(progress * 4) 
	if hour > 12: hour -= 12
	return str(hour) + ":00 PM"

func get_sun_stage_index() -> int:
	var progress = float(total_customers_served_today) / float(max_customers_today)
	return clampi(int(progress * 4), 0, 3)

# --- CORE METHODS ---
func start_new_day():
	daily_money_earned = 0
	daily_keys_earned = 0
	total_customers_served_today = 0
	max_customers_today = clampi(4 + (current_day - 1), 4, 10) 
	if current_day <= TOTAL_DAYS:
		get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
	else:
		print("Game finished!")

func start_day_with_orders(orders: Array):
	remaining_customers = orders.duplicate()
	max_customers_today = remaining_customers.size() 
	service_state = ServiceState.IDLE
	day_started = true

func finalize_service(day_result: Dictionary):
	total_customers_served_today += 1
	customer_history.append(day_result)
	
	# Extract happiness and calculate payout
	var base_earned = day_result.get("earned_money", 0)
	var happiness = day_result.get("happiness", 100.0)
	var tip = calculate_tip(happiness)
	var total_earned = base_earned + tip
	
	money += total_earned
	daily_money_earned += total_earned
	
	# Handle Keys
	var keys_won = day_result.get("earned_keys", 0)
	keys += keys_won
	daily_keys_earned += keys_won
	
	# Handle Glow Board
	var char_id = day_result.get("character_id", "")
	if character_progress.has(char_id):
		var gain = day_result.get("prog_gain", 0.0)
		character_progress[char_id] = clamp(character_progress[char_id] + gain, 0.0, 100.0)
	
	OrderSystem.clear_prepared_data()
	get_tree().call_group("HUD", "update_all_labels")

	if remaining_customers.is_empty():
		current_day += 1
		transition_to_end_day()

# --- WRAPPERS & TRANSITIONS ---
func store_plate_contents(contents: Array): OrderSystem.prepared_plate_contents = contents

# FIX: Added function requested by the error
func add_prepared_beverage(beverage_res: Resource):
	OrderSystem.add_prepared_beverage(beverage_res)

func store_beverage_data(data: Dictionary):
	OrderSystem.prepared_beverage_data = data
	returning_from_beverage = true
	transition_to_canteen_serve() 

func transition_to_plate_prep(): get_tree().change_scene_to_file(KITCHEN_SCENE_PATH)
func transition_to_beverage_prep(): get_tree().change_scene_to_file(BEVERAGE_SCENE_PATH)
func transition_to_canteen_serve(): get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
func transition_to_end_day(): get_tree().change_scene_to_file(END_DAY_SCENE_PATH)

var saved_customer_order: Resource = null
var saved_customer_texture: Texture2D = null
func save_customer(order: Resource, tex: Texture2D):
	saved_customer_order = order
	saved_customer_texture = tex
func clear_customer():
	saved_customer_order = null
	saved_customer_texture = null

func _ready():
	add_to_group("GameData")
