# chicken_leg_drag.gd
extends "res://Scripts/food_item_base.gd" 

# --- UNIQUE EXPORTS (for plate texture only) ---
# Raw texture and Cooked texture are handled by the container
@export var single_leg_texture: Texture2D # Texture of the single leg
@export var single_leg_plated_texture: Texture2D # Texture of the single leg when plated

# Override the base variables if you need to
func _ready() -> void:
	# Use the specific texture for the draggable leg
	texture = single_leg_texture 
	
	# Set the food type and plated texture required by food_item_base
	food_type = "Grow"
	plated_texture = single_leg_plated_texture
	
	# Run base setup (sets start_position, z_index, connects signals)
	super._ready()
	
	# We don't want the leg to return to its own start position (which is 0,0)
	# The parent container will handle cleanup. We'll disable return_to_start in the drop logic.

# --- OVERRIDE: Plate success logic ---
func on_plate_placement_success():
	# When placement succeeds, we destroy this temporary leg node.
	queue_free()
	
# --- OVERRIDE: Unique drop zone check ---
func on_unique_drop_zone_check():
	# If dropped elsewhere (not on plate or cooker), also destroy it.
	# The container remains unchanged.
	queue_free()

# --- REVISE: handle_drop to prevent tweening ---
# We must override the base handle_drop to prevent return_to_start() from running,
# since this item should be destroyed, not tweened.
func handle_drop():
	if current_hovered_area == null:
		queue_free() # Drop in open space, destroy
		return
	
	# Try to place food on a plate slot
	if current_hovered_area.has_method("try_place_food"):
		
		var texture_to_send = plated_texture
		if texture_to_send == null:
			texture_to_send = texture
			
		var success = current_hovered_area.try_place_food(food_type, texture_to_send)
		
		if success:
			on_plate_placement_success() # Calls queue_free()
		else:
			queue_free() # Failed to place, destroy
			
	# Check for other unique drop zones
	else:
		on_unique_drop_zone_check() # Calls queue_free()
