extends Area2D

@export var accepted_food_type: String = "Go"
@export var linked_image: Sprite2D # The empty sprite for this section
@export var plated_scale_factor: float = 0.4 # <<< NEW: Set the scale for the image on the plate

var is_filled: bool = false

# This function is called by the draggable food item (rice_cup)
func try_place_food(incoming_food_type: String, food_texture: Texture2D) -> bool:
	
	if is_filled:
		return false

	# Check if the food type matches this slot
	if incoming_food_type == accepted_food_type:
		is_filled = true
		linked_image.texture = food_texture
		linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor) # <<< FIX: Apply scale here
		return true
	else:
		return false
