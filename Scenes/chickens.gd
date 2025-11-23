# chickens.gd
extends Sprite2D # This container is just an image, no drag logic

# --- EXPORT (Must be linked to the ChickenLeg.tscn scene file) ---
@export var chicken_leg_scene: PackedScene 

# --- SIGNAL FUNCTION (Called when player clicks the container) ---
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	# We only care about the initial press/hold event
	var is_press = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or \
				   (event is InputEventScreenTouch and event.is_pressed())
	
	if is_press and chicken_leg_scene:
		
		# 1. Instantiate the single leg instance
		var new_leg = chicken_leg_scene.instantiate() 
		
		# 2. Add it to the main scene (to allow free movement)
		# Adding to the parent node of the container is usually safest:
		get_parent().add_child(new_leg)
		
		# 3. Position the leg where the mouse cursor is located
		new_leg.global_position = get_global_mouse_position()
		
		# 4. Tell the instance to start its dragging state
		# We use 'call' for safety since this method is defined in the base class.
		new_leg.call("start_dragging")
