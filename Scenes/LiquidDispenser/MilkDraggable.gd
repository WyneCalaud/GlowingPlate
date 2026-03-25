extends "res://Scripts/Food Data/food_item_base.gd"

@export var milk_data: Resource 

var serve_trash_zone: Node2D = null
var kitchen_area: Node = null
var is_processing_drop: bool = false 
var is_being_dragged: bool = false

# DEFENSIVE FIX: Allow tutorial manager to toggle this script's specific lock state
var is_tutorial_locked: bool = false 

@onready var area_node: Area2D = $Area2D

func _ready():
	self.name = "Milk"
	add_to_group("interactable")
	
	# DEFENSIVE: Run even if the tutorial paused the SceneTree
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if milk_data:
		food_data = milk_data

	super._ready()

	if "mouse_filter" in self:
		self.set("mouse_filter", 2) 

	if is_instance_valid(area_node):
		area_node.input_pickable = true
		area_node.monitoring = true
		area_node.monitorable = true
		
		if not area_node.input_event.is_connected(_on_area_node_input_event):
			area_node.input_event.connect(_on_area_node_input_event)

	serve_trash_zone = get_tree().root.find_child("ServeOrTrash", true, false)

	kitchen_area = get_tree().get_first_node_in_group("service_manager")
	if not is_instance_valid(kitchen_area):
		kitchen_area = get_tree().get_first_node_in_group("InteractiveTutorial")

# DEFENSIVE HELPER: Check if tutorial is actually active
func is_in_tutorial() -> bool:
	if not is_inside_tree(): return false
	return get_tree().get_node_count_in_group("InteractiveTutorial") > 0

# ---------------------------------------------------------
# DEBUG & INPUT (WITH BRUTE FORCE FALLBACK)
# ---------------------------------------------------------

func _on_area_node_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	# Standard Area2D detection
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_attempt_drag("Area2D")

# DEFENSIVE: Brute-force input detection. Bypasses UI blockers entirely.
func _input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# Check distance from mouse to milk (60 pixels is a safe click radius)
			var dist = get_global_mouse_position().distance_to(global_position)
			if dist < 60.0 and not is_being_dragged:
				_attempt_drag("Global _input (Distance: " + str(dist) + ")")
		else:
			if is_being_dragged:
				print("[DEBUG-MILK] Global Mouse Release Detected - Forcing Drop!")
				handle_drop()

func _attempt_drag(source: String):
	print("[DEBUG-MILK] Click detected via: ", source)
	
	# DEFENSIVE FIX: Prevent tutorial lock from leaking into normal gameplay
	if not is_in_tutorial():
		is_tutorial_locked = false
	
	var base_locked = false
	if "is_locked" in self:
		base_locked = self.get("is_locked")

	print("[DEBUG-MILK] Status -> is_tutorial_locked: ", is_tutorial_locked, " | base_is_locked: ", base_locked, " | is_processing_drop: ", is_processing_drop)

	if is_tutorial_locked or base_locked:
		print("[DEBUG-MILK] DRAG BLOCKED: Item is locked by tutorial.")
		return
	if is_processing_drop:
		print("[DEBUG-MILK] DRAG BLOCKED: Currently dropping.")
		return

	start_dragging()

# DEFENSIVE: Force position update if base script is failing to move it
func _process(_delta):
	if is_being_dragged:
		global_position = get_global_mouse_position()

# ---------------------------------------------------------
# DRAG
# ---------------------------------------------------------

func start_dragging():
	print("[DEBUG-MILK] Drag Started Successfully!")
	is_being_dragged = true
	super.start_dragging()
	z_index = 100

	if is_instance_valid(area_node):
		area_node.collision_mask = 2

	var cam = get_tree().get_first_node_in_group("MainCamera")
	if is_instance_valid(cam):
		if "is_input_blocked" in cam:
			cam.is_input_blocked = true
		else:
			print("[DEBUG-MILK] Warning: Camera does not have 'is_input_blocked' property.")
		
	if is_in_tutorial():
		get_tree().call_group("InteractiveTutorial", "action_completed", "Milk_Dragged")

	if is_instance_valid(kitchen_area):
		if kitchen_area.has_method("move_zones_to_beverage"):
			kitchen_area.move_zones_to_beverage(1240.0)
		if kitchen_area.has_method("show_drop_zones"):
			kitchen_area.show_drop_zones()

# ---------------------------------------------------------
# DROP
# ---------------------------------------------------------

func handle_drop():
	if is_processing_drop: return

	print("[DEBUG-MILK] Dropped!")
	is_processing_drop = true
	is_being_dragged = false
	z_index = 20

	var cam = get_tree().get_first_node_in_group("MainCamera")
	if is_instance_valid(cam):
		if "is_input_blocked" in cam:
			cam.is_input_blocked = false

	_perform_manual_overlap_check()

	if is_instance_valid(area_node):
		area_node.collision_mask = 1

	super.handle_drop()

func return_to_start():
	print("[DEBUG-MILK] Returning to start.")
	is_processing_drop = false
	is_being_dragged = false
	super.return_to_start()

# ---------------------------------------------------------
# ZONE DETECTION
# ---------------------------------------------------------

func _perform_manual_overlap_check():
	if not is_instance_valid(area_node): return

	var overlapping = area_node.get_overlapping_areas()
	print("[DEBUG-MILK] Overlapping areas on drop: ", overlapping.size())

	for area in overlapping:
		if not is_instance_valid(area) or area.owner == self or area.get_parent() == self:
			continue

		var a_name = area.name.to_lower()
		var p_name = area.get_parent().name.to_lower()

		if a_name.contains("serve") or p_name.contains("serve"):
			current_hovered_area = area
			break

		if a_name.contains("trash") or p_name.contains("trash"):
			current_hovered_area = area
			break

func on_unique_drop_zone_check():
	if is_instance_valid(current_hovered_area):
		var a_name = current_hovered_area.name.to_lower()
		var p_name = current_hovered_area.get_parent().name.to_lower()

		if a_name.contains("serve") or p_name.contains("serve"):
			on_serve_success()
			return

		if a_name.contains("trash") or p_name.contains("trash"):
			on_trash_item()
			return

	return_to_start()

# ---------------------------------------------------------
# RESULTS
# ---------------------------------------------------------

func on_serve_success():
	print("[DEBUG-MILK] Served!")
	
	# DEFENSIVE FIX: Directly access the GameData autoload path instead of a group to ensure it updates the Tray
	var gd = null
	if has_node("/root/GameData"):
		gd = get_node("/root/GameData")

	if is_instance_valid(gd) and milk_data:
		if gd.has_method("add_prepared_beverage"):
			gd.add_prepared_beverage(milk_data)

	if is_in_tutorial():
		get_tree().call_group("InteractiveTutorial", "action_completed", "Milk_Served")
	else:
		get_tree().call_group("service_manager", "serve_beverage")

	if is_instance_valid(kitchen_area) and kitchen_area.has_method("hide_drop_zones"):
		kitchen_area.hide_drop_zones()

	_notify_parent_of_removal()
	queue_free()

func on_trash_item():
	print("[DEBUG-MILK] Trashed!")
	if is_instance_valid(kitchen_area) and kitchen_area.has_method("hide_drop_zones"):
		kitchen_area.hide_drop_zones()

	_notify_parent_of_removal()
	queue_free()

func _notify_parent_of_removal():
	var parent = get_parent()
	if is_instance_valid(parent):
		if parent.has_method("clear_milk"):
			parent.clear_milk()
		elif "is_occupied" in parent:
			parent.is_occupied = false
