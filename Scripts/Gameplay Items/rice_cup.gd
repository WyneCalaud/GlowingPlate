extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var full_cup_texture: Texture2D
@export var empty_cup_texture: Texture2D
@export var full_cup_scale_factor: float = 0.3

# --- State Flag to enforce placement rule ---
var is_empty: bool = false 

# --- OVERRIDE: CORE DROP LOGIC (Blocks placement when empty) ---
# This function runs when the player releases the mouse button (after dragging).
func handle_drop():
	# CRITICAL CHECK: If the cup is empty, do NOT place the rice resource on the plate.
	if is_empty:
		# If the empty cup is dropped on the RiceCooker, allow refilling (handled below).
		if current_hovered_area and current_hovered_area.get_parent().name == "RiceCooker":
			on_unique_drop_zone_check()
			return

		# Otherwise, it's an invalid drop location for the empty cup.
		print("Rice Cup is empty. Cannot place rice on the plate or other zones.")
		return_to_start()
		return

	# If we reach here, the cup is FULL, so proceed with standard placement logic.
	
	if current_hovered_area == null:
		return_to_start()
		return
	
	if current_hovered_area.has_method("try_place_food"):
		
		# PASS THE RESOURCE (since the cup is full)
		var success = current_hovered_area.try_place_food(food_data)
		
		if success:
			print("Placed on plate: %s" % food_data.item_name)
			# Success logic runs, which flips 'is_empty' to true
			on_plate_placement_success()	
			
		else:
			return_to_start()
			
	else:
		on_unique_drop_zone_check()


# --- OVERRIDE: Plate success logic ---
func on_plate_placement_success():
	# 1. VISUAL: Change the Rice Cup's texture to EMPTY.
	texture = empty_cup_texture
	scale = Vector2(0.5, 0.5)
	
	# 2. STATE: Mark the cup as empty (This is what blocks future drops/drags from succeeding).
	is_empty = true
	
	# 3. LOCATION: Send the empty cup back to its start position.
	return_to_start()


# --- OVERRIDE: Unique drop zone check (Cooker) ---
func on_unique_drop_zone_check():
	# Unique Rice Logic: Check for the RiceCooker parent node
	if current_hovered_area and current_hovered_area.get_parent().name == "RiceCooker":
		
		# 1. VISUAL: Change the Rice Cup's texture back to FULL.
		texture = full_cup_texture
		scale = Vector2(full_cup_scale_factor, full_cup_scale_factor)
		
		# 2. STATE: Mark the cup as full.
		is_empty = false
		
		# 3. LOCATION: Send the full cup back to its start position.
		return_to_start()
		
	else:
		# Fallback to base behavior: return to start
		return_to_start()
