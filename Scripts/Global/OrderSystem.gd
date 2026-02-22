extends Node

# ---------------------------------------------------------
# FOOD DATABASE
# ---------------------------------------------------------

const FOOD_DB: Dictionary = {
	"RICE": preload("res://Data/Food/Go/Rice.tres"),
	"PANDESAL": preload("res://Data/Food/Go/Pandesal.tres"),
	"EGG": preload("res://Data/Food/Go/Eggs.tres"),
	"CORN": preload("res://Data/Food/Go/Corn.tres"),
	
	"CHICKEN_LEG": preload("res://Data/Food/Grow/Chicken.tres"),
	"FISH_FILLET": preload("res://Data/Food/Grow/FishFillet.tres"),
	"TOFU": preload("res://Data/Food/Grow/Tofu.tres"),
	
	"SITAW": preload("res://Data/Food/GlowVeg/Sitaw.tres"),
	"CARROTS": preload("res://Data/Food/GlowVeg/Carrots.tres"),
	"EGGPLANT": preload("res://Data/Food/GlowVeg/Eggplant.tres"),
	"PUMPKIN": preload("res://Data/Food/GlowVeg/Pumpkin.tres"),
	
	"PAPAYA": preload("res://Data/Food/GlowFru/Papaya.tres"),
	"WATERMELON": preload("res://Data/Food/GlowFru/Watermelon.tres"),
	"MANGO": preload("res://Data/Food/GlowFru/Mango.tres"),
	"BANANA": preload("res://Data/Food/GlowFru/Banana.tres"),
	
	"REGULAR_MILK": preload("res://Data/Drink/RegularMilk.tres"),
	"WATER": preload("res://Data/Drink/Water.tres")
}

# ---------------------------------------------------------
# WEEKLY MENU
# ---------------------------------------------------------

const MENU_SCHEDULE: Dictionary = {
	1: {
		"Go": ["PANDESAL", "EGG", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "TOFU"],
		"GlowVeg": ["SITAW", "CARROTS", "EGGPLANT", "PUMPKIN"],
		"GlowFru": ["WATERMELON", "MANGO", "BANANA", "PAPAYA"],
		"Beverage": ["REGULAR_MILK", "WATER"]
	},
	2: {
		"Go": "RICE",
		"Grow": "FISH_FILLET",
		"GlowVeg": "SITAW",
		"GlowFru": "MANGO",
		"Beverage": "WATER"
	},
	3: {
		"Go": "RICE",
		"Grow": "CHICKEN_LEG",
		"GlowVeg": "SITAW",
		"GlowFru": "WATERMELON",
		"Beverage": "REGULAR_MILK"
	},
	4: {
		"Go": "PANDESAL",
		"Grow": "CHICKEN_LEG",
		"GlowVeg": "SITAW",
		"GlowFru": "BANANA",
		"Beverage": "WATER"
	},
	5: {
		"Go": "RICE",
		"Grow": "FISH_FILLET",
		"GlowVeg": "SITAW", 
		"GlowFru": "MANGO",
		"Beverage": "REGULAR_MILK"
	}
}

# ---------------------------------------------------------
# SERVICE STATE
# ---------------------------------------------------------

var current_customer_order: Dictionary = {
	"age_group": "6-9",
	"required_plate": {},
	"required_beverage": []
}

func set_order_from_customer(customer_order: CustomerOrder) -> void:

	# plate
	current_customer_order.required_plate = customer_order.needs.duplicate()

	# beverage
	current_customer_order.required_beverage = customer_order.beverage_needs.duplicate()



var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}


# ---------------------------------------------------------
# CLEAR
# ---------------------------------------------------------

func clear_prepared_data() -> void:
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()


# ---------------------------------------------------------
# SAFE BEVERAGE STORAGE (FIXED)
# ---------------------------------------------------------

func add_prepared_beverage(beverage_res: Resource) -> void:
	if beverage_res == null:
		return

	# Get internal_key safely and enforce uppercase consistency
	var key: String = str(beverage_res.get("internal_key")).strip_edges().to_upper()

	# Fallback protection (should not trigger if resource is correct)
	if key == "":
		key = str(beverage_res.resource_name).strip_edges().to_upper()

	# Absolute fallback (guarantees uniqueness)
	if key == "":
		key = str(beverage_res.get_instance_id())

	# Store entry
	prepared_beverage_data[key] = {
		"item": beverage_res
	}

	# Debug (optional, remove later)
	# print("Beverage stored under key:", key)


# ---------------------------------------------------------
# ORDER GENERATION
# ---------------------------------------------------------

func generate_order_for_day(day: int) -> Dictionary:
	var menu_key: int = day if MENU_SCHEDULE.has(day) else 1
	var daily_menu: Dictionary = MENU_SCHEDULE[menu_key]

	current_customer_order.required_plate = {
		"Go": daily_menu["Go"][0] if daily_menu["Go"] is Array else daily_menu["Go"],
		"Grow": daily_menu["Grow"][0] if daily_menu["Grow"] is Array else daily_menu["Grow"],
		"GlowVeg": daily_menu["GlowVeg"][0] if daily_menu["GlowVeg"] is Array else daily_menu["GlowVeg"],
		"GlowFru": daily_menu["GlowFru"][0] if daily_menu["GlowFru"] is Array else daily_menu["GlowFru"]
	}

	var bev_list = daily_menu.get("Beverage", "WATER")
	current_customer_order.required_beverage = [
		bev_list[0] if bev_list is Array else bev_list
	]

	return daily_menu


# ---------------------------------------------------------
# VALIDATION
# ---------------------------------------------------------

func is_plate_correct() -> bool:
	var plated_map: Dictionary = {}

	for entry in prepared_plate_contents:
		var slot_type: String = str(entry.get("accepted_type", "")).strip_edges()
		if slot_type != "":
			plated_map[slot_type] = entry["item"].internal_key

	for category in current_customer_order.required_plate.keys():
		var required: String = current_customer_order.required_plate[category]
		var actual: String = plated_map.get(category, "")
		if actual != required:
			return false

	return true


func is_beverage_correct() -> bool:
	for bev_key in current_customer_order.required_beverage:
		var normalized_key: String = str(bev_key).strip_edges().to_upper()
		if not prepared_beverage_data.has(normalized_key):
			return false

	return true
