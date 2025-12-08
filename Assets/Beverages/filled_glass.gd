extends "res://Scripts/Food Data/food_item_base.gd"

# --- CONFIGURATION ---
@export var water_data: Resource 

func _ready():
	# 1. Capture the texture set by the Spawner (Low, Med, High, etc.)
	# We do this BEFORE calling super._ready(), which would overwrite it.
	var correct_level_texture = texture
	
	# 2. Setup Data Identity
	if water_data:
		food_data = water_data
	
	# 3. Call Parent Ready (Sets up dragging connections and normally resets texture)
	super._ready()
	
	# 4. RESTORE the correct texture
	# If the spawner gave us a specific texture, we use that instead of the default.
	if correct_level_texture:
		texture = correct_level_texture
	
	# 5. Ensure Input is active
	var area_node = get_node_or_null("Area2D")
	if area_node:
		area_node.input_pickable = true

# --- OVERRIDE: Handle what happens when dropped on a Plate/Tray ---
func on_plate_placement_success():
	print("ACTION: Filled glass served/placed successfully.")
	queue_free()

# --- OVERRIDE: Handle unique drop zones (Trash, Sink, etc.) ---
func on_unique_drop_zone_check():
	if current_hovered_area:
		if current_hovered_area.name == "Trash":
			print("ACTION: Filled glass trashed.")
			queue_free()
			return
			
	# Default: Return to start if dropped on nothing valid
	return_to_start()
