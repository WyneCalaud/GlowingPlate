extends "res://Scripts/Food Data/food_item_base.gd"

@export var milk_data: Resource 

var serve_trash_zone: Node2D = null
var kitchen_area: Node = null
var is_processing_drop: bool = false 

# DEFENSIVE FIX: Allow tutorial manager to toggle this script's specific lock state
var is_tutorial_locked: bool = false 

@onready var area_node: Area2D = $Area2D

func _ready():
	# DEFENSIVE FIX: Dynamically spawned items MUST be in this group to be found by unlock_item()
	add_to_group("interactable")
	
	if milk_data:
		food_data = milk_data

	super._ready()

	if is_instance_valid(area_node):
		area_node.input_pickable = true
		area_node.monitoring = true
		area_node.monitorable = true

	serve_trash_zone = get_tree().root.find_child("ServeOrTrash", true, false)

	# DEFENSIVE FALLBACK: Check service_manager, then InteractiveTutorial
	kitchen_area = get_tree().get_first_node_in_group("service_manager")
	if not is_instance_valid(kitchen_area):
		kitchen_area = get_tree().get_first_node_in_group("InteractiveTutorial")

# ---------------------------------------------------------
# DRAG
# ---------------------------------------------------------

func start_dragging():
	# DEFENSIVE GUARD: Prevent dragging if locked by the tutorial or currently dropping
	if is_processing_drop or is_tutorial_locked: return

	super.start_dragging()
	z_index = 100

	if is_instance_valid(area_node):
		area_node.collision_mask = 2

	var cam = get_tree().get_first_node_in_group("MainCamera")
	if is_instance_valid(cam):
		cam.is_input_blocked = true
		
	# --- TUTORIAL SUPPORT ---
	if get_tree().get_node_count_in_group("InteractiveTutorial") > 0:
		get_tree().call_group("InteractiveTutorial", "action_completed", "MilkCarton_Dragged")

	# Defensively move zones near beverage
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

	is_processing_drop = true
	z_index = 20

	var cam = get_tree().get_first_node_in_group("MainCamera")
	if is_instance_valid(cam):
		cam.is_input_blocked = false

	_perform_manual_overlap_check()

	if is_instance_valid(area_node):
		area_node.collision_mask = 1

	super.handle_drop()

func return_to_start():
	is_processing_drop = false
	super.return_to_start()

# ---------------------------------------------------------
# ZONE DETECTION
# ---------------------------------------------------------

func _perform_manual_overlap_check():
	if not is_instance_valid(area_node): return

	var overlapping = area_node.get_overlapping_areas()

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
	var gd := get_tree().get_first_node_in_group("GameData")

	if is_instance_valid(gd) and milk_data:
		if gd.has_method("add_prepared_beverage"):
			gd.add_prepared_beverage(milk_data)

	# Defensively Call Serve
	if get_tree().get_node_count_in_group("InteractiveTutorial") > 0:
		get_tree().call_group("InteractiveTutorial", "action_completed", "MilkCarton_Served")
	else:
		get_tree().call_group("service_manager", "serve_beverage")

	if is_instance_valid(kitchen_area) and kitchen_area.has_method("hide_drop_zones"):
		kitchen_area.hide_drop_zones()

	_notify_parent_of_removal()
	queue_free()

func on_trash_item():
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
