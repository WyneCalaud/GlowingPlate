# chicken_leg_drag.gd
extends "res://Scripts/Food Data/food_item_base.gd" # Use your actual path!

# --- EXPORTS (Set these in the Inspector of ChickenLeg.tscn) ---
@export var single_leg_texture: Texture2D 
@export var single_leg_plated_texture: Texture2D 

func _ready() -> void:
	# Set the visual appearance and properties for the base class
	texture = single_leg_texture 
	texture = food_data.plated_texture
	if food_data.food_category == "Grow":
		super._ready() # Initialize start_position, z_index, and signal connections

# --- OVERRIDES (Define what happens when the leg is dropped) ---

# Called when successfully placed on the plate
func on_plate_placement_success():
	# Success: Destroy this temporary node
	queue_free()
	
# Called when dropped in empty space or placement failed
func on_drop_fail():
	# Failure: Destroy this temporary node
	queue_free()
	
# Called when dropped somewhere else (not a plate slot)
func on_unique_drop_zone_check():
	# For a simple item like this, treat unique zones as failure (destroy)
	queue_free()
