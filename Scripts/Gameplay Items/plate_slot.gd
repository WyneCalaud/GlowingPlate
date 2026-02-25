extends Area2D

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

@export var item_resource: Resource = null 
@export var is_filled: bool = false
@export var linked_image: Sprite2D 
@export var plated_scale_factor: float = 0.4
@export var slot_type: String = "Go" 

# --- Stacking & Portion Variables ---
var current_quantity: int = 0
var current_portion_type: String = "" # Stores "Half", "Whole", "VeggieFull" or ""
const MAX_QUANTITY: int = 3 

signal slot_updated(resource, filled)

func _ready():
	self.input_pickable = true
	add_to_group(&"plate_slot")
	
	if linked_image:
		linked_image.visible = false

func _input(event: InputEvent) -> void:
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		if _is_pos_inside(get_global_mouse_position()):
			_process_placement_attempt()

func _is_pos_inside(global_pos: Vector2) -> bool:
	var local_pos = to_local(global_pos)
	for child in get_children():
		if child is CollisionShape2D:
			if child.shape:
				var rect = child.shape.get_rect()
				rect.position += child.position 
				if rect.has_point(local_pos):
					return true
		elif child is CollisionPolygon2D:
			var offset_polygon = []
			for point in child.polygon:
				offset_polygon.append(point + child.position)
			if Geometry2D.is_point_in_polygon(local_pos, offset_polygon):
				return true
	return false

func _process_placement_attempt():
	if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER == null:
		return

	var selected = FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER
	
	if is_filled:
		var data_to_check = selected.get("food_data") if "food_data" in selected else selected.get("item_resource")
		var current_name = item_resource.get("item_name") if item_resource else ""
		var incoming_name = data_to_check.get("item_name") if data_to_check else ""
		
		if current_name != incoming_name:
			return 
		
		var incoming_portion = selected.get("portion_type") if "portion_type" in selected else ""
		if incoming_portion != "" and incoming_portion != current_portion_type:
			return

		if current_quantity >= MAX_QUANTITY:
			return 

	var success = try_place_food(selected)
	if success:
		if selected.has_method("deselect"):
			selected.deselect()
		get_tree().call_group("portion_selector", "_close_selector")
		get_tree().call_group("veggie_cup_ui", "_close_ui") 
		get_viewport().set_input_as_handled()

func try_place_food(incoming_data: Variant) -> bool:
	var placement_results = _get_placement_data(incoming_data)
	if placement_results.is_empty(): 
		return false
	
	var incoming_resource = placement_results.food_resource
	var incoming_initial_texture = placement_results.final_texture
	var incoming_portion = placement_results.portion_type
	var rice_amount = placement_results.get("rice_amount", "")
	
	# CRITICAL: Always duplicate to ensure metadata doesn't leak back to the dispenser
	incoming_resource = incoming_resource.duplicate(true)
	
	# Bake metadata into the resource so LobbyCanteen/OrderSystem can see it
	if incoming_portion != "":
		incoming_resource.set_meta("Portion", incoming_portion)
	if rice_amount != "":
		incoming_resource.set_meta("RiceAmount", rice_amount)
	
	if not is_filled:
		if incoming_resource.get("food_category") != slot_type:
			print("⚠️ Misplaced item category")

		item_resource = incoming_resource
		is_filled = true
		current_quantity = 1
		current_portion_type = incoming_portion
		_update_visuals(incoming_initial_texture)
	else:
		current_quantity += 1
		_update_stacking_visuals()

	emit_signal("slot_updated", item_resource, is_filled)
	return true

func _update_stacking_visuals():
	if not item_resource: return
	if item_resource.get("is_veggie_cup"): return

	var next_texture = null
	if current_portion_type == "Half":
		match current_quantity:
			1: next_texture = item_resource.get("plated_texture_half")
			2: next_texture = item_resource.get("plated_texture_half_2")
			3: next_texture = item_resource.get("plated_texture_half_3")
	elif current_portion_type == "Whole":
		match current_quantity:
			1: next_texture = item_resource.get("plated_texture_whole")
			2: next_texture = item_resource.get("plated_texture_whole_2")
			3: next_texture = item_resource.get("plated_texture_whole_3")
	else:
		match current_quantity:
			1: next_texture = item_resource.get("texture_count_1")
			2: next_texture = item_resource.get("texture_count_2")
			3: next_texture = item_resource.get("texture_count_3")
	
	if next_texture:
		_update_visuals(next_texture)

func _update_visuals(tex: Texture2D):
	linked_image.texture = tex
	linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor)
	linked_image.visible = true

func _get_placement_data(incoming_data: Variant) -> Dictionary:
	var food_resource: Resource = null
	var final_texture: Texture2D = null
	var portion = ""
	var rice_amt = ""
	
	if incoming_data is Resource:
		food_resource = incoming_data
	elif incoming_data is Node:
		food_resource = incoming_data.get("food_data") if "food_data" in incoming_data else incoming_data.get("item_resource")
		portion = incoming_data.get("portion_type") if "portion_type" in incoming_data else ""
		rice_amt = incoming_data.get("current_rice_amount") if "current_rice_amount" in incoming_data else ""
	
	if not food_resource: return {}

	if food_resource.get("is_veggie_cup"):
		if portion == "VeggieFull":
			final_texture = food_resource.veggie_plated_full
		elif portion == "VeggieHigh":
			final_texture = food_resource.veggie_plated_high
		elif portion == "VeggieMed":
			final_texture = food_resource.veggie_plated_med
		elif portion == "VeggieLow":
			final_texture = food_resource.veggie_plated_low
	elif portion == "Half":
		final_texture = food_resource.plated_texture_half
	elif portion == "Whole":
		final_texture = food_resource.plated_texture_whole
	elif rice_amt != "":
		match rice_amt:
			"Small": final_texture = food_resource.plated_texture_small
			"Medium": final_texture = food_resource.plated_texture_medium
			"TooHigh": final_texture = food_resource.plated_texture_too_high
			"RightAmount": final_texture = food_resource.default_plated_texture

	if not final_texture:
		final_texture = food_resource.texture_count_1 if food_resource.get("texture_count_1") else food_resource.default_plated_texture

	if not final_texture: return {}
		
	return { 
		"food_resource": food_resource, 
		"final_texture": final_texture,
		"portion_type": portion,
		"rice_amount": rice_amt
	}

func clear_slot():
	is_filled = false
	item_resource = null
	current_quantity = 0
	current_portion_type = ""
	if linked_image:
		linked_image.texture = null
		linked_image.visible = false
	emit_signal("slot_updated", item_resource, is_filled)
