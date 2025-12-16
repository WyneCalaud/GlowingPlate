extends Area2D

# --- STATE ---
var is_ui_active: bool = false
var spawner_controller: Node = null
# FIX: Added state to remember which liquid initiated the hold
var active_liquid_type: String = "" 

func _ready():
	# 1. Find the Global Controller
	var controllers = get_tree().get_nodes_in_group("global_controller")
	if controllers.size() > 0:
		spawner_controller = controllers[0]
	
	# 2. Ensure Input is active
	set_pickable(true)

# --- INPUT HANDLING ---
func _input_event(_viewport, event, _shape_idx):
	# DEBUG: Check if the click is even registering
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		var current_liquid = "None"
		if spawner_controller:
			current_liquid = spawner_controller.selected_liquid
		print("DEBUG: EmptyGlass clicked! Current Liquid: %s" % current_liquid)

	if is_ui_active: return # Prevent double clicks while UI is open
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		get_viewport().set_input_as_handled()
		try_start_filling()

# --- LOGIC ---
func try_start_filling():
	if not spawner_controller: 
		print("ERROR: No Spawner Controller found!")
		return
	
	# FIX: Convert to lower case to handle liquid names consistently
	var sel = spawner_controller.selected_liquid.to_lower()
	print("DEBUG: Checking liquid match for: %s" % sel)
	
	# UPDATED FIX: Check for all water types, AND check if the selected liquid CONTAINS "milk" 
	# (or starts with specific milk prefixes) for broader compatibility.
	var is_water_type = sel.begins_with("water") or sel.begins_with("hot") or sel.begins_with("cold") or sel.begins_with("lukewarm")
	
	# CRITICAL FIX HERE: Check if the selection starts with 'milk', 'regular_milk', or 'almond_milk'
	var is_milk_type = sel.begins_with("milk") or sel.begins_with("regularmilk") or sel.begins_with("almondmilk")
	
	if is_water_type or is_milk_type:
		
		# FIX: Capture the specific liquid string (e.g. "Cold" or "Regular Milk") so we remember it
		active_liquid_type = spawner_controller.selected_liquid
		
		# 2. Get the Hold Button Scene from the Spawner
		var ui_scene = spawner_controller.HOLD_BUTTON_SCENE
		if ui_scene:
			spawn_hold_button(ui_scene)
		else:
			print("ERROR: HOLD_BUTTON_SCENE not found in Spawner.")
			
	elif spawner_controller.selected_liquid != "":
		# UPDATED ERROR MESSAGE to reflect correct naming conventions
		print("ACTION: Wrong liquid type (%s). Select a valid Water, Milk, or Almond Milk type." % spawner_controller.selected_liquid)
	else:
		print("ACTION: Select a liquid first.")

func spawn_hold_button(ui_scene: PackedScene):
	is_ui_active = true
	print("DEBUG: Spawning Hold Button UI")
	
	# 1. Instantiate the UI
	var hold_button = ui_scene.instantiate()
	
	# 2. Add it to the scene
	add_child(hold_button)
	
	# 3. CRITICAL VISIBILITY FIX: Make it Top Level
	if hold_button is CanvasItem:
		hold_button.top_level = true
	
	# 4. Position it: TIE TO MAT POSITION (PARENT)
	# Instead of using self.global_position, we use get_parent().global_position.
	var parent_node = get_parent()
	var target_pos = Vector2.ZERO
	
	if parent_node:
		target_pos = parent_node.global_position
		print("DEBUG: Anchoring UI to Parent Mat: %s at %s" % [parent_node.name, target_pos])
	else:
		# Fallback if for some reason it has no parent
		target_pos = global_position
	
	# Add an offset (e.g., -145 X, -50 Y) to float it ABOVE the mat/glass
	hold_button.global_position = target_pos + Vector2(-145, -50)
	
	# 5. Force Z-Index to Max
	hold_button.z_index = 4096 
	
	# 6. Connect the signal
	if hold_button.has_signal("fill_finished"):
		hold_button.connect("fill_finished", Callable(self, "_on_fill_finished"))
	else:
		print("ERROR: HoldButton scene is missing 'fill_finished' signal!")

	print("DEBUG: Button spawned at global pos: ", hold_button.global_position)

# --- CALLBACK ---
func _on_fill_finished(_amount_str: String, amount_int: int):
	is_ui_active = false

	# ✅ GET GAMEDATA FIRST (while still in tree)
	var gd := get_tree().get_first_node_in_group("GameData")
	if not gd:
		push_error("GameData not found!")
		return

	# 1. Replace the glass visually (this may free self)
	spawner_controller.replace_glass_with_filled(self, amount_int, active_liquid_type)

	# 2. Resolve beverage type
	var liquid := active_liquid_type.to_lower()
	var beverage_key := ""

	if liquid.begins_with("water") or liquid.begins_with("cold") or liquid.begins_with("hot") or liquid.begins_with("lukewarm"):
		beverage_key = "WATER"
	elif liquid.begins_with("regularmilk"):
		beverage_key = "REGULAR_MILK"
	elif liquid.begins_with("almondmilk"):
		beverage_key = "ALMOND_MILK"

	if beverage_key == "":
		push_warning("Unknown beverage type: " + active_liquid_type)
		return

	# 3. Fetch resource
	var base_res: CustomItemData = gd.FOOD_DB.get(beverage_key)
	if not base_res:
		push_warning("Beverage not found in FOOD_DB: " + beverage_key)
		return

	# CRITICAL FIX: duplicate the resource
	var beverage_res: CustomItemData = base_res.duplicate(true)

	# 4. Store amount (THIS IS CORRECT)
	beverage_res.set_meta("DrinkAmount", _amount_str)

	# 5. Store in GameData
	gd.add_prepared_beverage(beverage_res)
