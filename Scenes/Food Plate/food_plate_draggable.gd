extends Node2D # Assuming your Plate is a Node2D or Sprite2D

# --- SIGNALS FOR GAME MANAGER ---
signal served(contents: Array) # Emitted when plate is served, passing contents
signal trashed # Emitted when plate is trashed (triggers food cleanup/reset)

# --- Z-INDEX CONSTANTS ---
const DRAG_Z_INDEX: int = 1
const DEFAULT_Z_INDEX: int = 1 

# --- DRAG STATE ---
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 # Stores the plate's starting position
var is_returning: bool = false
const RETURN_SPEED: float = 8.0 # Speed of interpolation (higher = faster return)

# --- DROP ZONE STATE ---
var is_over_serve_zone: bool = false
var is_over_trash_zone: bool = false

# --- CACHE NODE REFERENCES ---
@onready var plate_area: Area2D = $Area2D 

# --- INITIALIZATION ---
func _ready():
	# Store the initial position when the scene loads
	original_position = global_position
	print("Plate ready. Original position: ", original_position)
	
	# Set the initial Z-index
	self.z_index = DEFAULT_Z_INDEX
	
	# CRUCIAL: Ensure the Area2D is pickable for collision checks to work reliably
	if plate_area:
		plate_area.input_pickable = true
		
# --- DROP ZONE DETECTION (REQUIRES SIGNAL CONNECTION) ---
# NOTE: You MUST connect the 'body_entered' and 'body_exited' signals of the 
# child Area2D node (plate_area) to these functions in the Inspector!

func _on_plate_area_body_entered(body):
	# Assuming your zones are named "ServeZone" and "TrashZone"
	if body.name == "ServeZone": 
		is_over_serve_zone = true
		print("DEBUG: Entered Serve Zone")
	elif body.name == "TrashZone": 
		is_over_trash_zone = true
		print("DEBUG: Entered Trash Zone")

func _on_plate_area_body_exited(body):
	if body.name == "ServeZone":
		is_over_serve_zone = false
		print("DEBUG: Exited Serve Zone")
	elif body.name == "TrashZone":
		is_over_trash_zone = false
		print("DEBUG: Exited Trash Zone")

# --- INPUT HANDLING ---

# 1. Capture the input event for the whole node
func _input(event):
	
	# Start Dragging (Mouse Button Down)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.is_pressed():
			# If currently returning, stop the return animation instantly
			if is_returning:
				is_returning = false
			
			# --- NEW PRIORITY CHECK ---
			if is_mouse_over_plate_slot():
				# If the click is over a plate slot, we allow the slot to handle the placement.
				pass
			# -------------------------
			
			# Check if the click happened directly on the non-slot part of the Plate
			elif is_point_inside_area(get_global_mouse_position()):
				is_dragging = true
				
				# --- Z-INDEX FIX: Elevate the plate above all items while dragging ---
				self.z_index = DRAG_Z_INDEX
				
				# Calculate the offset between the plate's origin and the mouse click position
				drag_offset = get_global_mouse_position() - global_position
				
				# Set input as handled to prevent placement events on the slots
				get_viewport().set_input_as_handled()
				
		# Stop Dragging (Mouse Button Up)
		elif is_dragging and event.is_released():
			is_dragging = false
			_on_drop()
	
	# Handle dragging on touch screens
	if event is InputEventScreenTouch:
		if event.is_pressed():
			if is_returning:
				is_returning = false
			
			# --- NEW PRIORITY CHECK (Touch) ---
			if is_mouse_over_plate_slot():
				pass
			# ----------------------------------
				
			elif is_point_inside_area(get_global_mouse_position()):
				is_dragging = true
				
				# --- Z-INDEX FIX: Elevate the plate above all items while dragging ---
				self.z_index = DRAG_Z_INDEX
				
				drag_offset = get_global_mouse_position() - global_position
				get_viewport().set_input_as_handled()
		elif is_dragging and event.is_released():
			is_dragging = false
			_on_drop()

