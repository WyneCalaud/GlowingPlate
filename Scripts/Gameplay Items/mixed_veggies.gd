extends "res://Scripts/Food Data/food_item_base.gd"

# --- IMPORT GLOBAL REFERENCE (FIXED PATH) ---
const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

# --- CONFIGURATION ---
@export var selected_texture: Texture2D 
@export var selected_scale_factor: float = 0.4

# --- STATE ---
var is_selected: bool = false
var default_texture: Texture2D = null 
var default_scale: Vector2 

# --- INITIALIZATION ---
func _ready():
	# 1. Texture initialization
	if food_data and food_data.base_texture:
		default_texture = food_data.base_texture
	elif texture:
		default_texture = texture
	
	if default_texture:
		texture = default_texture
	
	default_scale = scale 
		
	# 2. Add node to a group
	add_to_group("food_dispenser")
	
	# 3. CRITICAL FIX: PROGRAMMATIC SIGNAL CONNECTION & INPUT SETUP
	var area_node: Area2D = get_node_or_null("Area2D")
		
	if area_node and area_node is Area2D:
		area_node.input_pickable = true 
		
		if not area_node.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
			area_node.connect("input_event", Callable(self, "_on_area_2d_input_event"))
			print("Mixed Veggies Dispenser: Input signal connected successfully.")
	else:
		print("ERROR: Mixed Veggies Dispenser could not find Area2D child for input.")


# --- INPUT LOGIC (Click-to-Select/Deselect) ---
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventScreenTouch and event.is_pressed()):
		
		get_viewport().set_input_as_handled()
		print("INPUT RECEIVED: Toggling selection.")
		toggle_selection()

# --- CORE MECHANIC: TOGGLE SELECTION ---
func toggle_selection():
	if is_selected:
		# DESELECT:
		is_selected = false
		texture = default_texture
		scale = default_scale 
		
		# FIX: Use global reference for deselect and assign to the STATIC variable
		if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER == self:
			# CORRECT: Assign to the static variable inside the loaded script
			FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = null 
			
		print("Dispenser deselected: %s" % food_data.item_name)
	else:
		# SELECT: Ensure all other dispensers are deselected first
		for dispenser in get_tree().get_nodes_in_group("food_dispenser"):
			if dispenser != self and dispenser.has_method("toggle_selection") and dispenser.is_selected:
				dispenser.toggle_selection()

		is_selected = true
		
		# FIX: Set global reference by assigning to the STATIC variable
		FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = self
		
		if selected_texture:
			texture = selected_texture
			scale = Vector2(selected_scale_factor, selected_scale_factor) 
		else:
			print("WARNING: Selected texture is NOT set in the Inspector. Using default texture and scale.")
			texture = default_texture 
			scale = default_scale 
		
		print("Dispenser selected: %s. Click a plate slot to place." % food_data.item_name)

# --- OVERRIDDEN VIRTUAL FUNCTIONS (Remove drag/drop functionality) ---
func handle_drop():
	pass

func return_to_start():
	pass

func on_plate_placement_success():
	pass

func on_unique_drop_zone_check():
	pass
