extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var chicken_leg: Texture2D
@export var draggable_scene: PackedScene 
@export var drag_scale: Vector2 = Vector2(0.2, 0.2)

# --- Use _ready to connect the Area2D signal ---
func _ready():
	# Assuming the Area2D child node is named "Area2D"
	var area_node = get_node_or_null("Area2D")
	if area_node:
		# Connect the Area2D's input signal to our handler
		area_node.connect("input_event", _on_area_2d_input_event)
	
# --- Input Handler (Triggers ONLY when the CollisionShape is clicked) ---
func _on_area_2d_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed():
		# BLOCK CAMERA HERE
		get_viewport().set_input_as_handled()
		_spawn_draggable()

func _spawn_draggable():
	if draggable_scene:
		var item = draggable_scene.instantiate()
		get_tree().current_scene.add_child(item)
		
		# Set item's global position to mouse location
		item.global_position = get_global_mouse_position()
		item.top_level = true
		item.z_index = 999
		
		# --- CRITICAL FIX START: PASS THE CORRECT TEXTURE & DATA ---
		
		# 1. Pass the Food Data (Logic)
		if item.has_method("set_food_data"): # Best practice if you have a setter
			item.set_food_data(food_data)
		elif "food_data" in item:
			item.food_data = food_data
			
		# 2. Pass the Visual Texture
		# We prefer the 'default_plated_texture' so the dragged item matches the look on the plate.
		# If not found, fall back to 'icon_texture', then 'chicken_leg'.
		var tex_to_use = chicken_leg
		
		if food_data:
			if "default_plated_texture" in food_data and food_data.default_plated_texture != null:
				tex_to_use = food_data.default_plated_texture
			elif "icon_texture" in food_data and food_data.icon_texture != null:
				tex_to_use = food_data.icon_texture
			
		# Apply the texture to the spawned item
		if tex_to_use:
			if "texture" in item:
				item.texture = tex_to_use
			elif item.has_node("Sprite"):
				item.get_node("Sprite").texture = tex_to_use
		
		# 3. Apply Scale Adjustment (NEW FIX)
		item.scale = drag_scale
		
		# --- CRITICAL FIX END ---
		
		# CRITICAL FIX: Set the item's start_position for return_to_start()
		if item.has_method("return_to_start"): 
			item.start_position = item.global_position 
		
		# Manually tell the item to start dragging
		if item.has_method("start_dragging"):
			item.start_dragging() 
	else:
		print("ERROR: Draggable Scene is not assigned!")