# 2. Handle Movement and Return Animation
func _process(delta):
	if is_dragging:
		# Update the plate's position based on the current mouse position minus the offset
		global_position = get_global_mouse_position() - drag_offset
	elif is_returning:
		# Smoothly move the plate back to its original position
		global_position = global_position.lerp(original_position, delta * RETURN_SPEED)
		
		# Stop returning when close enough to avoid infinite movement
		if global_position.distance_to(original_position) < 1.0:
			global_position = original_position
			is_returning = false

# --- DROP LOGIC (Called when dragging stops) ---
func _on_drop():
	# 1. Reset Z-index immediately
	self.z_index = DEFAULT_Z_INDEX
	
	# --- CRITICAL: Gather the contents BEFORE processing the drop action ---
	var plate_contents = get_plate_contents()
	
	# Check if the plate is empty
	var is_plate_truly_empty = plate_contents.size() == 0

	if is_over_serve_zone:
		# --- SERVE ACTION ---
		if is_plate_truly_empty:
			print("WARNING: Cannot serve empty plate.")
			is_returning = true # Just return the plate
			return
			
		print("ACTION: Plate Served. Transitioning to Beverages Scene.")
		# PASS THE CONTENTS TO THE GAME MANAGER
		emit_signal("served", plate_contents) 
		
		# Reset position instantly for the "Served" transition effect
		global_position = original_position
		
		# Clear food visuals so the next plate starts clean
		reset_plate_visuals() 
		
	elif is_over_trash_zone:
		# --- TRASH ACTION ---
		if is_plate_truly_empty:
			print("RESTRICTION: Trash attempt failed, plate is empty.")
			# The PlateDraggable debug output you provided seems to come from here!
			is_returning = true
			return
			
		print("ACTION: Plate Trashed. Removing food and returning.")
		
		# Clear all food from slots
		reset_plate_visuals()
		emit_signal("trashed")
		
		# Start smooth return (looks like a new, clean plate is sliding into place)
		is_returning = true

	else:
		# --- RETURN HOME ACTION ---
		# Default behavior: Always return to original position
		is_returning = true

# --- UTILITY FUNCTIONS ---

# Public function to read the data from all plate slots.
func get_plate_contents() -> Array:
	var contents = []
	
	# This is where the error likely occurs: Reading the child Area2D properties.
	for child in get_children():
		# Check if the child is an Area2D and is likely a plate slot
		if child is Area2D and child.name.contains("Slot"):
			
			# Check if the slot script is attached and has the required properties
			if child.has_meta("is_filled") and child.has_meta("item_resource"):
				
				var is_filled = child.get_meta("is_filled")
				var item_resource = child.get_meta("item_resource")
				
				print("DEBUG [PlateDraggable]: Slot %s -> is_filled: %s, Item: %s" % [child.name, is_filled, item_resource])
				
				# Assuming the plate slot script exposes the data directly via @export or getters
				if is_filled and item_resource != null:
					
					# NOTE: ASSUMING YOUR SLOTS ARE NAMED SlotGo, SlotGrow, etc.
					var accepted_type = "UNKNOWN"
					if child.name.contains("Go"): accepted_type = "Go"
					elif child.name.contains("Grow"): accepted_type = "Grow"
					elif child.name.contains("GlowVeg"): accepted_type = "GlowVeg"
					elif child.name.contains("GlowFru"): accepted_type = "GlowFru"
					
					contents.append({
						"item": item_resource,
						"accepted_type": accepted_type # Food category for scoring
					})
					
			# FALLBACK: Access exported variables directly (This relies on the latest plate_slot.gd)
			elif child.has_node("linked_image"): # Simple check to see if it's a known slot structure
				
				# Since the variables are @export in the plate_slot.gd, they should be accessible
				# as properties of the script itself, not as meta data.
				var item_resource_ref = child.get("item_resource")
				var is_filled_ref = child.get("is_filled")
				
				print("DEBUG [PlateDraggable - FALLBACK]: Slot %s -> is_filled: %s, Item: %s" % [child.name, is_filled_ref, item_resource_ref.get("item_name") if item_resource_ref else "NULL"])
				
				if is_filled_ref and item_resource_ref != null:
					var accepted_type = "UNKNOWN"
					if child.name.contains("Go"): accepted_type = "Go"
					elif child.name.contains("Grow"): accepted_type = "Grow"
					elif child.name.contains("GlowVeg"): accepted_type = "GlowVeg"
					elif child.name.contains("GlowFru"): accepted_type = "GlowFru"
					
					contents.append({
						"item": item_resource_ref,
						"accepted_type": accepted_type
					})
					
			else:
				print("WARNING: Plate slot ", child.name, " does not appear to have the expected structure or properties.")

	# The output you saw came from the function that reads these contents.
	# The key issue is that the item_resource and is_filled properties are not being read correctly
	# from the plate slot nodes, or the `plate_slot.gd` script is not actually attached.
	# We are forcing the fallback access now.
	
	print("DEBUG [PlateDraggable]: Total Items Read: %d" % contents.size())
	return contents

