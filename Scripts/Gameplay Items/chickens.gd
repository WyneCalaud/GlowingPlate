# chickens.gd (The Final, Robust Spawner Script)
extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var chicken_leg: Texture2D
@export var draggable_scene: PackedScene 

# --- Use _ready to connect the Area2D signal ---
func _ready():
	# Assuming the Area2D child node is named "Area2D"
	var area_node = get_node_or_null("Area2D")
	if area_node:
		# Connect the Area2D's input signal to our handler
		area_node.connect("input_event", _on_area_2d_input_event)
	
# --- Input Handler (Triggers ONLY when the CollisionShape is clicked) ---
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	# Only react to the left mouse button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		
		_spawn_draggable()
		
		# CRITICAL FIX: The Draggable Item must catch the event to start dragging.
		# We do NOT use set_input_as_handled() here to allow the draggable item to process the press.

func _spawn_draggable():
	if draggable_scene:
		var item = draggable_scene.instantiate()
		get_tree().current_scene.add_child(item)
		
		# Set item's global position to mouse location
		item.global_position = get_global_mouse_position()
		item.top_level = true
		item.z_index = 999
		
		# CRITICAL FIX: Set the item's start_position for return_to_start()
		# The start_position variable comes from the inherited food_item_base.gd
		if item.has_method("return_to_start"): # Check if it inherits the property
			item.start_position = item.global_position 
		
		# Manually tell the item to start dragging
		if item.has_method("start_dragging"):
			item.start_dragging() 
	else:
		print("ERROR: Draggable Scene is not assigned!")
