extends Area2D

# --- RESOURCES & PATHS ---
const EMPTY_GLASS_SCENE = preload("res://Assets/Beverages/EmptyGlass.tscn")
const TRAVEL_TIME = 0.3 

# --- CACHE NODE REFERENCES ---
# Assumes Mat1 and Mat2 are siblings of the 'Glasses' container's parent (BeveragesStation)
@onready var mat1: Node2D = $"../../../Mat/Mat1"
@onready var mat2: Node2D = $"../../../Mat/Mat2"

# Start finding the root node for parenting during movement
@onready var beverage_station_root: Node = get_parent()

# Flag to prevent rapid spawning while the glass is moving.
var is_spawning: bool = false

# --- INITIALIZATION ---
func _ready():
	# Find the true root node of the station (BeveragesStation)
	var current_node = get_parent()
	while current_node and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node
	
	if not mat1 or not mat2:
		push_error("Mat1 or Mat2 not found! Check the @onready paths.")
	
	# --- INPUT FIXES & DEBUG ---
	
	# 1. Ensure this Area2D is pickable
	self.input_pickable = true
	
	# 2. Set a high Z-Index to ensure no other element blocks the click
	# NOTE: Set the z_index of the Area2D itself, or the visual parent (StackGlass)
	get_parent().z_index = 10 
	
	# 3. Connect the signal from this Area2D to the handler function
	if not is_connected("input_event", Callable(self, "_on_stack_glass_input_event")):
		connect("input_event", Callable(self, "_on_stack_glass_input_event"))
		print("Glass Input Connected to self Area2D.")


# --- INPUT HANDLING ---
func _on_stack_glass_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# --- DEBUGGING: Print confirmation that the function is reached ---
	print("DEBUG: Input event received in Area2D: ", event.get_class())
	
	# Only react to the left mouse button press or touch press
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or \
	   (event is InputEventScreenTouch and event.is_pressed()):
		if not is_spawning:
			event.set_accepted()
			spawn_glass()

# --- GLASS SPAWN AND MOVEMENT LOGIC (Minor adjustment to start position) ---
func spawn_glass():
	# 1. Prevent multiple spawns during movement
	is_spawning = true
	
	# 2. Check for available slot (Mat1 first, then Mat2)
	var target_mat: Node2D = null
	
	if not is_slot_occupied(mat1):
		target_mat = mat1
	elif not is_slot_occupied(mat2):
		target_mat = mat2
	else:
		print("INFO: Both Mat1 and Mat2 are currently occupied. Cannot take a glass.")
		is_spawning = false
		return 
	
	# 3. Instantiate the glass
	if not EMPTY_GLASS_SCENE:
		push_error("FATAL: EMPTY_GLASS_SCENE not loaded. Check resource path.")
		is_spawning = false
		return
		
	var empty_glass: Sprite2D = EMPTY_GLASS_SCENE.instantiate()
	empty_glass.name = "EmptyGlass"
	
	# CRUCIAL: Get the StackGlass's actual global position (the Area2D's parent)
	empty_glass.global_position = get_parent().global_position
	
	# 4. Add glass to the scene root for correct global movement
	beverage_station_root.add_child(empty_glass)
	
	# 5. Animate movement using Tween
	var tween = create_tween()
	
	# Move the glass to the center of the target mat
	tween.tween_property(empty_glass, "global_position", target_mat.global_position, TRAVEL_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	# Wait for animation to finish
	await tween.finished
	
	# 6. Final Placement: Reparent the glass to the Mat slot
	var current_global_pos = empty_glass.global_position
	
	# Remove from current parent (BeverageStation root)
	empty_glass.get_parent().remove_child(empty_glass)
	
	# Add to the new parent (Mat1 or Mat2)
	target_mat.add_child(empty_glass)
	
	# Restore global position 
	empty_glass.global_position = current_global_pos
	
	is_spawning = false
	print("ACTION: Empty glass placed on ", target_mat.name)

# --- HELPER FUNCTIONS ---
func is_slot_occupied(mat_node: Node2D) -> bool:
	for child in mat_node.get_children():
		if child.name.begins_with("EmptyGlass"): 
			return true
	return false
