extends Area2D

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

@export var item_resource: Resource = null 
@export var is_filled: bool = false
@export var linked_image: Sprite2D 
@export var plated_scale_factor: float = 0.4
@export var slot_type: String = "Go" 

# --- Custom Transform Variables ---
@export_group("Placement Tweaks")
@export var rice_position_offset: Vector2 = Vector2.ZERO
@export var rice_rotation_offset: float = 0.0
@export var rice_scale_factor: float = 0.4

# --- Stacking & Portion Variables ---
var current_quantity: int = 0
var current_portion_type: String = "" 
var current_rice_amount: String = ""  
const MAX_QUANTITY: int = 3 

var base_image_position: Vector2
var base_image_rotation: float

signal slot_updated(resource, filled)

func _ready():
	self.input_pickable = true
	add_to_group(&"plate_slot")
	
	if linked_image:
		base_image_position = linked_image.position
		base_image_rotation = linked_image.rotation_degrees
		linked_image.visible = false
	else:
		print("[PlateSlot DEBUG] WARNING: No linked_image assigned to ", self.name)

func _input(event: InputEvent) -> void:
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		if _is_pos_inside(get_global_mouse_position()):
			print("\n[PlateSlot DEBUG] --- 1. SLOT CLICKED: ", self.name, " ---")
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
		print("[PlateSlot DEBUG] 2. No dispenser selected, aborting.")
		return

	var selected = FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER
	print("[PlateSlot DEBUG] 3. Dispenser found: ", selected.name)
	
	if is_filled:
		print("[PlateSlot DEBUG] 3a. Slot already filled, checking if we can stack...")
		var data_to_check = selected.get("food_data") if "food_data" in selected else selected.get("item_resource")
		var current_name = item_resource.get("item_name") if item_resource else ""
		var incoming_name = data_to_check.get("item_name") if data_to_check else ""
		
		if current_name != incoming_name:
			print("[PlateSlot DEBUG] 3b. Names don't match, aborting.")
			return 
		
		var incoming_portion = selected.get("portion_type") if "portion_type" in selected else ""
		if incoming_portion != "" and incoming_portion != current_portion_type:
			print("[PlateSlot DEBUG] 3c. Portions don't match, aborting.")
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
	
	# Shallow copy safely creates a new data object but shares the textures.
	incoming_resource = incoming_resource.duplicate()
	
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
		current_rice_amount = rice_amount
		_update_visuals(incoming_initial_texture)
	else:
		# FIX: Prevent rice from stacking to avoid disappearing textures and bugs
		if rice_amount != "":
			print("⚠️ Cannot stack rice!")
			return false
			
		current_quantity += 1
		_update_stacking_visuals()

	emit_signal("slot_updated", item_resource, is_filled)
	return true

func _update_stacking_visuals():
	print("[PlateSlot DEBUG] 8a. Determining next stacked texture...")
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
	else:
		print("[PlateSlot DEBUG] 8b. WARNING: Stacked texture is null!")

func _update_visuals(tex: Texture2D):
	if not linked_image:
		print("[PlateSlot DEBUG] 9. ERROR: linked_image is missing!")
		return
		
	print("[PlateSlot DEBUG] 9. Applying texture: ", tex)
	linked_image.texture = tex
	
	if item_resource and item_resource.has_meta("RiceAmount"):
		print("[PlateSlot DEBUG] 9a. Applying Rice transforms...")
		linked_image.position = base_image_position + rice_position_offset
		linked_image.rotation_degrees = base_image_rotation + rice_rotation_offset
		linked_image.scale = Vector2(rice_scale_factor, rice_scale_factor)
	else:
		print("[PlateSlot DEBUG] 9b. Applying Standard transforms...")
		linked_image.position = base_image_position
		linked_image.rotation_degrees = base_image_rotation
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
	
	# FIX: Explicitly reject an empty rice cup so it doesn't place a blank texture
	if rice_amt == "Empty":
		print("[PlateSlot] Rejected empty rice cup.")
		return {}

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

	if not final_texture: 
		print("[PlateSlot DEBUG] 5b. ERROR: Could not resolve a final texture.")
		return {}
		
	return { 
		"food_resource": food_resource, 
		"final_texture": final_texture,
		"portion_type": portion,
		"rice_amount": rice_amt
	}

func clear_slot():
	print("[PlateSlot DEBUG] Clearing slot...")
	is_filled = false
	item_resource = null
	current_quantity = 0
	current_portion_type = ""
	current_rice_amount = ""
	if linked_image:
		linked_image.texture = null
		linked_image.visible = false
	emit_signal("slot_updated", item_resource, is_filled)
