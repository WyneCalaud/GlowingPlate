extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var empty_cup_texture: Texture2D
@export var small_scoop_texture: Texture2D
@export var medium_scoop_texture: Texture2D
@export var full_cup_texture: Texture2D
@export var too_high_texture: Texture2D
@export var empty_cup_texture_factor: float = 0.4
@export var full_cup_scale_factor: float = 0.25

# --- RICE SCOOP MECHANIC CONFIGURATION ---
const RICE_COOKER_NAME = "RiceCooker" 
const TEXTURE_FLASH_DURATION: float = 0.3 

# --- CACHED RESOURCES ---
const RICE_SCOOP_MECHANIC_SCRIPT = preload("res://Scripts/Gameplay Items/rice_scoop_mechanic.gd")

# --- STATE ---
var is_empty: bool = true 
var current_rice_amount: String = "Empty"

# --- CACHED NODES ---
@onready var rice_cup_area: Area2D = $Area2D
var mechanic_instance: Node = null 

# --- SIGNALS ---
signal score_change(deduction: int)
signal rice_scoop_completed(rice_amount: String)


# --- INITIALIZATION ---
func _ready():
	# 1. Set initial state (Empty)
	texture = empty_cup_texture 
	# Apply the EMPTY scale factor
	scale = Vector2(0.5, 0.5)
	is_empty = true 
	current_rice_amount = "Empty"
	
	super._ready()
	
	if is_instance_valid(rice_cup_area):
		rice_cup_area.input_pickable = true
		# FIX: Scale up the Area2D so it's larger than the visual sprite (easier to grab)
		# At 0.4 parent scale, 2.5x makes the hitbox ~1.0x (original texture size)
		rice_cup_area.scale = Vector2(1.0, 1.0)


# --- OVERRIDE: CORE DROP LOGIC ---
func handle_drop():
	var cooker_area_found = false
	if current_hovered_area and current_hovered_area.get_parent():
		cooker_area_found = current_hovered_area.get_parent().name == RICE_COOKER_NAME
		print("DEBUG: Hovered Area Parent Name: %s | Cooker Found: %s" % [current_hovered_area.get_parent().name, cooker_area_found])
	else:
		print("DEBUG: Dropped area is null or has no parent.")

	if cooker_area_found:
		print("DEBUG: Dropped on recognized Rice Cooker area. Cup is_empty: %s" % is_empty)
		if is_empty:
			start_hold_mechanic()
			return 
		else:
			return_to_start()
			return 

	# --- Logic for dropping elsewhere ---
	if is_empty:
		print("Rice Cup is empty. Cannot place on a plate. Returning to start.")
		return_to_start()
		return
	
	if current_hovered_area == null:
		return_to_start()
		return
	
	if current_hovered_area.has_method("try_place_food"):
		var success = current_hovered_area.try_place_food(self)
		if success:
			print("Placed on plate: %s (Amount: %s)" % [food_data.item_name, current_rice_amount])
			on_plate_placement_success()	
		else:
			return_to_start()
	else:
		return_to_start()


# --- OVERRIDE: Plate success logic ---
func on_plate_placement_success():
	# 1. VISUAL: Reset to EMPTY texture
	texture = empty_cup_texture
	# 2. SCALE: Reset to EMPTY scale factor
	scale = Vector2(empty_cup_texture_factor, empty_cup_texture_factor) 
	
	# FIX: Reset Area2D scale for empty state
	if is_instance_valid(rice_cup_area):
		rice_cup_area.scale = Vector2(2.5, 2.5)
	
	is_empty = true
	current_rice_amount = "Empty"
	
	return_to_start()


# --- DELEGATED CORE MECHANIC: START ---
func start_hold_mechanic():
	if mechanic_instance != null and is_instance_valid(mechanic_instance):
		print("Mechanic already running.")
		return
		
	mechanic_instance = RICE_SCOOP_MECHANIC_SCRIPT.new()
	add_child(mechanic_instance)
	print("Mechanic instance created and added.")
	
	mechanic_instance.connect("score_change", Callable(self, "_on_mechanic_score_change"))
	mechanic_instance.connect("scoop_finished", Callable(self, "_on_mechanic_scoop_finished"))
	
	mechanic_instance.start_scoop_hold(self, RICE_COOKER_NAME, empty_cup_texture, full_cup_scale_factor)


# --- MECHANIC CALLBACKS (UPDATED) ---

func _on_mechanic_score_change(deduction: int):
	emit_signal("score_change", deduction)

func _on_mechanic_scoop_finished(amount: String):
	# 1. Update the cup's final state based on the mechanic's result
	current_rice_amount = amount
	
	var final_texture: Texture2D = empty_cup_texture
	var is_scoop_successful: bool = true 
	
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
			final_texture = empty_cup_texture
			is_scoop_successful = false
		_:
			final_texture = empty_cup_texture
			is_scoop_successful = false
	
	# 2. Apply the final persistent texture
	texture = final_texture
	
	# 3. FIX: Apply the correct SCALE based on success
	if is_scoop_successful:
		is_empty = false
		# Change scale to the "Full" size (0.25)
		scale = Vector2(full_cup_scale_factor, full_cup_scale_factor)
		
		# FIX: When the cup shrinks to 0.25, we make the Area2D HUGE (4.0x) 
		# so the clickable area stays roughly the same size (0.25 * 4.0 = 1.0)
		if is_instance_valid(rice_cup_area):
			rice_cup_area.scale = Vector2(4.0, 4.0)
	else:
		is_empty = true
		# Revert scale to the "Empty" size (0.4)
		scale = Vector2(empty_cup_texture_factor, empty_cup_texture_factor)
		
		# FIX: Revert Area2D scale (0.4 * 2.5 = 1.0)
		if is_instance_valid(rice_cup_area):
			rice_cup_area.scale = Vector2(2.5, 2.5)

	# All results return to the start position immediately
	return_to_start()

	if amount == "RightAmount":
		emit_signal("rice_scoop_completed", amount)
	
	if mechanic_instance:
		mechanic_instance.queue_free()
		mechanic_instance = null
		print("Mechanic instance cleaned up.")

func _revert_to_empty_texture():
	pass
