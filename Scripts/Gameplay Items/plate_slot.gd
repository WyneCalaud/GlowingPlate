# plate_slot.gd
extends Area2D

@export var accepted_food_type: String = "Go"
@export var linked_image: Sprite2D # The empty sprite for this section
@export var plated_scale_factor: float = 0.4 

# --- CORRECTED GLOBAL DECLARATIONS ---
# This variable stores the resource once placed.
var item_resource: Resource = null 

# This variable tracks if the slot is full.
var is_filled: bool = false
# -------------------------------------

signal plate_updated # Used by the GameplayManager (Task 3.1)

# This function is called by the draggable food item (food_item_base.gd)
func try_place_food(incoming_resource: Resource) -> bool:
	
	# Check if the slot is already filled
	if is_filled:
		return false

	# VALIDATION: Check if the food category in the resource matches this slot's requirement
	if incoming_resource.food_category == accepted_food_type:
		is_filled = true
		
		# PLACEMENT: Update visuals and store the data
		linked_image.texture = incoming_resource.plated_texture
		linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor)
		item_resource = incoming_resource # Store the full resource data
		
		# Notify the Gameplay Manager that something was placed
		emit_signal("plate_updated", item_resource) 
		
		return true
	else:
		return false
