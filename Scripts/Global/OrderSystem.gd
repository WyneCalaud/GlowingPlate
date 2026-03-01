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
	"HOT_WATER": preload("res://Data/Drink/HotWater.tres"),
	"COLD_WATER": preload("res://Data/Drink/ColdWater.tres")
}

# ---------------------------------------------------------
# WEEKLY MENU
# ---------------------------------------------------------

const MENU_SCHEDULE: Dictionary = {
	1: {
		"Go": "BROWN_RICE",
		"Grow": "CHICKEN_LEG",
		"GlowVeg": "SITAW",
		"GlowFru": "MANGO",
		"Beverage": ["REGULAR_MILK", "WATER"]
	},
	2: {
		"Go": ["PANDESAL"],
		"Grow": "CHICKEN_LEG",
		"GlowVeg": "SITAW",
		"GlowFru": "MANGO",
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	3: {
		"Go": "PANDESAL",
		"Grow": ["CHICKEN_LEG", "FISH_FILLET"],
		"GlowVeg": "SITAW",
		"GlowFru": "MANGO",
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	4: {
		"Go": ["PANDESAL"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET"],
		"GlowVeg": ["SITAW", "PUMPKIN"],
		"GlowFru": "MANGO",
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	5: {
		"Go": ["PANDESAL"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET"],
		"GlowVeg": ["SITAW", "PUMPKIN"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	6: {
		"Go": ["PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET"],
		"GlowVeg": ["SITAW", "PUMPKIN"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	7: {
		"Go": ["PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG"],
		"GlowVeg": ["SITAW", "PUMPKIN"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	8: {
		"Go": ["PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	9: {
		"Go": ["BROWN_RICE",  "PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	10: {
		"Go": ["BROWN_RICE", "PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	11: {
		"Go": ["BROWN_RICE", "PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS", "EGGPLANT"],
		"GlowFru": ["MANGO", "WATERMELON"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	12: {
		"Go": ["BROWN_RICE", "PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS", "EGGPLANT"],
		"GlowFru": ["MANGO", "WATERMELON", "BANANA"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	13: {
		"Go": ["BROWN_RICE", "PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS", "EGGPLANT"],
		"GlowFru": ["MANGO", "WATERMELON", "BANANA", "PAPAYA"],
		"Beverage": ["WATER", "REGULAR_MILK"]
	},
	14: {
		"Go": ["BROWN_RICE", "PANDESAL", "CORN"],
		"Grow": ["CHICKEN_LEG", "FISH_FILLET", "EGG", "TOFU"],
		"GlowVeg": ["SITAW", "PUMPKIN", "CARROTS", "EGGPLANT"],
		"GlowFru": ["MANGO", "WATERMELON", "BANANA", "PAPAYA"],
		"Beverage": ["WATER", "REGULAR_MILK"]
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

	# ✅ FOOD INTRO / NON-CUSTOMER SAFETY
	if customer_order == null:
		current_customer_order.age_group = ""
		current_customer_order.required_plate.clear()
		current_customer_order.required_beverage.clear()
		current_customer_order["required_portions"] = {}

		return

	var age_group := customer_order.get_age_group()

	current_customer_order.age_group = age_group

	# Copy plate base keys
	current_customer_order.required_plate = customer_order.needs.duplicate()

	# Beverage
	current_customer_order.required_beverage = customer_order.beverage_needs.duplicate()

	# Portion rules
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

	var liquid_type := ""

	if "internal_key" in beverage_res:
		liquid_type = str(beverage_res.internal_key).to_upper()

	if liquid_type == "":
		push_warning("Beverage has no internal_key!")
		return

	print("Storing beverage | LiquidType:", liquid_type)

	prepared_beverage_data[liquid_type] = {
		"item": beverage_res,
		"liquid_type": liquid_type
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
	print("Required Plate:", current_customer_order.required_plate)
	print("Required Portions:", current_customer_order.required_portions)

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
			# If single option
			if required_key is String:
				if actual.key != required_key:
					print("❌ Wrong food for", category,
						"| Expected:", required_key,
						"| Got:", actual.key)
					return false
		# If multiple options
			elif required_key is Array:
				if not required_key.has(actual.key):
					print("❌ Wrong food for", category,
						"| Expected one of:", required_key,
						"| Got:", actual.key)
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

	print("----- VALIDATING BEVERAGE -----")

	var required_list : Array = current_customer_order.required_beverage
	var prepared_list := prepared_beverage_data.keys()

	# 1️⃣ First: Check counts match exactly
	if prepared_list.size() != required_list.size():
		print("❌ Extra or missing beverages.")
		return false

	for required in required_list:

		var required_upper = str(required).to_upper()
		var found := false

		for entry in prepared_beverage_data.values():

			var actual_type = str(entry.get("liquid_type", "")).to_upper()

			print("Checking Beverage | Required:", required_upper,
				"| Got:", actual_type)

			# --- ANY WATER SUPPORT ---
			if required_upper == "WATER":
				if actual_type == "HOT_WATER" or actual_type == "COLD_WATER":
					found = true
					break
			else:
				if actual_type == required_upper:
					found = true
					break

		if not found:
			print("❌ Missing or wrong beverage:", required_upper)
			return false

	print("✅ Beverage is correct!")
	return true

# ---------------------------------------------------------
# NEW: GET UNLOCKED FOODS FOR ALMANAC
# ---------------------------------------------------------
func get_unlocked_foods(max_day: int) -> Array[String]:
	var unlocked: Array[String] = []
	
	# Loop from Day 1 up to the current completed day
	for day in range(1, max_day + 1):
		if MENU_SCHEDULE.has(day):
			var daily_menu = MENU_SCHEDULE[day]
			
			# Check all food categories (ignoring Beverage for the food almanac)
			var categories = ["Go", "Grow", "GlowVeg", "GlowFru"]
			for cat in categories:
				if daily_menu.has(cat):
					var items = daily_menu[cat]
					
					# Some days have Arrays of food (e.g. Day 9 has ["BROWN_RICE", "PANDESAL", "CORN"])
					if items is Array:
						for item in items:
							if not unlocked.has(item):
								unlocked.append(item)
					# Some days have Strings (e.g. Day 1 has "CHICKEN_LEG")
					elif items is String:
						if not unlocked.has(items):
							unlocked.append(items)
							
	return unlocked
