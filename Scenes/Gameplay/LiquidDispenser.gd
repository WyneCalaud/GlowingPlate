extends Area2D 

# --- CONFIGURATION (Set these in the Inspector) ---
@export var liquid_type: String = "water_1" 
@export var unselected_texture: Texture2D # The default look
@export var selected_texture: Texture2D   # The selected/active look

# --- NODE REFERENCES ---
@onready var sprite: Sprite2D = $".." # Assuming the Sprite2D is the parent, or adjust path
var global_controller: Node = null

func _ready():
	# Initial Setup
	if sprite and is_instance_valid(unselected_texture):
		sprite.texture = unselected_texture
		
	# Find the global controller
	var controllers = get_tree().get_nodes_in_group("global_controller")
	if controllers.size() > 0:
		global_controller = controllers[0]
	else:
		push_error("Global Controller (StackGlass Spawner) not found!")
	
	# Ensure the Area2D is pickable
	set_pickable(true)

# --- INPUT HANDLING ---
func _input_event(_viewport, event, _shape_idx):
	# Only react to the press event
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		
		# Consume the event to prevent clicking through to other nodes
		get_viewport().set_input_as_handled() 
		
		if global_controller:
			
			# Check if we are ALREADY selected (Toggling)
			if global_controller.selected_liquid == liquid_type:
				# Toggle OFF (Deselect)
				global_controller.reset_liquid_selection_visuals()
				print("STATE: Deselected %s" % liquid_type)
			else:
				# Select as normal
				global_controller.set_liquid_selection(self, liquid_type)
				# NOTE: The global_controller handles resetting others and setting state.
				# We only need to ensure *this* visual state is correct.
				set_visual_state(true)
				print("STATE: Selected liquid set to: %s" % liquid_type)

# Helper function to change the texture
func set_visual_state(is_selected: bool):
	if sprite:
		if is_selected and is_instance_valid(selected_texture):
			sprite.texture = selected_texture
		elif is_instance_valid(unselected_texture):
			sprite.texture = unselected_texture
