# GameData.gd
extends Node

var tutorial_completed: bool = false

# --- Tutorial & Intro Flags ---
var kitchen_tutorial_completed: bool = true
var matching_tutorial_completed: bool = false
var intro_completed: bool = false

# --- Player & Customer Context ---
var current_customer_age_group: String = ""
var player_name : String = ""
var music_volume: float = 1.0 
var sfx_volume: float = 1.0

# --- Core Progression Variables ---
var current_day: int = 1         
const TOTAL_DAYS: int = 14         
var money: int = 0         
var keys: int = 60  

# --- Save Logic ---
const SAVE_PATH := "user://save_data.json"
var shown_food_intros := {}

# --- QUIZ PROGRESSION (Persistence) ---
# Holds the SM-2 data (intervals, repetitions, ease factors)
var quiz_concept_progress: Dictionary = {}
# Holds the specific history of questions answered
var quiz_question_progress: Dictionary = {}

# --- GLOW BOARD PROGRESSION ---
var character_progress: Dictionary = {
	"Leo": 0.0,
	"Maya": 0.0,
	"Norma": 0.0
}

# --- CHARACTER VISUAL STAGES ---
# 1 = Base, 2 = Improved, 3 = Glowing
var character_stage: Dictionary = {
	"Leo": 1,
	"Maya": 1,
	"Norma": 1
}

var special_intro_shown := {}

# --- UPGRADABLE / EXTENSION STATS ---
var max_customers_today: int = 4  
var customer_patience_multiplier: float = 1.5 

var purchased_upgrades: Dictionary = {}
var unlocked_upgrades: Array = []

# --- SHOP REGISTRY ---
var shop_unlocked_registry: Dictionary = {}
var shop_equipped_registry: Dictionary = {}

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

# --- GLOBAL PATIENCE SYSTEM ---
var customer_patience := 100.0
var patience_running := false

# --- SCENE PATHS ---
const KITCHEN_SCENE_PATH = "res://Scenes/Gameplay/fullgameplay.tscn"
const BEVERAGE_SCENE_PATH = "res://Scenes/Gameplay/BeveragesStation.tscn"
const LOBBY_CANTEEN_PATH = "res://Scenes/Lobby Canteen/lobbycanteen.tscn"
const END_DAY_SCENE_PATH = "res://Scenes/Results/EndDayResults.tscn" 
const QUIZ_SCENE_PATH = "res://Scenes/Quiz/QuizScene.tscn"

enum GamePhase {
	LOBBY,
	MATCHING,
	NEWS,
	QUIZ,
	END_DAY
}

var current_phase: GamePhase = GamePhase.LOBBY

var returning_from_kitchen := false

var saved_quiz_sets: Dictionary = {}

# ==========================================================
# INITIALIZATION
# ==========================================================

func _ready():
	add_to_group("GameData")
	load_game()
	_apply_saved_upgrades()

func _apply_saved_upgrades():
	if purchased_upgrades.has("PatientCustomers") or unlocked_upgrades.has("PatientCustomers"):
		customer_patience_multiplier = 1.5

# ==========================================================
# ECONOMY & REWARDS
# ==========================================================

func add_money(amount: int) -> void:
	money += amount
	# Notify any UI elements (like HUD labels) to refresh
	get_tree().call_group("HUD", "update_all_labels")
	print("Economy Update: Money is now ", money)

func calculate_tip(happiness_percent: float) -> int:
	if happiness_percent >= 90.0: return 25
	elif happiness_percent >= 70.0: return 15
	elif happiness_percent >= 40.0: return 8
	elif happiness_percent >= 20.0: return 4
	else: return 1

# ==========================================================
# TIME & VISUAL STAGING
# ==========================================================

func get_current_time_string() -> String:
	var safe_max = max(1, max_customers_today)
	var progress = float(total_customers_served_today) / float(safe_max)
	var hour = 12 + int(progress * 4) 
	if hour > 12: hour -= 12
	return str(hour) + ":00 PM"

