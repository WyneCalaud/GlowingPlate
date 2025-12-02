extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var empty_cup_texture: Texture2D
@export var small_scoop_texture: Texture2D
@export var medium_scoop_texture: Texture2D
@export var full_cup_texture: Texture2D
@export var too_high_texture: Texture2D
@export var full_cup_scale_factor: float = 0.3

# --- RICE SCOOP MECHANIC CONFIGURATION ---
const RICE_COOKER_NAME = "RiceCooker" # Name of the parent node of the drop zone
const TEXTURE_FLASH_DURATION: float = 0.3 # No longer used, but kept for reference

# --- CACHED RESOURCES ---
# Load the new mechanic script (Path confirmed from previous steps)
const RICE_SCOOP_MECHANIC_SCRIPT = preload("res://Scripts/Gameplay Items/rice_scoop_mechanic.gd")

# --- STATE ---
var is_empty: bool = true 
var current_rice_amount: String = "Empty" # Tracks the result of the scoop

# --- CACHED NODES ---
@onready var rice_cup_area: Area2D = $Area2D
var mechanic_instance: Node = null # The instance of the running mini-game logic

# --- SIGNALS ---
# Re-emitted from the mechanic instance
signal score_change(deduction: int)
signal rice_scoop_completed(rice_amount: String)


# --- INITIALIZATION ---
func _ready():
	# 1. Set initial state
	texture = empty_cup_texture 
	scale = Vector2(full_cup_scale_factor, full_cup_scale_factor)
	is_empty = true 
	current_rice_amount = "Empty"
	
	# 2. Call the base class's ready function to set up dragging.
	super._ready()
	
	# 3. Ensure Area2D is pickable.
	if is_instance_valid(rice_cup_area):
		rice_cup_area.input_pickable = true


# --- OVERRIDE: CORE DROP LOGIC (Handles drop on the Rice Cooker) ---
func handle_drop():
	
	var cooker_area_found = false
	if current_hovered_area and current_hovered_area.get_parent():
		# Check for the unique drop zone FIRST (The Rice Cooker)
		cooker_area_found = current_hovered_area.get_parent().name == RICE_COOKER_NAME
		print("DEBUG: Hovered Area Parent Name: %s | Cooker Found: %s" % [current_hovered_area.get_parent().name, cooker_area_found])
	else:
		print("DEBUG: Dropped area is null or has no parent.")


	if cooker_area_found:
		print("DEBUG: Dropped on recognized Rice Cooker area. Cup is_empty: %s" % is_empty)
		
		# If the cup is empty AND dropped on the cooker, start the scoop mini-game
		if is_empty:
			start_hold_mechanic()
			return # Stop processing drop logic
		else:
			# If the cup is full and dropped on the cooker, just return to start (no interaction)
			return_to_start()
			return # Stop processing drop logic

	# --- Logic for dropping elsewhere (Plates, Trash, etc.) ---
	
	# If we drop an empty cup anywhere other than the cooker, it must return home.
	if is_empty:
		print("Rice Cup is empty. Cannot place on a plate. Returning to start.")
		return_to_start()
		return
	
	# If current_hovered_area is null (dropped on background), return home.
	if current_hovered_area == null:
		return_to_start()
		return
	
	# If we reach here, the cup is FULL and dropped on another droppable Area2D.
	if current_hovered_area.has_method("try_place_food"):
		# CRITICAL FIX: Pass 'self' (the node instance) so the plate can read current_rice_amount
		var success = current_hovered_area.try_place_food(self)
		
		if success:
			print("Placed on plate: %s (Amount: %s)" % [food_data.item_name, current_rice_amount])
			on_plate_placement_success()	
		else:
			return_to_start()
	else:
		# Fallback for other non-cooker zones (Trash, Serve, etc.) - return home
		return_to_start()


# --- OVERRIDE: Plate success logic (Called when rice is successfully placed on a plate) ---
func on_plate_placement_success():
	# 1. VISUAL: Change the Rice Cup's texture to EMPTY and scale.
	texture = empty_cup_texture
	scale = Vector2(full_cup_scale_factor, full_cup_scale_factor) # Use the exported scale factor
	
	# 2. STATE: Mark the cup as empty.
	is_empty = true
	current_rice_amount = "Empty"
	
	# 3. LOCATION: Send the empty cup back to its start position.
	return_to_start()


# --- DELEGATED CORE MECHANIC: START ---

func start_hold_mechanic():
	# Check if the mechanic is already running
	if mechanic_instance != null and is_instance_valid(mechanic_instance):
		print("Mechanic already running.")
		return
		
	# 1. Instantiate the new mechanic node and add it to the scene tree
	mechanic_instance = RICE_SCOOP_MECHANIC_SCRIPT.new()
	# The mechanic itself will add the UI to the root for correct layering (Z-index)
	add_child(mechanic_instance)
	print("Mechanic instance created and added.")
	
	# 2. Connect the signals this cup needs to react to
	mechanic_instance.connect("score_change", Callable(self, "_on_mechanic_score_change"))
	mechanic_instance.connect("scoop_finished", Callable(self, "_on_mechanic_scoop_finished"))
	
	# 3. Start the process, passing required context (textures, locations)
	mechanic_instance.start_scoop_hold(self, RICE_COOKER_NAME, empty_cup_texture, full_cup_scale_factor)


# --- MECHANIC CALLBACKS (UPDATED) ---

func _on_mechanic_score_change(deduction: int):
	# Re-emit the score change signal globally
	emit_signal("score_change", deduction)

func _on_mechanic_scoop_finished(amount: String):
	# 1. Update the cup's final state based on the mechanic's result
	current_rice_amount = amount
	
	var final_texture: Texture2D = empty_cup_texture
	var is_scoop_successful: bool = true # Assume success unless proven "TooFast"
	
	# Use the NEW score names from rice_scoop_mechanic.gd
	match amount:
		"RightAmount":
			final_texture = full_cup_texture
		
		"Small":
			final_texture = small_scoop_texture
			
		"Medium":
			final_texture = medium_scoop_texture
			
		"TooHigh":
			final_texture = too_high_texture
		
		"TooFast":
			# --- FAILURE STATE ---
			final_texture = empty_cup_texture
			is_scoop_successful = false
			
		_:
			# Fallback: Remains empty
			final_texture = empty_cup_texture
			is_scoop_successful = false
	
	# 2. Apply the final persistent texture
	texture = final_texture
	
	# 3. Handle state and movement
	if is_scoop_successful:
		# Success or partial success: The cup now holds rice and is placable.
		is_empty = false
	else:
		# TooFast/Failure: Cup remains empty.
		is_empty = true

	# All results return to the start position immediately
	return_to_start()

	# 4. Emit completion signal ONLY if the scoop was successful (RightAmount)
	if amount == "RightAmount":
		emit_signal("rice_scoop_completed", amount)
	
	# 5. Clean up the mechanic node
	if mechanic_instance:
		mechanic_instance.queue_free()
		mechanic_instance = null
		print("Mechanic instance cleaned up.")

# --- FUNCTION FOR TEXTURE REVERSION (REMOVED: No longer needed as textures are persistent) ---
func _revert_to_empty_texture():
	# This function is now redundant as all valid scoops keep their texture
	pass
