extends Area2D

# --- STATE ---
var is_ui_active: bool = false
var spawner_controller: Node = null
var active_liquid_type: String = "" 

# --- CRITICAL TUTORIAL SYSTEM VARS ---
var is_tutorial_locked: bool = false

func _ready():
	# 1. Find the Global Controller
	var controllers = get_tree().get_nodes_in_group("global_controller")
	if controllers.size() > 0:
		spawner_controller = controllers[0]
	
	# 2. Ensure Input is active
	set_pickable(true)
	
	# 3. Add to interactable group for the tutorial manager
	add_to_group("interactable")

# --- BULLETPROOF INPUT HANDLING ---
func _input(event):
	# Ignore clicks if the tutorial is currently locked
	if is_tutorial_locked: return
	
	# Prevent double clicks while UI is open
	if is_ui_active: return 

	# Detect left mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		
		# 1. Ask the physics engine directly what is under the mouse pointer
		var space = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = get_global_mouse_position()
		query.collide_with_areas = true
		
		var results = space.intersect_point(query)
		
		# 2. Check if THIS EmptyGlass was one of the objects hit by the click
		for hit in results:
			if hit.collider == self:
				var current_liquid = "None"
				if spawner_controller:
					current_liquid = spawner_controller.selected_liquid
				print("DEBUG: EmptyGlass clicked via Physics Check! Current Liquid: %s" % current_liquid)

				get_viewport().set_input_as_handled()
				try_start_filling()
				return # Stop searching once we found our glass

# --- LOGIC ---
func try_start_filling():
	if not spawner_controller: 
		print("ERROR: No Spawner Controller found!")
		return
	
	# Convert to lower case to handle liquid names consistently
	var sel = spawner_controller.selected_liquid.to_lower()
	print("DEBUG: Checking liquid match for: %s" % sel)
	
	# Check for all water types, AND check if the selected liquid CONTAINS "milk" 
	var is_water_type = sel.begins_with("water") or sel.begins_with("hot") or sel.begins_with("cold") or sel.begins_with("lukewarm")
	var is_milk_type = sel.begins_with("milk") or sel.begins_with("regularmilk") or sel.begins_with("almondmilk")
	
	if is_water_type or is_milk_type:
		
		# Capture the specific liquid string so we remember it
		active_liquid_type = spawner_controller.selected_liquid
		
		# Get the Hold Button Scene from the Spawner
		var ui_scene = spawner_controller.HOLD_BUTTON_SCENE
		if ui_scene:
			spawn_hold_button(ui_scene)
			
			# --- TUTORIAL NOTIFICATION ---
			var in_tutorial = get_tree().get_node_count_in_group("InteractiveTutorial") > 0
			if in_tutorial:
				# Tell the tutorial we pressed the empty glass successfully
				get_tree().call_group("InteractiveTutorial", "action_completed", "EmptyGlass_Pressed")
				# Instantly lock self so the player cannot click again during the UI transition
				is_tutorial_locked = true
		else:
			print("ERROR: HOLD_BUTTON_SCENE not found in Spawner.")
			
	elif spawner_controller.selected_liquid != "":
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
	
	# 3. Make it Top Level
	if hold_button is CanvasItem:
		hold_button.top_level = true
	
	# 4. Position it: TIE TO MAT POSITION (PARENT)
	var parent_node = get_parent()
	var target_pos = Vector2.ZERO
	
	if parent_node:
		target_pos = parent_node.global_position
	else:
		target_pos = global_position
	
	# Add an offset to float it ABOVE the mat/glass
	hold_button.global_position = target_pos + Vector2(-145, -50)
	
	# 5. Force Z-Index to Max
	hold_button.z_index = 4096 
	
	# 6. Connect the signal
	if hold_button.has_signal("fill_finished"):
		hold_button.connect("fill_finished", Callable(self, "_on_fill_finished"))

# --- CALLBACK ---
func _on_fill_finished(_amount_str: String, amount_int: int):
	is_ui_active = false
	# Replace the glass visually (this frees self)
	spawner_controller.replace_glass_with_filled(self, amount_int, active_liquid_type)
