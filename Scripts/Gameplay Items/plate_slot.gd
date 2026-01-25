extends Area2D

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

@export var item_resource: Resource = null 
@export var is_filled: bool = false
@export var linked_image: Sprite2D 
@export var plated_scale_factor: float = 0.4
@export var slot_type: String = "Go" 

signal slot_updated(resource, filled)

func _ready():
	# Crucial: Enable pickable and set the filter
	self.input_pickable = true
	add_to_group(&"plate_slot")
	
	if linked_image:
		linked_image.visible = false
	
	# Connect the standard input event which is more reliable than manual checks
	if not is_connected("input_event", _on_input_event):
		connect("input_event", _on_input_event)

# Use the built-in signal for perfect collision detection
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		_process_placement_attempt()

# We keep _unhandled_input as a fallback, but corrected the math
func _unhandled_input(event: InputEvent) -> void:
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		if _is_pos_inside(get_global_mouse_position()):
			_process_placement_attempt()

func _is_pos_inside(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	for child in get_children():
		if child is CollisionShape2D:
			# Subtracting child.position was the error. 
			# We must check against the shape's rect offset by the child's local position.
			if child.shape:
				var rect = child.shape.get_rect()
				rect.position += child.position # Offset the rect by the node's position
				if rect.has_point(local_pos):
					return true
		elif child is CollisionPolygon2D:
			# For polygons, we must offset every point by the child's position
			var offset_polygon = []
			for point in child.polygon:
				offset_polygon.append(point + child.position)
			if Geometry2D.is_point_in_polygon(local_pos, offset_polygon):
				return true
	return false

func _process_placement_attempt():
	if not is_filled and FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER != null:
		var selected = FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER
		
		# Validate data
		var data_to_check = selected.get("food_data") if "food_data" in selected else selected.get("item_resource")
		if data_to_check == null:
			return

		var success = try_place_food(selected)
		if success:
			if selected.has_method("deselect"):
				selected.deselect()
			# Consume the event so it doesn't click things behind the plate
			get_viewport().set_input_as_handled()

func try_place_food(incoming_data: Variant) -> bool:
	if is_filled: return false
	
	var placement_results = _get_placement_data(incoming_data)
	if placement_results.is_empty(): return false
	
	var food_resource = placement_results.food_resource
	var final_texture = placement_results.final_texture
	
	# Category validation
	if food_resource.get("food_category") != slot_type:
		print("⚠️ Misplaced item: ", food_resource.get("food_category"), " vs ", slot_type)

	item_resource = food_resource
	is_filled = true
	linked_image.texture = final_texture
	linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor)
	linked_image.visible = true
	
	emit_signal("slot_updated", item_resource, is_filled)
	return true

func _get_placement_data(incoming_data: Variant) -> Dictionary:
	var food_resource: Resource = null
	var final_texture: Texture2D = null
	
	if incoming_data is Resource:
		food_resource = incoming_data
	elif incoming_data is Node:
		if "food_data" in incoming_data:
			food_resource = incoming_data.food_data
		elif "item_resource" in incoming_data:
			food_resource = incoming_data.item_resource
	
	if not food_resource: return {}

	var amount = incoming_data.get("current_rice_amount") if incoming_data is Node else null
	
	if amount == "Small" and food_resource.get("plated_texture_small"):
		final_texture = food_resource.plated_texture_small
	elif amount == "Medium" and food_resource.get("plated_texture_medium"):
		final_texture = food_resource.plated_texture_medium
	elif amount == "TooHigh" and food_resource.get("plated_texture_too_high"):
		final_texture = food_resource.plated_texture_too_high
	else:
		if "default_plated_texture" in food_resource and food_resource.default_plated_texture:
			final_texture = food_resource.default_plated_texture
		else:
			final_texture = food_resource.base_texture

	if not final_texture: return {}
		
	return { "food_resource": food_resource, "final_texture": final_texture }

func clear_slot():
	is_filled = false
	item_resource = null
	if linked_image:
		linked_image.texture = null
		linked_image.visible = false
	emit_signal("slot_updated", item_resource, is_filled)
