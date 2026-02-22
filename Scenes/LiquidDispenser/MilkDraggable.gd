extends "res://Scripts/Food Data/food_item_base.gd"

@export var milk_data: Resource 

var serve_trash_zone: Node2D = null
var kitchen_area: Node = null
var is_processing_drop: bool = false 
@onready var area_node: Area2D = $Area2D


func _ready():
	if milk_data:
		food_data = milk_data

	super._ready()

	if area_node:
		area_node.input_pickable = true
		area_node.monitoring = true
		area_node.monitorable = true

	# Keep original node lookup
	serve_trash_zone = get_tree().root.find_child("ServeOrTrash", true, false)

	# Get KitchenArea (service_manager)
	kitchen_area = get_tree().get_first_node_in_group("service_manager")


# ---------------------------------------------------------
# DRAG
# ---------------------------------------------------------

func start_dragging():
	if is_processing_drop:
		return

	super.start_dragging()
	z_index = 100

	# CRITICAL (original behavior)
	if area_node:
		area_node.collision_mask = 2

	var cam = get_tree().get_first_node_in_group("MainCamera")
	if cam:
		cam.is_input_blocked = true

	# Move zones near beverage but DO NOT break original system
	if kitchen_area:
		kitchen_area.move_zones_to_beverage(1240.0)
		kitchen_area.show_drop_zones()


# ---------------------------------------------------------
# DROP
# ---------------------------------------------------------

func handle_drop():
	if is_processing_drop:
		return

	is_processing_drop = true
	z_index = 20

	var cam = get_tree().get_first_node_in_group("MainCamera")
	if cam:
		cam.is_input_blocked = false

	# KEEP original manual detection
	_perform_manual_overlap_check()

	# Restore collision mask
	if area_node:
		area_node.collision_mask = 1

	# Let base class handle zone routing
	super.handle_drop()


func return_to_start():
	is_processing_drop = false
	super.return_to_start()


# ---------------------------------------------------------
# ZONE DETECTION (ORIGINAL LOGIC RESTORED)
# ---------------------------------------------------------

func _perform_manual_overlap_check():
	if not area_node:
		return

	var overlapping = area_node.get_overlapping_areas()

	for area in overlapping:
		if area.owner == self or area.get_parent() == self:
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
	if current_hovered_area:
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

	if gd and milk_data:
		gd.add_prepared_beverage(milk_data)

	get_tree().call_group("service_manager", "serve_beverage")

	# Reset zones after serve
	if kitchen_area:
		kitchen_area.hide_drop_zones()

	_notify_parent_of_removal()
	queue_free()


func on_trash_item():
	if kitchen_area:
		kitchen_area.hide_drop_zones()

	_notify_parent_of_removal()
	queue_free()


func _notify_parent_of_removal():
	var parent = get_parent()
	if parent:
		if parent.has_method("clear_milk"):
			parent.clear_milk()
		elif "is_occupied" in parent:
			parent.is_occupied = false