func get_sun_stage_index() -> int:
	var safe_max = max(1, max_customers_today)
	var progress = float(total_customers_served_today) / float(safe_max)
	return clampi(int(progress * 4), 0, 3)

# ==========================================================
# CORE GAMEPLAY FLOW
# ==========================================================

func start_new_day():
	daily_money_earned = 0
	daily_keys_earned = 0
	total_customers_served_today = 0
	# Increase difficulty based on day
	max_customers_today = clampi(4 + (current_day - 1), 4, 10) 
	
	if current_day <= TOTAL_DAYS:
		get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)
	else:
		print("End of game content reached.")

func start_day_with_orders(orders: Array):
	remaining_customers = orders.duplicate()
	max_customers_today = max(1, remaining_customers.size()) 
	service_state = ServiceState.IDLE
	returning_from_kitchen = false
	day_started = true

func finalize_service(day_result: Dictionary) -> void:

	total_customers_served_today += 1
	customer_history.append(day_result)
	
	var base_earned = day_result.get("earned_money", 0)
	var happiness = day_result.get("happiness", 100.0)
	var performance_multiplier := 1.0

	if happiness >= 75: performance_multiplier = 1.0
	elif happiness >= 50: performance_multiplier = 0.8
	elif happiness >= 25: performance_multiplier = 0.6
	else: performance_multiplier = 0.4

	var adjusted_base = int(base_earned * performance_multiplier)
	var tip = calculate_tip(happiness)
	var total_earned = adjusted_base + tip
	
	money += total_earned
	daily_money_earned += total_earned
	
	# --- Key Rewards ---
	var keys_won = day_result.get("earned_keys", 0)
	
	# ⭐ FIX: Safe string checking and strip_edges to ensure spacing doesn't cause a failure
	var special_char: String = str(day_result.get("character_id", "")).strip_edges()
	var is_correct: bool = day_result.get("is_correct", false)

	if is_correct and (special_char == "Leo" or special_char == "Maya" or special_char == "Norma"):
		keys_won += 10
		print("⭐ Special character served successfully! Awarding +10 keys.")

	keys += keys_won
	daily_keys_earned += keys_won
	
	# --- Glow Board Progress ---
	var char_id = day_result.get("character_id", "")
	if character_progress.has(char_id):
		var gain = day_result.get("prog_gain", 0.0)
		character_progress[char_id] = clamp(character_progress[char_id] + gain, 0.0, 100.0)
	
	OrderSystem.clear_prepared_data()
	get_tree().call_group("HUD", "update_all_labels")

	# ⭐ FIX: Immediately save the game state here so the keys are persistently recorded
	# Otherwise, if the player quits to menu before the day transitions, they lose their keys!
	save_game()

	# ======================================================
	# 🔥 LAST CUSTOMER DELAY FIX
	# ======================================================

	if remaining_customers.is_empty():

		# 🔥 CRITICAL FIX
		clear_customer()

		day_started = false

		# ⏳ Wait 3 seconds before ending day
		await get_tree().create_timer(3.0).timeout

		current_day += 1
		transition_to_end_day()

# ==========================================================
# SCENE TRANSITIONS
# ==========================================================

func transition_to_plate_prep(): get_tree().change_scene_to_file(KITCHEN_SCENE_PATH)
func transition_to_beverage_prep(): get_tree().change_scene_to_file(BEVERAGE_SCENE_PATH)
func transition_to_canteen_serve(): get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)

func transition_to_end_day():
	current_phase = GamePhase.END_DAY
	save_game()

	customer_patience = 100.0
	patience_running = false
	get_tree().call_group("HUD", "reset_patience")

	get_tree().change_scene_to_file(END_DAY_SCENE_PATH)

func start_next_day_flow():
	save_game()
	get_tree().change_scene_to_file(LOBBY_CANTEEN_PATH)

