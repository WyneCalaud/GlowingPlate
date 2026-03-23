# stack_glass_spawner.gd
extends Sprite2D

# --- CONFIGURATION ---
const TRAVEL_TIME = 0.5 
const GLASS_SIZE_MULTIPLIER = 2.5
const FILLED_GLASS_SCALE = Vector2(2.8, 2.3)
const EMPTY_GLASS_SCALE = Vector2(2.5, 2.5)
const RETURN_SPEED = 0.3 # Time for the glass to return from trash

# --- RESOURCES & PATHS ---
const EMPTY_GLASS_SCENE = preload("res://Assets/Beverages/EmptyGlass.tscn")
const HOLD_BUTTON_SCENE = preload("res://Scenes/LiquidDispenser/FillMechanic.tscn")
const FILLED_GLASS_GENERIC_SCENE = preload("res://Assets/Beverages/FilledWaterGlass.tscn")

# --- WATER TEXTURES ---
const WATER_TEXTURE_LOW = preload("res://Assets/UI/Water/GlassLow.png")
const WATER_TEXTURE_MED = preload("res://Assets/UI/Water/GlassMed.png")
const WATER_TEXTURE_RIGHT = preload("res://Assets/UI/Water/GlassHigh.png")
const WATER_TEXTURE_HIGH = preload("res://Assets/UI/Water/GlassFull.png")

# --- CACHE NODE REFERENCES ---
@onready var mat1: Node2D = $"../../Mat/Mat1"
@onready var mat2: Node2D = $"../../Mat/Mat2" 
var beverage_station_root: Node = null
var is_spawning: bool = false 

# --- GLOBAL STATE ---
var selected_liquid: String = "" 
var current_dispenser_node: Node = null

# --- TUTORIAL SYSTEM ---
var is_tutorial_locked: bool = false

func _ready():
	var current_node = get_parent()
	while current_node and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node
	add_to_group("global_controller")

func set_liquid_selection(dispenser_node: Node, liquid_name: String):
	reset_liquid_selection_visuals()
	selected_liquid = liquid_name
	current_dispenser_node = dispenser_node
	if is_instance_valid(dispenser_node) and dispenser_node.has_method("set_visual_state"):
		dispenser_node.set_visual_state(true)
	print("STATE: Selected liquid is now: ", selected_liquid)

func reset_liquid_selection_visuals():
	# CRITICAL FIX: Capture the node locally first
	var dispenser_to_reset = current_dispenser_node
	
	# Clear the state variables BEFORE calling the dispenser.
	# This prevents the dispenser's deselect() function from calling THIS function back,
	# breaking the infinite recursion loop that freezes the computer.
	current_dispenser_node = null
	selected_liquid = ""
	
	if is_instance_valid(dispenser_to_reset) and dispenser_to_reset.has_method("set_visual_state"):
		dispenser_to_reset.set_visual_state(false)
		
	print("STATE: Liquid selection reset.")

# --- SWAP FILLED GLASS FOR EMPTY GLASS (TRASHING) ---
func replace_filled_with_empty(filled_glass: Node2D):
	if not is_instance_valid(filled_glass): 
		return
	
	var parent = filled_glass.get_parent()
	if not parent:
		filled_glass.queue_free()
		return
		
	# 1. Capture the current (trash drop) position and scale
	var global_pos_start = filled_glass.global_position
	var global_scale = EMPTY_GLASS_SCALE # Use the consistent empty glass scale
	
	# Determine the Mat's *target* position (This is where the glass should return)
	var return_pos_on_mat = filled_glass.get("start_position") # Read the original position stored during filling
	if return_pos_on_mat == null:
		# Fallback: Use the center of the mat if start_position wasn't captured correctly
		return_pos_on_mat = parent.global_position + Vector2(0, -50)
		print("WARNING: Using fallback return position.")
		
	parent.remove_child(filled_glass)
	
	# 2. Instantiate and set up the empty glass
	var empty_glass: Node2D = EMPTY_GLASS_SCENE.instantiate()
	empty_glass.name = "EmptyGlass"
	
	# 3. Add to the Mat
	parent.add_child(empty_glass)
	
	# 4. Set the empty glass at the trash drop point *first*
	empty_glass.global_position = global_pos_start
	
	# 5. Restore scale using the captured global values (FIX for sizing)
	empty_glass.global_scale = global_scale 
	
	# 6. Animate the return to the Mat's original position
	var tween = create_tween()
	tween.tween_property(empty_glass, "global_position", return_pos_on_mat, RETURN_SPEED)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 7. Destroy the filled glass node
	filled_glass.queue_free()
	
	print("ACTION: Filled glass trashed and replaced with new empty glass on Mat. Initiating return animation.")

