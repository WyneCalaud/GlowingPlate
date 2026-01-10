extends Node

# --- Core Progression Variables ---
var current_day: int = 1         
const TOTAL_DAYS: int = 7        
var money: int = 0               
var reputation_score: float = 0.0 

# --- DAILY TRACKING ---
var daily_money_earned: int = 0
var daily_reputation_gained: float = 0.0

# --- Tracking Data ---
var customer_history: Array = [] 

# --- SERVICE STATE MANAGEMENT ---
# NOTE: Food arrays removed. They are now in OrderSystem.
var returning_from_beverage: bool = false
var force_hide_accept_buttons: bool = false

enum ServiceState {
	IDLE,
	CUSTOMER_PRESENT,
	IN_KITCHEN,
	SERVED
}

var service_state: ServiceState = ServiceState.IDLE
var remaining_customers: Array = []
var day_started: bool = false

# --- SCENE PATHS ---
const KITCHEN_SCENE_PATH = "res://Scenes/Gameplay/fullgameplay.tscn"
const BEVERAGE_SCENE_PATH = "res://Scenes/Gameplay/BeveragesStation.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"
const END_DAY_SCENE_PATH = "res://Scenes/Results/EndDayResults.tscn" 
const QUIZ_SCENE_PATH = "res://Scenes/Quiz/QuizScene.tscn"

# ====================================================================
# --- DATA TRANSFER WRAPPERS (Compatibility Layer) ---
# ====================================================================

# These functions exist so your Drag & Drop scripts don't break.
# They simply forward the data to the new OrderSystem.

func store_plate_contents(contents: Array, go_to_beverage: bool = true) -> void:
	# Forward to OrderSystem
	OrderSystem.prepared_plate_contents = contents
	print("GAME_DATA: Delegating plate storage to OrderSystem.")

func store_beverage_data(data: Dictionary):
	# Forward to OrderSystem
	OrderSystem.prepared_beverage_data = data
	print("GAME_DATA: Delegating beverage storage to OrderSystem.")
	
	returning_from_beverage = true
	transition_to_canteen_serve() 

func add_prepared_beverage(beverage_res: Resource) -> void:
	OrderSystem.add_prepared_beverage(beverage_res)

func add_beverage_to_plate(beverage_resource: Resource):
	OrderSystem.add_prepared_beverage(beverage_resource)

# Wrapper for Order Generation
func generate_order_for_day(day: int) -> Dictionary:
	return OrderSystem.generate_order_for_day(day)

# ====================================================================
# --- SCENE TRANSITIONS ---
# ====================================================================

func transition_to_plate_prep():
	get_tree().change_scene_to_file(KITCHEN_SCENE_PATH)

func transition_to_beverage_prep():
	OrderSystem.prepared_beverage_data.clear()
	get_tree().change_scene_to_file("res://Scenes/Gameplay/BeverageStation.tscn")

func transition_to_canteen_serve():
	get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
	
func transition_to_end_day():
	get_tree().change_scene_to_file(END_DAY_SCENE_PATH)

func transition_to_quiz():
	get_tree().change_scene_to_file(QUIZ_SCENE_PATH)

# ====================================================================
# --- CORE METHODS ---
# ====================================================================

func start_new_day():
	daily_money_earned = 0
	daily_reputation_gained = 0.0
	
	if current_day <= TOTAL_DAYS:
		print("Starting Day %s" % current_day)
		get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
	else:
		print("Game finished! Showing results.")

func start_day_with_orders(orders: Array):
	remaining_customers = orders.duplicate()
	service_state = ServiceState.IDLE
	day_started = true

func finalize_service(day_result: Dictionary):
	customer_history.append(day_result)
	money += day_result.get("earned_money", 0)
	reputation_score += day_result.get("reputation_change", 0.0)
	
	# Update Daily Stats
	daily_money_earned += day_result.get("earned_money", 0)
	daily_reputation_gained += day_result.get("reputation_change", 0.0)
	
	# Clear data in OrderSystem
	OrderSystem.clear_prepared_data()
	
	var day_end_message = "Service finalized. New Money: %s" % money
	print(day_end_message)

	if remaining_customers.is_empty():
		print("Day complete! Transitioning to End Day Results.")
		current_day += 1
		transition_to_end_day()
	else:
		# Wait for lobby to spawn next customer
		pass

func end_day(day_result: Dictionary):
	finalize_service(day_result)

var saved_customer_order: Resource = null
var saved_customer_texture: Texture2D = null

func save_customer(order: Resource, tex: Texture2D):
	saved_customer_order = order
	saved_customer_texture = tex

func clear_customer():
	saved_customer_order = null
	saved_customer_texture = null

# Logic wrappers for validation (in case UI calls GD directly)
func is_plate_correct() -> bool:
	return OrderSystem.is_plate_correct()

func is_beverage_correct() -> bool:
	return OrderSystem.is_beverage_correct()

func _ready():
	add_to_group("GameData")
