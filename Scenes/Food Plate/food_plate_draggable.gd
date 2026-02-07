# food_plate_draggable.gd
extends Node2D

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

# --- SIGNALS FOR GAME MANAGER ---
signal trashed
signal drag_state_changed(is_dragging_now: bool)

# --- Z-INDEX & LAYER CONSTANTS ---
const DRAG_Z_INDEX: int = 4096 # Maximum possible Z-Index
const DEFAULT_Z_INDEX: int = 10
const RETURN_SPEED: float = 8.0

# --- CACHE NODE REFERENCES ---
@onready var plate_area: Area2D = $Area2D
@onready var GameData = get_node("/root/GameData")

# --- DRAG STATE ---
var is_dragging: bool = false:
	set(value):
		if is_dragging != value:
			is_dragging = value
			emit_signal("drag_state_changed", is_dragging)
			
			if is_dragging:
				get_tree().call_group("food_dispenser", "deselect")
				self.z_index = DRAG_Z_INDEX
				self.z_as_relative = false 

var drag_offset: Vector2 = Vector2.ZERO
var original_local_pos: Vector2 
var is_returning: bool = false

# --- DROP ZONE STATE ---
var is_over_serve_zone: bool = false
var is_over_trash_zone: bool = false

# --- INITIALIZATION ---
func _ready():
	original_local_pos = position 
	self.z_index = DEFAULT_Z_INDEX
	if plate_area:
		plate_area.input_pickable = true
		
# --- DROP ZONE DETECTION ---
func _on_area_2d_area_entered(area: Area2D):
	if area.name == "GlobalServeZone" or area.is_in_group("serve_zone"):
		is_over_serve_zone = true
	elif area.name == "GlobalTrashZone" or area.is_in_group("trash_zone"):
		is_over_trash_zone = true

func _on_area_2d_area_exited(area: Area2D):
	if area.name == "GlobalServeZone" or area.is_in_group("serve_zone"):
		is_over_serve_zone = false
	elif area.name == "GlobalTrashZone" or area.is_in_group("trash_zone"):
		is_over_trash_zone = false

# --- INPUT HANDLING ---
func _input(event):
	if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER != null:
		return

	var mouse_pos = get_global_mouse_position()
	
	var is_press = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventScreenTouch and event.is_pressed())
	var is_release = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_released()) or (event is InputEventScreenTouch and event.is_released())

	if is_press:
		if is_returning: is_returning = false
			
		if is_mouse_over_plate_slot():
			return 
			
		if is_point_inside_area(mouse_pos):
			if get_plate_contents().size() > 0:
				drag_offset = mouse_pos - global_position
				self.is_dragging = true
				get_viewport().set_input_as_handled()

	elif is_release:
		if is_dragging:
			self.is_dragging = false
			_on_drop()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() - drag_offset
	elif is_returning:
		position = position.lerp(original_local_pos, delta * RETURN_SPEED)
		
		if position.distance_to(original_local_pos) < 0.5:
			position = original_local_pos
			is_returning = false
			self.z_index = DEFAULT_Z_INDEX
			self.z_as_relative = true

func _on_drop():
	var plate_contents = get_plate_contents()
	var is_plate_truly_empty = plate_contents.size() == 0
	
	var handled = false
	
	# CASE 1: SERVE ZONE
	if is_over_serve_zone:
		handled = true
		if not is_plate_truly_empty and is_instance_valid(GameData):
			GameData.store_plate_contents(plate_contents)
			_animate_new_plate_arrival()
		else:
			is_returning = true
			
	# CASE 2: TRASH ZONE
	elif is_over_trash_zone:
		handled = true
		if not is_plate_truly_empty:
			if is_instance_valid(GameData):
				if GameData.has_method("add_money"):
					GameData.add_money(-5)
				elif GameData.has_method("adjust_money"):
					GameData.adjust_money(-5)
				
			emit_signal("trashed")
			_animate_new_plate_arrival()
		else:
			is_returning = true

	if not handled:
		is_returning = true

# --- NEW PLATE ANIMATION ---
func _animate_new_plate_arrival():
	is_returning = false
	self.z_index = DEFAULT_Z_INDEX
	self.z_as_relative = true
	
	reset_plate_visuals()
	
	var spawn_offset = Vector2(0, 600) 
	position = original_local_pos + spawn_offset
	
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_local_pos, 0.6)

# --- FIXED LOGIC HERE ---
func get_plate_contents() -> Array:
	var contents = []
	for child in get_children():
		# Check if it's a plate slot using the Group or Script property
		if child.is_in_group("plate_slot"):
			if child.get("is_filled") and child.get("item_resource") != null:
				# DIRECTLY get the type from the slot's exported variable
				var type = child.get("slot_type")
				
				# Fallback just in case
				if type == null or type == "": 
					print("WARNING: Slot ", child.name, " has no slot_type set!")
					type = "UNKNOWN"
					
				contents.append({"item": child.item_resource, "accepted_type": type})
	return contents

func reset_plate_visuals():
	for child in get_children():
		# Use group check here too for consistency
		if child.is_in_group("plate_slot"):
			if child.has_method("clear_slot"): child.clear_slot()
			elif child.has_method("clear_food"): child.clear_food()

func is_mouse_over_plate_slot() -> bool:
	var mouse_pos = get_global_mouse_position()
	var space = get_world_2d().direct_space_state
	var query = PhysicsPointQueryParameters2D.new()
	query.position = mouse_pos
	query.collide_with_areas = true
	var results = space.intersect_point(query)
	for result in results:
		if result.collider.is_in_group("plate_slot"): return true
	return false

func is_point_inside_area(point: Vector2) -> bool:
	if plate_area:
		var space = get_world_2d().direct_space_state
		var query = PhysicsPointQueryParameters2D.new()
		query.position = point
		query.collide_with_areas = true
		var result = space.intersect_point(query)
		for hit in result:
			if hit.collider == plate_area: return true
	return false
