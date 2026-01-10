extends Node

# --- FOOD DATABASE ---
# Holds the links to all possible food items in the game.
const FOOD_DB: Dictionary = {
	# --- GO (Energy/Carbs) ---
	"RICE": preload("res://Data/Food/Go/Rice.tres"),
	
	# --- GROW (Body Building/Protein) ---
	"CHICKEN_LEG": preload("res://Data/Food/Grow/Chicken.tres"),
	"FISH_FILLET": preload("res://Data/Food/Grow/FishFillet.tres"), # NEW (Assumed path)
	
	# --- GLOW VEGETABLES (Body Regulating) ---
	"MIXED_VEGGIES": preload("res://Data/Food/GlowVeg/MixedVeggies.tres"),
	"SITAW": preload("res://Data/Food/GlowVeg/Sitaw.tres"),         # NEW (Assumed path)
	
	# --- GLOW FRUITS (Body Regulating) ---
	"WATERMELON": preload("res://Data/Food/GlowFru/Watermelon.tres"),
	"MANGO": preload("res://Data/Food/GlowFru/Mango.tres"),         # NEW (Assumed path)
	
	# --- BEVERAGES ---
	"REGULAR_MILK": preload("res://Data/Drink/RegularMilk.tres"),
	"ALMOND_MILK": preload("res://Data/Drink/AlmondMilk.tres"),
	"WATER": preload("res://Data/Drink/Water.tres")
}

# --- WEEKLY MENU SCHEDULE ---
# This dictionary defines exactly what is served on which day.
# Format: Day Number : { Category : Internal_Key_In_FOOD_DB }
const MENU_SCHEDULE: Dictionary = {
	# DAY 1: Chicken / Mixed Veg / Watermelon
	1: {
		"Go": "PANDESAL",
		"Grow": "EGG",
		"GlowVeg": "CABBAGE",
		"GlowFru": "BANANA",
		"Beverage": "REGULAR_MILK"
	},
	
	# DAY 2: Fish / Sitaw / Mango (NEW MENU - ADDED)
	2: {
		
	},
	
	3: {
		
	},
	
	4: {
		
	}
}

# --- STATE VARIABLES ---
var current_customer_order: Dictionary = {
	"age_group": "6-9",
	"required_plate": {}, 
	"required_beverage": [] 
}

var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}

# --- HELPER FUNCTIONS ---

func clear_prepared_data():
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()
	current_customer_order.required_plate.clear()
	current_customer_order.required_beverage = ["WATER"]

func add_prepared_beverage(beverage_res: Resource) -> void:
	if beverage_res == null: return
	prepared_beverage_data[beverage_res.internal_key] = { "item": beverage_res }
	print("OrderSystem: Beverage added:", beverage_res.internal_key)

# --- CORE LOGIC ---

func generate_order_for_day(day: int) -> Dictionary:
	print("OrderSystem: Generating order for Day %s" % day)
	
	# 1. Determine which menu to use
	# If we are on Day 8 but only have 7 days defined, this logic loops back to Day 1
	# Or strictly uses the day number if available.
	var menu_key = day
	
	if not MENU_SCHEDULE.has(menu_key):
		print("Warning: No menu defined for Day %d. Defaulting to Day 1." % day)
		menu_key = 1
		
	var daily_menu = MENU_SCHEDULE[menu_key]
	var order_data = {}
	
	# 2. Construct the order from the Schedule
	# We copy the keys exactly as defined in MENU_SCHEDULE
	order_data["Go"] = daily_menu["Go"]
	order_data["Grow"] = daily_menu["Grow"]
	order_data["GlowVeg"] = daily_menu["GlowVeg"]
	order_data["GlowFru"] = daily_menu["GlowFru"]
	
	# --- FIX: Handle Beverage Logic ---
	# If the menu specifies explicit "Beverage", use it.
	# If it has "Beverage1/2", pick one randomly for the customer to request.
	if daily_menu.has("Beverage"):
		order_data["Beverage"] = daily_menu["Beverage"]
	elif daily_menu.has("Beverage1") and daily_menu.has("Beverage2"):
		# Randomly pick one for this specific customer
		var options = [daily_menu["Beverage1"], daily_menu["Beverage2"]]
		order_data["Beverage"] = options.pick_random()
	else:
		order_data["Beverage"] = "WATER" # Fallback
	
	# 3. Parse into validation format (Internal Game Logic)
	current_customer_order.required_plate.clear()
	var bev = order_data.get("Beverage", "")
	current_customer_order.required_beverage = [] if bev == "" else [bev]
	
	for k in order_data.keys():
		if k != "Beverage":
			current_customer_order.required_plate[k] = order_data[k]
	
	return order_data

func is_plate_correct() -> bool:
	print("OrderSystem: Checking Plate...")
	var plated_map := {"Go": "", "Grow": "", "GlowVeg": "", "GlowFru": ""}

	# Map what is on the plate
	for entry in prepared_plate_contents:
		var res = entry["item"]
		var slot : String = entry["accepted_type"].strip_edges()
		plated_map[slot] = res.internal_key

	# Compare with requirements
	for key in current_customer_order.required_plate.keys():
		var required : String = current_customer_order.required_plate[key].strip_edges()
		var plated : String = plated_map.get(key, "").strip_edges()
		
		if plated != required:
			print("❌ MISMATCH: Required %s, Found %s" % [required, plated])
			return false

	print("✅ Plate correct!")
	return true

func is_beverage_correct() -> bool:
	var required_list: Array = current_customer_order.required_beverage
	if required_list.is_empty(): return true

	for bev_key in required_list:
		if not prepared_beverage_data.has(bev_key):
			print("❌ Missing beverage:", bev_key)
			return false

	print("✅ Beverages correct!")
	return true
