extends Node2D

# --- SIGNALS FOR GAME MANAGER ---
signal trashed
signal drag_state_changed(is_dragging_now: bool)

# --- Z-INDEX CONSTANTS ---
const DRAG_Z_INDEX: int = 10
const DEFAULT_Z_INDEX: int = 10
const RETURN_SPEED: float = 8.0
const PLATE_SLOT_SCRIPT_PATH_SUFFIX = "plate_slot.gd"

# --- CACHE NODE REFERENCES ---
@onready var plate_area: Area2D = $Area2D
@onready var GameData = get_node("/root/GameData")

# --- DRAG STATE ---
var is_dragging: bool = false:
	set(value):
		if is_dragging != value:
			is_dragging = value
			emit_signal("drag_state_changed", is_dragging)
var drag_offset: Vector2 = Vector2.ZERO
var original_position: Vector2
var is_returning: bool = false

# --- DROP ZONE STATE ---
var is_over_serve_zone: bool = false
var is_over_trash_zone: bool = false

# --- INITIALIZATION ---
func _ready():
	original_position = global_position
	print("Plate ready. Original position: ", original_position)
	self.z_index = DEFAULT_Z_INDEX
	if plate_area:
		plate_area.input_pickable = true
		
# --- DROP ZONE DETECTION ---
func _on_area_2d_area_entered(area: Area2D):
	if area.get_parent().name == "Serve":
		is_over_serve_zone = true
		print("DEBUG: Entered Serve Zone")
	elif area.get_parent().name == "Trash":
		is_over_trash_zone = true
		print("DEBUG: Entered Trash Zone")

func _on_area_2d_area_exited(area: Area2D):
	if area.get_parent().name == "Serve":
		is_over_serve_zone = false
		print("DEBUG: Exited Serve Zone")
	elif area.get_parent().name == "Trash":
		is_over_trash_zone = false
		print("DEBUG: Exited Trash Zone")

# --- INPUT HANDLING ---
func _input(event):
	var mouse_pos = get_global_mouse_position()
	
	var is_press = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventScreenTouch and event.is_pressed())
	var is_release = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released()) or (event is InputEventScreenTouch and event.is_released())

	if is_press:
		if is_returning: is_returning = false
			
		if is_mouse_over_plate_slot():
			# If clicking a slot, we still want to block the camera
			get_viewport().set_input_as_handled()
			return 
			
		var contents_size = get_plate_contents().size()
		if is_point_inside_area(mouse_pos) and contents_size > 0:
			self.is_dragging = true
			self.z_index = DRAG_Z_INDEX
			drag_offset = mouse_pos - global_position
			# BLOCK CAMERA HERE
			get_viewport().set_input_as_handled()
			print("DEBUG [Drag Start]: Plate has %d items. Starting drag." % contents_size)
		elif is_point_inside_area(mouse_pos):
			# Even if drag fails (empty plate), block camera because we touched an item
			get_viewport().set_input_as_handled()
			print("RESTRICTION: Cannot drag an empty plate.")

	elif is_release:
		if is_dragging:
			self.is_dragging = false
			if get_viewport():
				get_viewport().set_input_as_handled()
			_on_drop()


# 2. Handle Movement and Return Animation
func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
	elif is_returning:
		global_position = global_position.lerp(original_position, delta * RETURN_SPEED)
		
		if global_position.distance_to(original_position) < 1.0:
			global_position = original_position
			is_returning = false
			self.z_index = DEFAULT_Z_INDEX

# --- DROP LOGIC (Called when dragging stops) ---
func _on_drop():
	self.z_index = DEFAULT_Z_INDEX
	
	var plate_contents = get_plate_contents()
	var is_plate_truly_empty = plate_contents.size() == 0
	
	print("DEBUG [Drop]: Drop initiated. Over Serve: ", is_over_serve_zone, ", Over Trash: ", is_over_trash_zone)
	print("DEBUG [Drop]: Plate has %d items. Is empty: %s" % [plate_contents.size(), is_plate_truly_empty])

	var handled = false
	if is_over_serve_zone:
		handled = true
		if is_plate_truly_empty:
			print("WARNING: Cannot serve empty plate.")
			is_returning = true
		else:
			print("ACTION: Plate Served. Storing data and initiating transition.")
			
			# This is where the scene transition is triggered.
			if is_instance_valid(GameData):
				# FIX: Use wrapper only. Removed direct assignments to GameData properties 
				# (like prepared_plate_contents) because they were moved to OrderSystem.
				# store_plate_contents handles the transfer safely.
				GameData.store_plate_contents(plate_contents)
				

			else:
				print("FATAL ERROR: GameData Autoload not found. Cannot proceed with serving.")
				is_returning = true
			
	elif is_over_trash_zone:
		handled = true
		if is_plate_truly_empty:
			print("RESTRICTION: Cannot trash empty plate.")
			is_returning = true
		else:
			print("ACTION: Plate Trashed. Contents cleared.")
			reset_plate_visuals()
			emit_signal("trashed")
			is_returning = true

	if not handled:
		is_returning = true # Return home

# --- CORE FUNCTION: READ DATA FROM SLOTS ---
func get_plate_contents() -> Array:
	var contents = []
	
	for child in get_children():
		if child is Area2D and child.name.contains("Slot"):
			
			var script = child.get_script()
			if not (script is GDScript and script.resource_path.ends_with(PLATE_SLOT_SCRIPT_PATH_SUFFIX)):
				continue
				
			var is_filled_ref = child.get("is_filled")
			var item_resource_ref = child.get("item_resource")

			if is_filled_ref and item_resource_ref != null and item_resource_ref is Resource:
				
				var accepted_type = "UNKNOWN"
				if child.name.contains("Go"): accepted_type = "Go"
				elif child.name.contains("Grow"): accepted_type = "Grow"
				elif child.name.contains("GlowVeg"): accepted_type = "GlowVeg"
				elif child.name.contains("GlowFru"): accepted_type = "GlowFru"
				
				contents.append({
					"item": item_resource_ref,
					"accepted_type": accepted_type
				})
				
	print("DEBUG [PlateDraggable]: Total Valid Items Read: %d" % contents.size())
	return contents

# Clears the food item from all slots on the plate.
func reset_plate_visuals():
	for child in get_children():
		if child is Area2D and child.name.contains("Slot"):
			if child.has_method("clear_slot"):
				child.clear_slot()
			elif child.has_method("clear_food"):
				child.clear_food()
			else:
				print("ERROR: Plate slot named ", child.name, " is missing the required 'clear_slot()' method!")

# --- HELPER FUNCTIONS ---
func is_mouse_over_plate_slot() -> bool:
	for child in get_children():
		if child is Area2D and child.name.contains("Slot"):
			var space = get_world_2d().direct_space_state
			var query = PhysicsPointQueryParameters2D.new()
			query.position = get_global_mouse_position()
			query.collide_with_areas = true
			query.collide_with_bodies = false
			var result = space.intersect_point(query)
			for hit in result:
				if hit.collider == child:
					return true
	return false

func is_point_inside_area(point: Vector2) -> bool:
	if plate_area and plate_area.input_pickable:
		var space = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = point
		query.collide_with_areas = true
		query.collide_with_bodies = false
		var result = space.intersect_point(query)
		for hit in result:
			if hit.collider == plate_area:
				return true
			
	var plate_sprite = find_child("PlateSprite")
	if plate_sprite and plate_sprite is Sprite2D:
		var local_point = plate_sprite.to_local(point)
		var texture_rect = plate_sprite.get_rect()
		return texture_rect.has_point(local_point)

	return false
