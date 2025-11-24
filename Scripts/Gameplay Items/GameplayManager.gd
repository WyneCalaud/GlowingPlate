# GameplayManager.gd
extends Node2D

# --- Node References ---
@onready var game_data = $"/root/GameData" # Accesses the global Autoload script
@onready var dialogue_box = $DialogueBox/DialogueBox # Assuming the customer's text box
@onready var customer_node = $Customer # Assuming the customer character node

# --- Plate Slot References ---
# Use the exact names of your Area2D slots inside the FoodPlate node
@onready var slot_go = $FoodPlate/SlotGo
@onready var slot_grow = $FoodPlate/SlotGrow
@onready var slot_glow_veg = $FoodPlate/SlotGlowVeg
@onready var slot_glow_fru = $FoodPlate/SlotGlowFru

# --- Game State ---
var current_required_order: Dictionary = {}
var is_order_served: bool = false # Prevents serving the plate multiple times

# --- Initialization ---
func _ready():
	# 1. Start the game flow by getting the current order
	start_customer_interaction()
	
	# 2. Connect signals from all four plate slots
	slot_go.plate_updated.connect(_on_plate_slot_updated)
	slot_grow.plate_updated.connect(_on_plate_slot_updated)
	slot_glow_veg.plate_updated.connect(_on_plate_slot_updated)
	slot_glow_fru.plate_updated.connect(_on_plate_slot_updated)


func start_customer_interaction():
	# 1. Get the order from the global GameData manager
	current_required_order = game_data.generate_order_for_day(game_data.current_day)
	
	# 2. Convert the order dictionary to a readable text string
	var order_text = generate_order_text(current_required_order)
	
	# 3. Display the order (Example: use your dialogue box)
	dialogue_box.set_text("I would like " + order_text + " please.")
	
	# 4. Optional: Animate customer entry here
	customer_node.show()


func generate_order_text(order: Dictionary) -> String:
	# Converts the order into a sentence: "rice, chicken, mixed vegetables and a watermelon"
	var items = []
	if order.has("Go"):
		items.append(order["Go"])
	if order.has("Grow"):
		items.append(order["Grow"])
	if order.has("GlowVeg"):
		items.append(order["GlowVeg"])
	if order.has("GlowFru"):
		items.append(order["GlowFru"])
	
	# Format the array into a comma-separated list
	if items.size() > 1:
		var last_item = items.pop_back()
		return items.join(", ") + " and a " + last_item
	elif items.size() == 1:
		return items[0]
	return "nothing" # Should not happen


# --- Plate Logic (Called by plate_slot.gd signal) ---
func _on_plate_slot_updated():
	# This is called whenever any slot is filled (or emptied, if you add that logic)
	check_plate_completion()

func check_plate_completion():
	if is_order_served:
		return
		
	# Check if ALL four slots are filled
	var all_slots_filled = slot_go.is_filled and slot_grow.is_filled and slot_glow_veg.is_filled and slot_glow_fru.is_filled
	
	if all_slots_filled:
		# If the plate is ready, check accuracy and serve
		serve_plate()


func serve_plate():
	is_order_served = true # Lock the serving process
	
	var accuracy_score = calculate_accuracy()
	var reaction_type = get_reaction_type(accuracy_score)
	
	# 1. Trigger the customer's reaction dialogue
	trigger_customer_reaction(reaction_type)
	
	# 2. Prepare the day results dictionary
	var money_gained = accuracy_score * 100 # Example: $100 per correct item
	var reputation_change = float(accuracy_score) / 4.0 - 0.5 # Range: -0.5 (0 correct) to +0.5 (4 correct)
	
	var day_result = {
		"accuracy": accuracy_score,
		"reaction": reaction_type,
		"earned_money": money_gained,
		"reputation_change": reputation_change
	}
	
	print(day_result) # Debug print
	
	# Wait for the customer dialogue to finish before advancing the day
	await get_tree().create_timer(3.0).timeout # Wait 3 seconds for reaction dialogue
	
	# 3. End the day through the global manager
	game_data.end_day(day_result)


# --- Scoring and Reaction ---
func calculate_accuracy() -> int:
	var correct_items = 0
	
	# Get the plate contents based on the item_placed_name variable from the slots
	var plate_contents = {
		"Go": slot_go.item_placed_name,
		"Grow": slot_grow.item_placed_name,
		"GlowVeg": slot_glow_veg.item_placed_name,
		"GlowFru": slot_glow_fru.item_placed_name
	}
	
	# Compare each slot's content to the required order
	if plate_contents["Go"] == current_required_order.get("Go"):
		correct_items += 1
	if plate_contents["Grow"] == current_required_order.get("Grow"):
		correct_items += 1
	if plate_contents["GlowVeg"] == current_required_order.get("GlowVeg"):
		correct_items += 1
	if plate_contents["GlowFru"] == current_required_order.get("GlowFru"):
		correct_items += 1
		
	return correct_items

func get_reaction_type(score: int) -> String:
	if score == 4:
		return "compliment"
	elif score >= 2:
		return "neutral"
	else:
		return "complaint"

func trigger_customer_reaction(reaction: String):
	# This function changes the customer's dialogue box text and/or facial expression
	var message = ""
	
	match reaction:
		"compliment":
			message = "This is a perfect plate! Exactly what I ordered, thank you!"
			# Optional: customer_node.play_animation("happy")
		"neutral":
			message = "It's close enough, I suppose. Some items were swapped."
			# Optional: customer_node.play_animation("confused")
		"complaint":
			message = "Ugh, this isn't what I asked for at all! Are you even listening?"
			# Optional: customer_node.play_animation("angry")
			
	dialogue_box.set_text(message)
