# filled_glass.gd
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
	
	# 1. Elevate Z-Index to appear above Serve/Trash zones (which are at Z=50)
	z_index = 100
	
	# 2. Block Camera Movement
	var cam = get_tree().get_first_node_in_group("MainCamera")
	if cam and "is_input_blocked" in cam:
		cam.is_input_blocked = true
	
	# 3. Show the drop zones
	if serve_trash_zone:
		serve_trash_zone.visible = true
		# Move to specific X position (1240.0) for the cup
		serve_trash_zone.global_position.x = 1240.0
		print("ACTION: Serve/Trash zones visible at x=1240.0.")

# --- OVERRIDE: Drop Ends (Hide Zones) ---
func handle_drop():
	# 1. Reset Z-Index
	z_index = 0
	
	# 2. Unblock Camera Movement
	var cam = get_tree().get_first_node_in_group("MainCamera")
	if cam and "is_input_blocked" in cam:
		cam.is_input_blocked = false

	# 3. CRITICAL RECOVERY: Manually check for overlaps before hiding zones.
	# We prioritize "Serve" over "Trash" and "Table" to ensure detection.
	_perform_manual_overlap_check()

	# 4. Hide the drop zones before processing the drop outcome
	if serve_trash_zone:
		serve_trash_zone.visible = false
		
	# Call the base logic to handle placing, trashing, or returning home
	super.handle_drop()

# --- RECOVERY: MANUAL OVERLAP CHECK ---
func _perform_manual_overlap_check():
	var area_node = get_node_or_null("Area2D")
	if not area_node: return

	var overlapping = area_node.get_overlapping_areas()
	var found_zone: Area2D = null

	for area in overlapping:
		# Ignore self-collision or children
		if area == area_node or area.owner == self or area.get_parent() == self: 
			continue
		
		var a_name = area.name.to_lower()
		var p_name = area.get_parent().name.to_lower()
		
		# PRIORITY 1: Serve Zone
		if a_name.contains("serve") or p_name.contains("serve"):
			current_hovered_area = area
			print("RECOVERY [FilledGlass]: Prioritized Serve Zone detected.")
			return # Stop here, we found the most important zone

		# PRIORITY 2: Trash Zone (Only set if we haven't found serve yet)
		if a_name.contains("trash") or p_name.contains("trash"):
			found_zone = area

	# If we didn't find a serve zone but found a trash zone, set it now
	if found_zone:
		current_hovered_area = found_zone
		print("RECOVERY [FilledGlass]: Trash Zone detected.")

# --- OVERRIDE: Area Detection (Debugging) ---
func _on_area_2d_area_entered(area: Area2D) -> void:
	# Ignore self
	if area.owner == self or area.get_parent() == self: return
	
	current_hovered_area = area
	
	var a_name = area.name.to_lower()
	var p_name = area.get_parent().name.to_lower()
	
	print("!!! COLLISION DEBUG [FilledGlass]: ENTERED Area: ", area.name, " (Parent: ", area.get_parent().name, ")")
	if a_name.contains("serve") or p_name.contains("serve"):
		print("!!! COLLISION DEBUG: SERVE ZONE DETECTED !!!")
	elif a_name.contains("trash") or p_name.contains("trash"):
		print("!!! COLLISION DEBUG: TRASH ZONE DETECTED !!!")

func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_hovered_area == area:
		current_hovered_area = null
	
	print("!!! COLLISION DEBUG [FilledGlass]: EXITED Area: ", area.name)


# --- OVERRIDE: Plate success logic ---
func on_plate_placement_success():
	print("ACTION: Filled glass served successfully.")

	var gd := get_tree().get_first_node_in_group("GameData")
	if not gd:
		push_error("GameData not found while serving beverage!")
		queue_free()
		return

	# Determine beverage type from food_data
	var beverage_res := food_data
	if not beverage_res:
		push_warning("Filled glass has no food_data!")
		queue_free()
		return

	# Store drink amount
	if current_liquid_amount != "":
		beverage_res.set_meta("DrinkAmount", current_liquid_amount)
	# 🔥 STORE LIQUID TYPE HERE (safe and guaranteed)
		if has_meta("LiquidType"):
			beverage_res.set_meta("LiquidType", str(get_meta("LiquidType")).to_upper())

	# Store in GameData if method exists
	if gd.has_method("add_prepared_beverage"):
		gd.add_prepared_beverage(beverage_res)
		
	# Notify the KitchenServiceManager that the beverage is served
	get_tree().call_group("service_manager", "serve_beverage")

	queue_free()


# --- OVERRIDE: Handle unique drop zones (Trash) ---
func on_unique_drop_zone_check():
	
	if current_hovered_area:
		# Check for the trash area name or its parent's name
		var area_name = current_hovered_area.name.to_lower()
		var parent_name = current_hovered_area.get_parent().name.to_lower()
		
		# LOG: What are we checking right now?
		print("DEBUG [Drop Check]: Hovering over Area: ", area_name, " (Parent: ", parent_name, ")")
		
		if area_name.contains("serve") or parent_name.contains("serve"):
			print("ACTION: Beverage served.")
			on_plate_placement_success()
			return
		
		if area_name.contains("trash") or parent_name.contains("trash"):
			print("ACTION: Filled glass trashing, replacing with empty.")
			
			# Find the Global Controller
			var spawner_controller = get_tree().get_first_node_in_group("global_controller")
			
			if spawner_controller and spawner_controller.has_method("replace_filled_with_empty"):
				spawner_controller.replace_filled_with_empty(self)
				return
			else:
				printerr("FATAL ERROR: Failed to find Global Controller or swap method!")
				queue_free()
				return
			
	# Default: Return to start if dropped on nothing valid
	print("DEBUG [FilledGlass]: No valid zone detected at drop. Returning home.")
	return_to_start()
