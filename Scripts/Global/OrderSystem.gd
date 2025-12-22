extends Node

# --- FOOD DATABASE ---
# Transferred from GameData.gd
const FOOD_DB: Dictionary = {
	# Food Items
	"RICE": preload("res://Data/Food/Rice.tres"),
	"CHICKEN_LEG": preload("res://Data/Food/Chicken.tres"),
	"MIXED_VEGGIES": preload("res://Data/Food/MixedVeggies.tres"),
	"WATERMELON": preload("res://Data/Food/Watermelon.tres"),
	
	# Beverage Items
	"REGULAR_MILK": preload("res://Data/Drink/RegularMilk.tres"),
	"ALMOND_MILK": preload("res://Data/Drink/AlmondMilk.tres"),
	"WATER": preload("res://Data/Drink/Water.tres")
}

# --- STATE VARIABLES ---
# Holds what the customer wants right now
var current_customer_order: Dictionary = {
	"age_group": "6-9",
	"required_plate": {}, 
	"required_beverage": [] 
}

# Holds what the player has actually prepared
var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}

# --- HELPER FUNCTIONS ---

func clear_prepared_data():
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()
	# We reset the required lists here to be safe
	current_customer_order.required_plate.clear()
	current_customer_order.required_beverage = ["WATER"]

func add_prepared_beverage(beverage_res: Resource) -> void:
	if beverage_res == null: return
	prepared_beverage_data[beverage_res.internal_key] = { "item": beverage_res }
	print("OrderSystem: Beverage added:", beverage_res.internal_key)

# --- LOGIC TRANSFER ---

func generate_order_for_day(day: int) -> Dictionary:
	print("OrderSystem: Generating order for Day %s" % day)
	var order_data = {}
	
	if day == 1:
		order_data = {
			"Go": "RICE",
			"Grow": "CHICKEN_LEG",
			"GlowVeg": "MIXED_VEGGIES",
			"GlowFru": "WATERMELON",
			"Beverage": "ALMOND_MILK"
		}
	
	# Parse into internal format
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
