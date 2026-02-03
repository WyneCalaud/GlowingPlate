extends Node

# --- FOOD DATABASE ---
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

# --- WEEKLY MENU SCHEDULE ---
# Day 1 has been updated to include arrays of all items to make them appear in prep scenes
const MENU_SCHEDULE: Dictionary = {
	1: {
		"Go": ["RICE", "PANDESAL", "EGG", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "TOFU"],
		"GlowVeg": ["SITAW", "CARROTS", "EGGPLANT", "PUMPKIN"],
		"GlowFru": ["WATERMELON", "MANGO", "BANANA", "PAPAYA"],
		"Beverage": ["REGULAR_MILK", "ALMOND_MILK", "WATER"]
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
		"GlowVeg": "MIXED_VEGGIES",
		"GlowFru": "WATERMELON",
		"Beverage": "ALMOND_MILK"
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
		"GlowVeg": "MIXED_VEGGIES", 
		"GlowFru": "MANGO",
		"Beverage": "REGULAR_MILK"
	}
}

var current_customer_order: Dictionary = {
	"age_group": "6-9",
	"required_plate": {}, 
	"required_beverage": [] 
}

var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}

func clear_prepared_data():
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()

func add_prepared_beverage(beverage_res: Resource) -> void:
	if beverage_res == null: return
	var key = beverage_res.get("internal_key")
	if not key:
		key = beverage_res.resource_name.to_upper()
	prepared_beverage_data[key] = { "item": beverage_res }

func generate_order_for_day(day: int) -> Dictionary:
	var menu_key = day if MENU_SCHEDULE.has(day) else 1
	var daily_menu = MENU_SCHEDULE[menu_key]
	
	# Logic to pick specific targets if the menu contains arrays (like our new Day 1)
	# This ensures the UI/Prep scenes see all items, but the "Correct" check has a specific target
	current_customer_order.required_plate = {
		"Go": daily_menu["Go"][0] if daily_menu["Go"] is Array else daily_menu["Go"],
		"Grow": daily_menu["Grow"][0] if daily_menu["Grow"] is Array else daily_menu["Grow"],
		"GlowVeg": daily_menu["GlowVeg"][0] if daily_menu["GlowVeg"] is Array else daily_menu["GlowVeg"],
		"GlowFru": daily_menu["GlowFru"][0] if daily_menu["GlowFru"] is Array else daily_menu["GlowFru"]
	}
	
	var bev_list = daily_menu.get("Beverage", "WATER")
	current_customer_order.required_beverage = [bev_list[0] if bev_list is Array else bev_list]
	
	return daily_menu

func is_plate_correct() -> bool:
	var plated_map := {}
	for entry in prepared_plate_contents:
		var slot_type = entry.get("accepted_type", "").strip_edges()
		if slot_type != "":
			plated_map[slot_type] = entry["item"].internal_key

	for category in current_customer_order.required_plate.keys():
		var required = current_customer_order.required_plate[category]
		var actual = plated_map.get(category, "")
		if actual != required:
			return false
	return true

func is_beverage_correct() -> bool:
	for bev_key in current_customer_order.required_beverage:
		if not prepared_beverage_data.has(bev_key):
			return false
	return true
