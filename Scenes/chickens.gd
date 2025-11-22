# chickens.gd
extends Sprite2D # <<< NO LONGER EXTENDS food_item_base.gd! It's just a manager.

# --- EXPORTS ---
# Reference the scene file we just created
@export var chicken_leg_scene: PackedScene 

# The main container should have its own Area2D for detecting the click.

func _ready() -> void:
	# Ensure the container has an Area2D child named "Area2D" connected to _on_area_2d_input_event
	pass 

# --- INPUT LOGIC ---
# This function is now responsible for spawning and starting the drag.
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or \
	   (event is InputEventScreenTouch and event.is_pressed()):
		
		if chicken_leg_scene:
			# 1. Instantiate the single leg scene
			var new_leg = chicken_leg_scene.instantiate() 
			
			# 2. Add it to the current scene (parent of the container)
			get_parent().add_child(new_leg)
			
			# 3. Position the leg where the container is
			new_leg.global_position = global_position
			
			# 4. Manually start the dragging state on the new leg
			if new_leg.has_method("start_dragging"):
				new_leg.start_dragging()
			else:
				new_leg.is_dragging = true
				new_leg.z_index = 30 # Bring to front while dragging