# ==========================================================
# CUSTOMER DATA CACHING
# ==========================================================

var saved_customer_order: Resource = null
var saved_customer_texture: Texture2D = null

func save_customer(order: Resource, tex: Texture2D):
	saved_customer_order = order
	saved_customer_texture = tex

	if order and order.has_method("get_age_group"):
		current_customer_age_group = order.get_age_group()

	get_tree().call_group("HUD", "update_age_group_display")

func clear_customer():
	saved_customer_order = null
	saved_customer_texture = null
	current_customer_age_group = ""
	get_tree().call_group("HUD", "update_age_group_display")

# ==========================================================
# PERSISTENCE (SAVE/LOAD)
# ==========================================================

func save_game():
	# Sync the latest quiz data from the Autoload/Singleton nodes before writing
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
		"unlocked_upgrades": unlocked_upgrades,
		"shop_unlocked_registry": shop_unlocked_registry,
		"shop_equipped_registry": shop_equipped_registry,
		"shown_food_intros": shown_food_intros,
		"quiz_question_progress": quiz_question_progress,
		"quiz_concept_progress": quiz_concept_progress,
		"current_phase": current_phase,
		"special_intro_shown": special_intro_shown,
		"intro_completed": intro_completed,
		"saved_quiz_sets": saved_quiz_sets
	}

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("Persistence: Game Saved.")
	else:
		print("Persistence Error: Save Failed.")

func load_game():
	if not FileAccess.file_exists(SAVE_PATH):
		print("Persistence: No save file found.")
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file: return

	var content = file.get_as_text()
	file.close()

	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		print("Persistence Error: Corrupted save file.")
		return

	# Progression
	current_day = data.get("current_day", 1)
	money = data.get("money", 900)
	keys = data.get("keys", 60)
	player_name = data.get("player_name", "")
	
	# Tutorials & Flags
	matching_tutorial_completed = data.get("matching_tutorial_completed", false)
	kitchen_tutorial_completed = data.get("kitchen_tutorial_completed", false)
	intro_completed = data.get("intro_completed", false)
	
	# Characters & Upgrades
	character_progress = data.get("character_progress", character_progress)
	character_stage = data.get("character_stage", character_stage)
	purchased_upgrades = data.get("purchased_upgrades", {})
	unlocked_upgrades = data.get("unlocked_upgrades", []) 
	shop_unlocked_registry = data.get("shop_unlocked_registry", {})
	shop_equipped_registry = data.get("shop_equipped_registry", {})
	
	# Intros & Phases
	shown_food_intros = data.get("shown_food_intros", {})
	special_intro_shown = data.get("special_intro_shown", {})
	current_phase = data.get("current_phase", GamePhase.LOBBY)
	
	# --- Load Quiz Data (Critical for SM-2) ---
	quiz_question_progress = data.get("quiz_question_progress", {})
	quiz_concept_progress = data.get("quiz_concept_progress", {})
	saved_quiz_sets = data.get("saved_quiz_sets", {})

	print("Persistence: Game Loaded.")

func reset_day_state():
	day_started = false
	service_state = ServiceState.IDLE
	remaining_customers.clear()
	clear_customer()
	customer_patience = 100.0
	patience_running = false
	OrderSystem.clear_prepared_data()
	current_phase = GamePhase.LOBBY
	save_game()
	print("Service state reset complete.")

func get_character_stage(name: String) -> int:
	if character_stage.has(name):
		return character_stage[name]
	return 1

# --- WRAPPERS & TRANSITIONS ---
func store_plate_contents(contents: Array): OrderSystem.prepared_plate_contents = contents

func add_prepared_beverage(beverage_res: Resource):
	OrderSystem.add_prepared_beverage(beverage_res)

func store_beverage_data(data: Dictionary):
	OrderSystem.prepared_beverage_data = data
	returning_from_beverage = true
	transition_to_canteen_serve()
