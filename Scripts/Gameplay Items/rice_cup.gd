# rice_cup.gd
extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var full_cup_texture: Texture2D
@export var empty_cup_texture: Texture2D
@export var full_cup_scale_factor: float = 0.3

# --- OVERRIDE: Plate success logic ---
func on_plate_placement_success():
	# Unique Rice Logic: Set to empty texture and reset scale
	texture = empty_cup_texture
	scale = Vector2(0.5, 0.5)
	return_to_start()

# --- OVERRIDE: Unique drop zone check (Cooker) ---
func on_unique_drop_zone_check():
	# Unique Rice Logic: Check for RiceCooker
	if current_hovered_area.get_parent().name == "RiceCooker":
		texture = full_cup_texture
		scale = Vector2(full_cup_scale_factor, full_cup_scale_factor)
		# Note: plated_texture is already set via the Inspector or base class
		return_to_start()
	else:
		# Fallback to base behavior: return to start
		return_to_start()
