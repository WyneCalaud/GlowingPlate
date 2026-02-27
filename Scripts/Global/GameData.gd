# GameData.gd
extends Node

var kitchen_tutorial_completed: bool = true

var current_customer_age_group: String = ""
var player_name : String = ""

# --- Core Progression Variables ---
var current_day: int = 1         
const TOTAL_DAYS: int = 14         
var money: int = 900                
var keys: int = 60  

var matching_tutorial_completed: bool = false

const SAVE_PATH := "user://save_data.json"
var shown_food_intros := {}

# --- QUIZ PROGRESSION (Saved State) ---
var quiz_question_progress: Dictionary = {}
var quiz_concept_progress: Dictionary = {}

# --- GLOW BOARD PROGRESSION ---
var character_progress: Dictionary = {
	"Leo": 0.0,
	"Maya": 0.0,
	"Arman": 0.0
}

# --- CHARACTER VISUAL STAGES ---
# 1 = Current
# 2 = Better
# 3 = Glowing
var character_stage: Dictionary = {
	"Leo": 1,
	"Maya": 1,
	"Norma": 1
}


# --- UPGRADABLE / EXTENSION STATS ---
var max_customers_today: int = 4  
var customer_patience_multiplier: float = 1.0 

var purchased_upgrades: Dictionary = {}

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

# -----------------------------
# GLOBAL PATIENCE SYSTEM
# -----------------------------
var customer_patience := 100.0
var patience_running := false


# --- SCENE PATHS ---
const KITCHEN_SCENE_PATH = "res://Scenes/Gameplay/fullgameplay.tscn"
const BEVERAGE_SCENE_PATH = "res://Scenes/Gameplay/BeveragesStation.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"
const END_DAY_SCENE_PATH = "res://Scenes/Results/EndDayResults.tscn" 
const QUIZ_SCENE_PATH = "res://Scenes/Quiz/QuizScene.tscn"

func _ready():
	add_to_group("GameData")
	load_game()
	_apply_saved_upgrades()

func _apply_saved_upgrades():
	if purchased_upgrades.has("PatientCustomers"):
		customer_patience_multiplier = 1.5

# --- ECONOMY HELPER (FIX FOR CRASH) ---
func add_money(amount: int) -> void:
	money += amount
	# Update any UI listening for changes
	get_tree().call_group("HUD", "update_all_labels")
	print("Money updated: ", money)

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

	var performance_multiplier := 1.0

	if happiness >= 75:
		performance_multiplier = 1.0        # full pay
	elif happiness >= 50:
		performance_multiplier = 0.8
	elif happiness >= 25:
		performance_multiplier = 0.6
	else:
		performance_multiplier = 0.4

	var adjusted_base = int(base_earned * performance_multiplier)

	var tip = calculate_tip(happiness)
	var total_earned = adjusted_base + tip
	
	money += total_earned
	daily_money_earned += total_earned
	
	# Handle Keys
	var keys_won = day_result.get("earned_keys", 0)

	var special_char: String = day_result.get("character_id", "") as String
	var is_correct: bool = day_result.get("is_correct", false)

	# ⭐ Only give special bonus if order was correct
	if is_correct and special_char in ["Leo","Maya","Norma"]:
		keys_won += 5

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
		day_started = false
		current_day += 1
		transition_to_end_day()
	
	save_game()

# --- WRAPPERS & TRANSITIONS ---
func store_plate_contents(contents: Array): OrderSystem.prepared_plate_contents = contents

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

	# ⭐ NEW
	if order and order.has_method("get"):
		current_customer_age_group = order.get_age_group()

	# Tell HUD to refresh
	get_tree().call_group("HUD", "update_age_group_display")

func clear_customer():
	saved_customer_order = null
	saved_customer_texture = null
	current_customer_age_group = ""

	get_tree().call_group("HUD", "update_age_group_display")


# =========================
# SPECIAL CHARACTER HELPERS
# =========================

func get_character_stage(char_name: String) -> int:
	if character_stage.has(char_name):
		return character_stage[char_name]
	return 1


func start_next_day_flow():
	save_game()
	if current_day == 1:
		get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
		return

	if current_day >= 2 and current_day <= 5:
		get_tree().change_scene_to_file("res://Scenes/News/news_scene.tscn")
		return

	# Day 6+ → no news
	get_tree().change_scene_to_file("res://Scenes/MiniGame/matching_game.tscn")


func save_game():
	# Ensure we pull the latest quiz data before saving
	if has_node("/root/QuizProgress"):
		quiz_question_progress = get_node("/root/QuizProgress").question_progress
	if has_node("/root/QuizSystem"):
		quiz_concept_progress = get_node("/root/QuizSystem").concept_progress
		
	var save_data = {
		"kitchen_tutorial_completed": kitchen_tutorial_completed,
		"current_day": current_day,
		"money": money,
		"keys": keys,
		"player_name": player_name,
		"matching_tutorial_completed": matching_tutorial_completed,
		"character_progress": character_progress,
		"character_stage": character_stage,
		"purchased_upgrades": purchased_upgrades,
		"shown_food_intros": shown_food_intros,
		"quiz_question_progress": quiz_question_progress,
		"quiz_concept_progress": quiz_concept_progress
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Game Saved.")
	else:
		print("Save Failed.")


func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("No save file found.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		print("Failed to open save file.")
		return

	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		print("Corrupted save file.")
		return

	current_day = data.get("current_day", 1)
	money = data.get("money", 900)
	keys = data.get("keys", 60)
	player_name = data.get("player_name", "")
	matching_tutorial_completed = data.get("matching_tutorial_completed", false)
	character_progress = data.get("character_progress", character_progress)
	character_stage = data.get("character_stage", character_stage)
	kitchen_tutorial_completed = data.get("kitchen_tutorial_completed", false)
	shown_food_intros = data.get("shown_food_intros", {})
	purchased_upgrades = data.get("purchased_upgrades", {})
	
	# --- Load Quiz Data ---
	quiz_question_progress = data.get("quiz_question_progress", {})
	quiz_concept_progress = data.get("quiz_concept_progress", {})

	print("Game Loaded.")