# --- INTERACTION LOGIC ---
func replace_glass_with_filled(empty_glass: Node2D, fill_level: int, liquid_type_override: String = ""):
	
	print("DEBUG: replace_glass called. Level: %d, Override: %s" % [fill_level, liquid_type_override])

	var check_liquid = liquid_type_override if liquid_type_override != "" else selected_liquid
	var liquid_lower = check_liquid.to_lower()
	
	var valid_waters = ["water", "hot", "cold", "lukewarm"]
	var is_water = false
	for w in valid_waters:
		if liquid_lower.begins_with(w):
			is_water = true
			break
	
	if is_water:
		# 1. Handle "TooFast" (Level 0) immediately
		if fill_level == 0:
			print("ACTION: Held too short (TooFast). Glass remains empty.")
			empty_glass.visible = false 
			empty_glass.queue_free()
			return false

		# 2. Determine Texture based on Liquid Type
		var target_texture: Texture2D = null
		var amount_string: String = "Right"
		
		# Default to Water textures
		var low_texture = WATER_TEXTURE_LOW
		var med_texture = WATER_TEXTURE_MED
		var right_texture = WATER_TEXTURE_RIGHT
		var high_texture = WATER_TEXTURE_HIGH
		
		match fill_level:
			1: 
				target_texture = low_texture
				amount_string = "Low"
			2: 
				target_texture = med_texture
				amount_string = "Medium"
			3: 
				target_texture = right_texture
				amount_string = "Right"
			4: 
				target_texture = high_texture
				amount_string = "TooHigh"
			_: 
				print("ERROR: Invalid fill level: %d" % fill_level)
				return false
		
		# 3. CRITICAL FIX: Hide the empty glass and ALL its children immediately
		empty_glass.visible = false
		for child in empty_glass.get_children():
			if child is CanvasItem:
				child.visible = false
		
		# 4. Create Filled Glass
		var filled_glass: Node2D = FILLED_GLASS_GENERIC_SCENE.instantiate()
		var os = get_node("/root/OrderSystem")
		if liquid_lower.contains("hot"):
			filled_glass.water_data = os.FOOD_DB["HOT_WATER"]
		elif liquid_lower.contains("cold"):
			filled_glass.water_data = os.FOOD_DB["COLD_WATER"]
		# Apply the determined texture
		if filled_glass is Sprite2D:
			filled_glass.texture = target_texture
		else:
			var sprite_child = filled_glass.get_node_or_null("Sprite2D")
			if sprite_child: filled_glass.texture = target_texture

		if filled_glass.get("current_liquid_amount") != null:
			filled_glass.current_liquid_amount = amount_string
			filled_glass.set_meta("LiquidType", check_liquid)
		# 5. Swap in Scene Tree
		var parent = empty_glass.get_parent()
		if parent:
			var global_pos = empty_glass.global_position
			
			parent.remove_child(empty_glass)
			parent.add_child(filled_glass)
			
			filled_glass.global_position = global_pos
			filled_glass.scale = FILLED_GLASS_SCALE # Use the standardized scale
			
			# FIX: Overwrite the inherited start_position variable.
			if filled_glass.get("start_position") != null:
				filled_glass.set("start_position", global_pos) 
				print("DEBUG: Overwriting start_position to: ", global_pos)
			
			print("DEBUG: Swapped nodes on parent: %s" % parent.name)
		else:
			print("ERROR: Empty Glass has no parent! Cannot swap.")
			
		# 6. Delete Empty Glass
		empty_glass.queue_free()
		
		reset_liquid_selection_visuals()
		
		print("ACTION: Glass filled with %s. Amount: %s" % [check_liquid, amount_string])
		return true
	
	print("ACTION: Wrong liquid context for replacement.")
	return false

func _input(event: InputEvent) -> void:
	# --- TUTORIAL LOCK CHECK ---
	if is_tutorial_locked:
		return
		
	if is_spawning: return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		var local_click_pos = to_local(get_global_mouse_position())
		if get_rect().has_point(local_click_pos):
			get_viewport().set_input_as_handled()
			reset_liquid_selection_visuals()
			spawn_and_place_glass()
			
			# --- TUTORIAL NOTIFICATION & SAFETY LOCK ---
			var in_tutorial = get_tree().get_node_count_in_group("InteractiveTutorial") > 0
			if in_tutorial:
				get_tree().call_group("InteractiveTutorial", "action_completed", "Stack_Glass_Pressed")
				# Instantly lock self so player cannot double click during the tutorial transition
				is_tutorial_locked = true

func is_mat_available(mat: Node2D) -> bool:
	# Checks if it has no children AND isn't currently reserved by another mid-air item
	return mat != null and mat.get_child_count() == 0 and not mat.get_meta("reserved", false)

func spawn_and_place_glass():
	if not EMPTY_GLASS_SCENE: return
	var target_mat: Node2D = null
	
	# Check for an empty and unreserved mat
	if is_mat_available(mat1): target_mat = mat1
	elif is_mat_available(mat2): target_mat = mat2
	else: return
		
	is_spawning = true 
	
	# INSTANTLY reserve the mat so rapid clicks (or milk clicks) don't steal it
	target_mat.set_meta("reserved", true)
	
	var empty_glass: Node2D = EMPTY_GLASS_SCENE.instantiate()
	empty_glass.name = "EmptyGlass"
	
	# Initial spawn size matches original logic
	empty_glass.scale = Vector2(GLASS_SIZE_MULTIPLIER, GLASS_SIZE_MULTIPLIER)
	
	if beverage_station_root: beverage_station_root.add_child(empty_glass)
	else: add_child(empty_glass)
		
	empty_glass.global_position = self.global_position
	var final_position = target_mat.global_position + Vector2(0, -50)

	var tween = create_tween()
	tween.tween_property(empty_glass, "global_position", final_position, TRAVEL_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	var current_global_pos = empty_glass.global_position
	# Capture the achieved scale after the parent reparenting
	var current_global_scale = empty_glass.global_scale
	
	var current_parent = empty_glass.get_parent()
	if current_parent: current_parent.remove_child(empty_glass)
	
	target_mat.add_child(empty_glass)
	empty_glass.global_position = current_global_pos
	empty_glass.global_scale = current_global_scale
	
	# Clear the reservation now that the item is physically inside the mat
	target_mat.set_meta("reserved", false)
	is_spawning = false
