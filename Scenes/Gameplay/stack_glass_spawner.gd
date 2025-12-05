extends Sprite2D

# --- CONFIGURATION ---
const TRAVEL_TIME = 0.5 # Quick animation time
# Adjust this value (e.g., 0.8 to make the cup 20% smaller, 1.2 to make it 20% larger)
const GLASS_SIZE_MULTIPLIER = 2.5
# NEW: Vertical adjustment for the final position (negative value moves it UP)
const Y_OFFSET_ADJUSTMENT = -35 

# --- RESOURCES & PATHS ---
const EMPTY_GLASS_SCENE = preload("res://Assets/Beverages/EmptyGlass.tscn")

# --- CACHE NODE REFERENCES ---
@onready var mat1: Node2D = $"../../Mat/Mat1"
@onready var mat2: Node2D = $"../../Mat/Mat2" 
var beverage_station_root: Node = null
var is_spawning: bool = false 

# --- INITIALIZATION ---
func _ready():
	# Finds the true scene root for global movement
	var current_node = get_parent()
	while current_node and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node
	
	if not mat1 or not mat2:
		push_error("One or more Mat nodes not found! Check the @onready paths.")


# --- INPUT HANDLING ---
func _input(event: InputEvent) -> void:
	if is_spawning:
		return
	
	# Check for click/touch press
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or \
	   (event is InputEventScreenTouch and event.is_pressed()):
		
		var local_click_pos = to_local(get_global_mouse_position())
		var sprite_rect = get_rect()
		
		# Check if the click is within the visual bounds
		if sprite_rect.has_point(local_click_pos):
			get_viewport().set_input_as_handled()
			spawn_and_place_glass()


# --- GLASS SPAWN AND PLACEMENT LOGIC ---
func spawn_and_place_glass():
	if not EMPTY_GLASS_SCENE:
		return
	
	var target_mat: Node2D = null
	
	# Determine the target Mat
	if mat1 and mat1.get_child_count() == 0:
		target_mat = mat1
	elif mat2 and mat2.get_child_count() == 0:
		target_mat = mat2
	else:
		# DEBUG PRINT: Both mats are occupied
		print("DEBUG: Both Mat1 and Mat2 are currently occupied. Cannot place glass.")
		return
		
	# --- Start Spawn Process ---
	is_spawning = true 
		
	var empty_glass: Node2D = EMPTY_GLASS_SCENE.instantiate()
	empty_glass.name = "EmptyGlass"
	
	# 1. Apply manual size adjustment (scale)
	empty_glass.scale *= GLASS_SIZE_MULTIPLIER
	
	# 2. Temporarily add the glass to the scene root for global movement
	if beverage_station_root:
		beverage_station_root.add_child(empty_glass)
	else:
		add_child(empty_glass)
		
	empty_glass.global_position = self.global_position

	# 3. Calculate final position with manual offset
	var final_position = target_mat.global_position
	# We ADD the negative offset to the Y coordinate to shift it UP
	final_position.y += Y_OFFSET_ADJUSTMENT 

	# 4. Animate movement
	var tween = create_tween()
	# Use the calculated final_position for the destination
	tween.tween_property(empty_glass, "global_position", final_position, TRAVEL_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		
	await tween.finished
	
	# 5. Final Placement: Reparent the glass to the target Mat
	var current_global_pos = empty_glass.global_position
	var current_global_scale = empty_glass.global_scale 
	
	# Remove from the temporary parent
	var current_parent = empty_glass.get_parent()
	if current_parent:
		current_parent.remove_child(empty_glass)
	
	# Add to Target Mat
	target_mat.add_child(empty_glass)
	
	# Restore global properties (position and scale)
	empty_glass.global_position = current_global_pos
	empty_glass.global_scale = current_global_scale
	
	print("ACTION: Empty glass spawned and placed on %s." % target_mat.name)
	is_spawning = false
