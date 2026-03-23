# food_plate_draggable.gd
extends Node2D

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

# --- SIGNALS FOR GAME MANAGER ---
signal trashed
signal drag_state_changed(is_dragging_now: bool)

# --- Z-INDEX & LAYER CONSTANTS ---
const DRAG_Z_INDEX: int = 4096 
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
var _service_complete_triggered: bool = false 

# --- UNDO HISTORY ---
var placement_history: Array[Node] = []

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
	var a_name = area.name.to_lower()
	var p_name = area.get_parent().name.to_lower()
	
	if a_name.contains("serve") or p_name.contains("serve") or area.is_in_group("serve_zone"):
		is_over_serve_zone = true
		print("DEBUG [Plate]: Entered Serve Zone")
	elif a_name.contains("trash") or p_name.contains("trash") or area.is_in_group("trash_zone"):
		is_over_trash_zone = true
		print("DEBUG [Plate]: Entered Trash Zone")

func _on_area_2d_area_exited(area: Area2D):
	var a_name = area.name.to_lower()
	var p_name = area.get_parent().name.to_lower()
	
	if a_name.contains("serve") or p_name.contains("serve") or area.is_in_group("serve_zone"):
		is_over_serve_zone = false
	elif a_name.contains("trash") or p_name.contains("trash") or area.is_in_group("trash_zone"):
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
		if is_mouse_over_plate_slot(): return 
			
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

	# --- CONTINUOUS SERVICE CHECK ---
	var order_sys = get_node_or_null("/root/OrderSystem")
	if order_sys:
		var is_full_service = order_sys.prepared_plate_contents.size() > 0 and order_sys.prepared_beverage_data.size() > 0
		if is_full_service and not _service_complete_triggered:
			_service_complete_triggered = true
			get_tree().call_group("HUD", "show_finish_button", true)
		elif not is_full_service and _service_complete_triggered:
			_service_complete_triggered = false

func _on_drop():
	# RECOVERY: Do a manual check because signals might have exited as the UI hid
	_manual_zone_recovery()
	
	var plate_contents = get_plate_contents()
	var is_plate_truly_empty = plate_contents.size() == 0
	var handled = false
	
	if is_over_serve_zone:
		handled = true
		if not is_plate_truly_empty and is_instance_valid(GameData):
			GameData.store_plate_contents(plate_contents)
			get_tree().call_group("service_manager", "serve_plate", plate_contents)
			
			# ✨ INSTANT TUTORIAL TRIGGER ✨
			get_tree().call_group("InteractiveTutorial", "action_completed", "Plate_Served")
			
			_animate_new_plate_arrival()
		else:
			is_returning = true
			
	elif is_over_trash_zone:
		handled = true
		if not is_plate_truly_empty:
			if is_instance_valid(GameData):
				GameData.add_money(-5)
			emit_signal("trashed")
			
			# (Optional) Notify tutorial if you ever add a trash step!
			get_tree().call_group("InteractiveTutorial", "action_completed", "Plate_Trashed")
			
			_animate_new_plate_arrival()
		else:
			is_returning = true

	if not handled:
		is_returning = true

# Checks for zones even if signals were missed
func _manual_zone_recovery():
	if not plate_area: return
	var overlapping = plate_area.get_overlapping_areas()
	for area in overlapping:
		var a_name = area.name.to_lower()
		var p_name = area.get_parent().name.to_lower()
		if a_name.contains("serve") or p_name.contains("serve"):
			is_over_serve_zone = true
		if a_name.contains("trash") or p_name.contains("trash"):
			is_over_trash_zone = true

func _animate_new_plate_arrival():
	is_returning = false
	self.z_index = DEFAULT_Z_INDEX
	self.z_as_relative = true
	reset_plate_visuals()
	position = original_local_pos + Vector2(0, 600)
	var tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", original_local_pos, 0.6)

func get_plate_contents() -> Array:
	var contents = []
	for child in get_children():
		if child.is_in_group("plate_slot"):
			if child.get("is_filled") and child.get("item_resource"):
				contents.append({
					"item": child.item_resource,
					"accepted_type": child.slot_type,
					"count": child.get("current_quantity"),
					"portion_type": child.get("current_portion_type")
				})
	return contents

func reset_plate_visuals():
	placement_history.clear() # Clear undo history on reset
	for child in get_children():
		if child.is_in_group("plate_slot") and child.has_method("clear_slot"):
			child.clear_slot()

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

# --- UNDO MECHANIC ---
func record_placement(slot_node: Node):
	placement_history.append(slot_node)

func undo_last_placement():
	if placement_history.size() > 0:
		var last_slot = placement_history.pop_back()
		if is_instance_valid(last_slot) and last_slot.has_method("clear_slot"):
			last_slot.clear_slot()
			
		# Reset the service complete trigger so the Finish button hides if the plate is no longer full
		_service_complete_triggered = false
		get_tree().call_group("HUD", "show_finish_button", false)