# Clears the food item from all slots on the plate.
func reset_plate_visuals():
	for child in get_children():
		# Assuming plate slots are Area2Ds with a 'Slot' in their name
		if child is Area2D and child.name.contains("Slot"):
			# IMPORTANT: This ASSUMES your plate_slot.gd script has a public clear_slot() method!
			if child.has_method("clear_slot"): 
				child.clear_slot()
			elif child.has_method("clear_food"):
				# Handle case if the function name was 'clear_food' in a prior version
				child.clear_food() 
			else:
				# Log an error if the method is missing for debugging
				print("ERROR: Plate slot named ", child.name, " is missing the required 'clear_slot()' method!")

# --- HELPER FUNCTION: Prioritize Plate Slot Input ---
func is_mouse_over_plate_slot() -> bool:
	# Iterate through all children to find the plate slots (which are Area2Ds)
	# Assuming plate slots are named 'Slot...' or are direct Area2D children
	for child in get_children():
		# Check if the child is an Area2D (like plate_slot.gd) and its Area2D has a collision shape
		# Note: plate_slot.gd inherits Area2D, so this check works if plate slots are children of FoodPlate
		if child is Area2D and child.name.contains("Slot"):
			
			# We must test the mouse position against the Area2D's shape
			# This uses the built-in collision/physics query, which is the most reliable method
			var space = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collide_with_areas = true
			query.collide_with_bodies = false
			
			# Get all objects overlapping the mouse position
			var result = space.intersect_point(query)
			
			for hit in result:
				# Check if the hit object is one of our plate slot nodes
				if hit.collider == child:
					return true # Yes, the mouse is over a plate slot
					
	return false

# --- HELPER FUNCTION: Check if the click is on the Plate using the Area2D ---
func is_point_inside_area(point: Vector2) -> bool:
	if plate_area and plate_area.input_pickable:
		
		for i in range(plate_area.get_child_count()):
			var child = plate_area.get_child(i)
			if child is CollisionShape2D:
				var shape_node = child as CollisionShape2D
				var shape = shape_node.shape
				if shape:
					# Convert the global mouse position to the local coordinates of the Area2D
					var local_point = plate_area.to_local(point)
					
					# Test the point against the shape's geometry
					# Checking the bounding box is a quick, approximate test that usually works for simple shapes.
					if shape.get_rect().has_point(local_point):
						return true
						
	# Fallback check (less precise, but safer than nothing)
	var plate_sprite = find_child("PlateSprite")
	if plate_sprite and plate_sprite is Sprite2D:
		var local_point = plate_sprite.to_local(point)
		var texture_rect = plate_sprite.get_rect()
		return texture_rect.has_point(local_point)

	return false
