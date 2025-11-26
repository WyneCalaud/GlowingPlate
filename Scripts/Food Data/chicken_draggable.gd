# chicken_draggable.gd
extends "res://Scripts/Food Data/food_item_base.gd"

# --- CORE DROP LOGIC OVERRIDE ---
# This function is called when the item is released (drop).
func handle_drop():
	# 1. Check if we are hovering over an Area2D (a drop zone)
	if current_hovered_area != null:
		
		# 2. Check if the drop zone is a plate slot (it has the placement method)
		if current_hovered_area.has_method("try_place_food"):
			
			# Attempt placement on the plate slot
			var success = current_hovered_area.try_place_food(food_data)
			
			if success:
				# Placement success (calls queue_free() internally)
				on_plate_placement_success()
			else:
				# Placement failed (e.g., slot was full, calls queue_free() internally)
				on_drop_fail()
				
		else:
			# Dropped on an Area2D that is NOT a plate slot (e.g., Rice Cooker)
			# (Calls queue_free() internally)
			on_unique_drop_zone_check()
			
	else:
		# 3. Dropped on the background (current_hovered_area == null)
		# (Calls queue_free() internally)
		on_drop_fail()

# --- DESTRUCTION HANDLERS (Defined by you) ---

func on_plate_placement_success():
	# Success: Destroy this temporary node
	print("Chicken successfully placed.")
	queue_free()
	
# Called when dropped in empty space or placement failed
func on_drop_fail():
	# Failure: Destroy this temporary node
	print("Chicken placement failed (invalid drop/slot full). Item destroyed.")
	queue_free()
	
# Called when dropped somewhere else (not a plate slot)
func on_unique_drop_zone_check():
	# For a simple item like this, treat unique zones as failure (destroy)
	print("Chicken dropped on unique zone. Item destroyed.")
	queue_free()

# --- MANDATORY OVERRIDE ---
# The base class might call return_to_start() as a failure fallback.
# Ensure that if it is called, the item is destroyed instead of returning.
func return_to_start():
	queue_free()
