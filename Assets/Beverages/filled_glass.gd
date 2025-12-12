extends "res://Scripts/Food Data/food_item_base.gd"

# --- CONFIGURATION ---
@export var water_data: Resource 

# --- STATE ---
var current_liquid_amount: String = "Right" 
var serve_trash_zone: Node2D = null # Node reference for the Serve/Trash container

func _ready():
	# 1. Capture the texture set by the Spawner
	var correct_level_texture = texture
	
	# 2. Setup Data Identity
	if water_data:
		food_data = water_data
	
	# 3. Call Parent Ready (Sets up dragging connections and signal connections)
	super._ready()
	
	# 4. Restore Texture
	if correct_level_texture:
		texture = correct_level_texture
	
	# 5. Ensure Input is active
	var area_node = get_node_or_null("Area2D")
	if area_node:
		area_node.input_pickable = true

	# 6. FIND SERVE/TRASH ZONE: Look in the main scene tree for the node
	serve_trash_zone = get_tree().root.find_child("ServeOrTrash", true, false)
	if not serve_trash_zone:
		serve_trash_zone = get_tree().root.find_child("Serve or Trash", true, false)
	
	if serve_trash_zone:
		# Ensure zones start hidden
		serve_trash_zone.visible = false
		print("DEBUG: Serve/Trash zone found.")

# --- OVERRIDE: Dragging Starts (Show Zones) ---
func start_dragging():
	super.start_dragging() 
	
	# Show the drop zones
	if serve_trash_zone:
		serve_trash_zone.visible = true
		print("ACTION: Serve/Trash zones visible.")

# --- OVERRIDE: Drop Ends (Hide Zones) ---
func handle_drop():
	# Hide the drop zones before processing the drop outcome
	if serve_trash_zone:
		serve_trash_zone.visible = false
		
	# Call the base logic to handle placing, trashing, or returning home
	super.handle_drop()

# --- OVERRIDE: Area Detection (Debugging) ---
# NOTE: This function overrides the inherited logic from food_item_base.gd
# to provide detailed logging and ensure current_hovered_area is set.
func _on_area_2d_area_entered(area: Area2D) -> void:
	# CRITICAL: Manually set the base variable since we are overriding the base function.
	current_hovered_area = area
	
	print("!!! COLLISION DEBUG [FilledGlass]: ENTERED Area: ", area.name, " (Parent: ", area.get_parent().name, ")")
	if area.name.to_lower().contains("trash") or area.get_parent().name.to_lower().contains("trash"):
		print("!!! COLLISION DEBUG: TRASH ZONE DETECTED !!!")

func _on_area_2d_area_exited(area: Area2D) -> void:
	# CRITICAL: Manually clear the base variable since we are overriding the base function.
	if current_hovered_area == area:
		current_hovered_area = null
	
	print("!!! COLLISION DEBUG [FilledGlass]: EXITED Area: ", area.name, " (Parent: ", area.get_parent().name, ")")


# --- OVERRIDE: Plate success logic ---
func on_plate_placement_success():
	print("ACTION: Filled glass served/placed successfully.")
	queue_free()

# --- OVERRIDE: Handle unique drop zones (Trash) ---
func on_unique_drop_zone_check():
	if current_hovered_area:
		# Check for the trash area name or its parent's name
		var area_name = current_hovered_area.name.to_lower()
		var parent_name = current_hovered_area.get_parent().name.to_lower()
		
		# Log the area being checked just before the swap attempt
		print("DEBUG [Drop Check]: Hovering over Area: ", area_name, " (Parent: ", parent_name, ")")
		
		if area_name.contains("trash") or parent_name.contains("trash"):
			print("ACTION: Filled glass trashing, replacing with empty.")
			
			# 1. Find the Global Controller (RELYING ON GROUP)
			var spawner_controller = get_tree().get_first_node_in_group("global_controller")
			
			# 2. Debugging Check & Call
			if spawner_controller and spawner_controller.has_method("replace_filled_with_empty"):
				spawner_controller.replace_filled_with_empty(self)
				return
			else:
				# Log detailed error information if the lookup fails
				printerr("FATAL ERROR: Failed to find Global Controller or swap method!")
				var all_controllers = get_tree().get_nodes_in_group("global_controller")
				if all_controllers.size() == 0:
					printerr("DEBUG: Global Controller group returned 0 nodes. Check spawner's group tag.")
				else:
					printerr("DEBUG: Global Controller found, but missing 'replace_filled_with_empty' method.")
				
				queue_free()
				return
			
	# Default: Return to start if dropped on nothing valid
	return_to_start()
