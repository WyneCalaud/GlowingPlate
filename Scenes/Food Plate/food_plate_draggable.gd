extends Node2D # Assuming your Plate is a Node2D or Sprite2D

# --- Z-INDEX CONSTANTS ---
# Use a very high Z-index to ensure the plate is ALWAYS on top when dragged.
const DRAG_Z_INDEX: int = 10
const DEFAULT_Z_INDEX: int = 1 # Assuming the plate's base Z-index is 999

# --- DRAG STATE ---
var is_dragging: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2 # Stores the plate's starting position
var is_returning: bool = false
const RETURN_SPEED: float = 8.0 # Speed of interpolation (higher = faster return)

# --- CACHE NODE REFERENCES ---
# Assuming the Area2D is a direct child named "Area2D" as per your scene structure
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
	# --- Z-INDEX FIX: Reset the plate's Z-index after dropping ---
	self.z_index = DEFAULT_Z_INDEX
	
	# Default behavior: Always return to original position
	is_returning = true

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
