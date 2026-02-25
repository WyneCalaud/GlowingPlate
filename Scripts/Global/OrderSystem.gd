extends Node

# ---------------------------------------------------------
# FOOD DATABASE
# ---------------------------------------------------------

const FOOD_DB: Dictionary = {
	"RICE": preload("res://Data/Food/Go/Rice.tres"),
	"PANDESAL": preload("res://Data/Food/Go/Pandesal.tres"),
	"EGG": preload("res://Data/Food/Go/Eggs.tres"),
	"CORN": preload("res://Data/Food/Go/Corn.tres"),
	"BROWN_RICE": preload("res://Data/Food/Go/BrownRice.tres"),
	
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
		"Go": ["PANDESAL", "EGG", "CORN", "BROWN_RICE"],
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

func _generate_portion_rules(customer_order: CustomerOrder) -> Dictionary:
	var rules := {}
	var age_group := customer_order.get_age_group()
	var plate := customer_order.needs

	for category in plate.keys():
		var key : String = plate[category]

		# 🔹 ADD THIS BLOCK RIGHT HERE
		if key == "ANY":
			match category:
				"Grow":
					rules[category] = "Whole" if age_group == "10-12" else "Half"
				"GlowVeg":
					rules[category] = "VeggieFull" if age_group == "10-12" else "VeggieHigh"
				"Go":
					rules[category] = "TooHigh" if age_group == "10-12" else "RightAmount"
				"GlowFru":
					rules[category] = "Single"
			continue
		# 🔹 END OF NEW BLOCK

		match key:

			# ---------------- GROW ----------------
			"CHICKEN_LEG", "FISH_FILLET":
				rules[category] = "Whole" if age_group == "10-12" else "Half"

			"EGG", "TOFU":
				rules[category] = "Whole" if age_group == "10-12" else "Half"

			# ---------------- GO ----------------
			"RICE":
				rules[category] = "TooHigh" if age_group == "10-12" else "RightAmount"

			"CORN":
				rules[category] = "VeggieFull" if age_group == "10-12" else "VeggieHigh"

			"PANDESAL":
				rules[category] = 4 if age_group == "10-12" else 3

			# ---------------- GLOW VEG ----------------
			"SITAW", "CARROTS", "EGGPLANT", "PUMPKIN":
				rules[category] = "VeggieFull" if age_group == "10-12" else "VeggieHigh"

			# ---------------- GLOW FRU ----------------
			"WATERMELON", "MANGO", "BANANA", "PAPAYA":
				rules[category] = "Single"

	return rules

func set_order_from_customer(customer_order: CustomerOrder) -> void:

	var age_group := customer_order.get_age_group()

	current_customer_order.age_group = age_group

	# Copy plate base keys
	current_customer_order.required_plate = customer_order.needs.duplicate()

	# Beverage
	current_customer_order.required_beverage = customer_order.beverage_needs.duplicate()

	# NEW: Attach required portion rules
	current_customer_order["required_portions"] = _generate_portion_rules(customer_order)



var prepared_plate_contents: Array = []
var prepared_beverage_data: Dictionary = {}


# ---------------------------------------------------------
# CLEAR
# ---------------------------------------------------------

func clear_prepared_data() -> void:
	prepared_plate_contents.clear()
	prepared_beverage_data.clear()


# ---------------------------------------------------------
# SAFE BEVERAGE STORAGE (FIXED FOR MULTIPLES)
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

	# Create a unique dictionary key so multiples of the same drink don't overwrite each other
	var unique_id = key + "_" + str(Time.get_ticks_msec()) + "_" + str(randi() % 1000)

	# Store entry
	prepared_beverage_data[unique_id] = {
		"item": beverage_res,
		"base_key": key
	}


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

	print("----- VALIDATING PLATE -----")

	var plated_map := {}

	for entry in prepared_plate_contents:

		var slot_type: String = str(entry.get("accepted_type", "")).strip_edges()
		if slot_type == "":
			continue

		var item: Resource = entry["item"]

		plated_map[slot_type] = {
			"key": item.internal_key,
			"portion": item.get_meta("Portion") if item.has_meta("Portion") else "",
			"rice": item.get_meta("RiceAmount") if item.has_meta("RiceAmount") else "",
			"quantity": entry.get("count", 1)
		}

		print("Plated ->", slot_type,
			"| Item:", item.internal_key,
			"| Portion:", plated_map[slot_type].portion,
			"| Rice:", plated_map[slot_type].rice,
			"| Qty:", plated_map[slot_type].quantity
		)

	for category in current_customer_order.required_plate.keys():

		var required_key = current_customer_order.required_plate[category]
		var required_portion = current_customer_order.required_portions.get(category, null)

		print("Required ->", category,
			"| Item:", required_key,
			"| Portion:", required_portion
		)

		if not plated_map.has(category):
			print("❌ Missing category:", category)
			return false

		var actual = plated_map[category]

		# 1️⃣ Check item
		if required_key != "ANY":
			if actual.key != required_key:
				print("❌ Wrong food for", category)
				return false
				
		else:
			#validate category onlly
			var food_res = FOOD_DB.get(actual.key)
			if food_res and food_res.food_category != category:
				print("❌ Item not valid for ANY", category)
				return false

		# 2️⃣ Portion validation
		match required_key:

			"CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU":
				if actual.portion != required_portion:
					print("❌ Wrong portion for", category,
						"| Expected:", required_portion,
						"| Got:", actual.portion)
					return false

			"RICE":
				if actual.rice != required_portion:
					print("❌ Wrong rice amount for", category,
						"| Expected:", required_portion,
						"| Got:", actual.rice)
					return false

			"CORN":
				if actual.portion != required_portion:
					print("❌ Wrong corn portion for", category,
						"| Expected:", required_portion,
						"| Got:", actual.portion)
					return false

			"SITAW", "CARROTS", "EGGPLANT", "PUMPKIN":
				if actual.portion != required_portion:
					print("❌ Wrong veggie amount for", category,
						"| Expected:", required_portion,
						"| Got:", actual.portion)
					return false

			"PANDESAL":
				if actual.quantity != required_portion:
					print("❌ Wrong pandesal quantity",
						"| Expected:", required_portion,
						"| Got:", actual.quantity)
					return false

	print("✅ Plate is correct!")
	return true

func entry_quantity_for(category: String) -> int:
	for entry in prepared_plate_contents:
		if entry.get("accepted_type") == category:
			return entry.get("quantity", 1)
	return 0


func is_beverage_correct() -> bool:
	var required_counts = {}
	var prepared_counts = {}

	# Count required beverages
	for bev_key in current_customer_order.required_beverage:
		var normalized_key: String = str(bev_key).strip_edges().to_upper()
		required_counts[normalized_key] = required_counts.get(normalized_key, 0) + 1

	# Count prepared beverages
	for entry in prepared_beverage_data.values():
		var item_key: String = entry.get("base_key", "")
		if item_key == "":
			item_key = str(entry.item.get("internal_key", "")).strip_edges().to_upper()
		prepared_counts[item_key] = prepared_counts.get(item_key, 0) + 1

	# Ensure everything required is prepared in the correct quantity
	for req_key in required_counts.keys():
		if prepared_counts.get(req_key, 0) < required_counts[req_key]:
			return false

	return true
