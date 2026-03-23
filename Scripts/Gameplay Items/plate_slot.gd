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
const MAX_QUANTITY: int = 4 # UPDATED: Increased to 4

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
		print("[PlateSlot DEBUG] ⚠️ WARNING: No linked_image assigned to ", self.name)

func _input(event: InputEvent) -> void:
	var is_click = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	var is_touch = event is InputEventScreenTouch and event.pressed
	
	if is_click or is_touch:
		if _is_pos_inside(get_global_mouse_position()):
			print("\n[PlateSlot] 👆 SLOT CLICKED: ", self.name)
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
			print("[PlateSlot] ❌ Mismatch: Slot has ", current_name, ", tried to place ", incoming_name)
			return 
		
		var incoming_portion = selected.get("portion_type") if "portion_type" in selected else ""
		if incoming_portion != "" and incoming_portion != current_portion_type:
			print("[PlateSlot] ❌ Portion Mismatch: Slot has ", current_portion_type, ", tried to place ", incoming_portion)
			return

		if current_quantity >= MAX_QUANTITY:
			print("[PlateSlot] ⚠️ Slot is full! Max quantity reached (", MAX_QUANTITY, ")")
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
	
	incoming_resource = incoming_resource.duplicate()
	
	if incoming_portion != "":
		incoming_resource.set_meta("Portion", incoming_portion)
	if rice_amount != "":
		incoming_resource.set_meta("RiceAmount", rice_amount)
	
	if not is_filled:
		item_resource = incoming_resource
		is_filled = true
		current_quantity = 1
		current_portion_type = incoming_portion
		current_rice_amount = rice_amount
		_update_visuals(incoming_initial_texture)
		
		# --- SAFELY GET ITEM NAME ---
		var raw_item_name = ""
		if incoming_resource:
			if incoming_resource.get("item_name") != null:
				raw_item_name = str(incoming_resource.get("item_name"))
			else:
				# Fallback: grabs the filename
				raw_item_name = incoming_resource.resource_path.get_file().get_basename()
				
		var item_name_lower = raw_item_name.to_lower()
		var slot_type_lower = str(slot_type).to_lower()
		var node_name_lower = str(name).to_lower()
		var is_veggie = incoming_resource.get("is_veggie_cup") if incoming_resource and incoming_resource.get("is_veggie_cup") != null else false
		
		# --- ENHANCED DEBUG PRINT TO HELP DIAGNOSE ---
		print("\n=========================================================")
		print(" 🍽️ [PLATE SLOT DEBUG] ITEM PLACED ")
		print("=========================================================")
		print(" 📍 Node Name:       ", name)
		print(" 🏷️ Slot Type:       ", slot_type)
		print(" 🍎 Item Placed:     ", raw_item_name)
		print(" 📏 Portion/Amount:  ", incoming_portion if incoming_portion != "" else "N/A")
		print(" 🍚 Rice Amount:     ", rice_amount if rice_amount != "" else "N/A")
		print(" 🥗 Is Veggie Cup?   ", "Yes" if is_veggie else "No")
		print("---------------------------------------------------------")
		print(" 🔍 [TUTORIAL TRIGGER CHECKS] ")
		
		# =========================================================
		# TUTORIAL FIX: Trigger step when Full Rice goes in GoSlot
		# =========================================================
		var is_go_slot = (slot_type_lower == "go" or node_name_lower.contains("goslot") or node_name_lower.contains("go_slot"))
		var is_rice = (item_name_lower.contains("rice") or rice_amount == "RightAmount")
		
		print("   -> 🍚 Checking GoSlot + Rice:")
		print("      | is_go_slot: ", is_go_slot, " | is_rice: ", is_rice)
		
		if is_go_slot and is_rice:
			print("      ✅ MATCH! Triggering: Rice_In_GoSlot")
			get_tree().call_group("InteractiveTutorial", "action_completed", "Rice_In_GoSlot")
		
		# =========================================================
		# TUTORIAL FIX: Trigger step when Mango goes in GlowFruitSlot
		# =========================================================
		var is_glow_fruit_slot = (slot_type_lower.contains("glowfru") or node_name_lower.contains("glowfru") or (node_name_lower.contains("glow") and node_name_lower.contains("fru")))
		var is_mango = item_name_lower.contains("mango")
		
		print("   -> 🥭 Checking GlowFruitSlot + Mango:")
		print("      | is_glow_fruit_slot: ", is_glow_fruit_slot, " | is_mango: ", is_mango)
		
		if is_glow_fruit_slot and is_mango:
			print("      ✅ MATCH! Triggering: Mango_In_GlowFruitSlot")
			get_tree().call_group("InteractiveTutorial", "action_completed", "Mango_In_GlowFruitSlot")
			
		# =========================================================
		# TUTORIAL FIX: Trigger step when Full Veggie Cup goes in GlowVegSlot
		# =========================================================
		var is_glow_veg_slot = (slot_type_lower.contains("glowveg") or node_name_lower.contains("glowveg") or (node_name_lower.contains("glow") and node_name_lower.contains("veg")))
		
		print("   -> 🥗 Checking GlowVegSlot + Veggie Cup:")
		print("      | is_glow_veg_slot: ", is_glow_veg_slot, " | is_veggie: ", is_veggie)
		
		if is_glow_veg_slot and is_veggie:
			if incoming_portion == "VeggieFull":
				print("      ✅ MATCH! Placed VeggieFull! Triggering: FullCupVeggie_In_GlowVegSlot")
				get_tree().call_group("InteractiveTutorial", "action_completed", "FullCupVeggie_In_GlowVegSlot")
			else:
				print("      ❌ MISMATCH! Placed portion was '", incoming_portion, "', expected 'VeggieFull'.")
				print("      🔄 Resetting slot and showing Veggie Retry Overlay...")
				# Call the retry visual in the tutorial script
				get_tree().call_group("InteractiveTutorial", "trigger_veggie_retry")
				# Reset the plate slot immediately
				clear_slot()
				print("=========================================================\n")
				# Return true so the item gets removed from the player's cursor
				return true 
				
		# =========================================================
		# TUTORIAL FIX: Trigger step when Chicken goes in GrowSlot
		# =========================================================
		var is_grow_slot = (slot_type_lower.contains("grow") or node_name_lower.contains("grow"))
		var is_chicken = item_name_lower.contains("chicken")
		
		print("   -> 🍗 Checking GrowSlot + Chicken:")
		print("      | is_grow_slot: ", is_grow_slot, " | is_chicken: ", is_chicken)
		
		if is_grow_slot and is_chicken:
			print("      ✅ MATCH! Triggering: Chicken_In_GrowSlot")
			get_tree().call_group("InteractiveTutorial", "action_completed", "Chicken_In_GrowSlot")
				
		print("=========================================================\n")
		# =========================================================
			
	else:
		if rice_amount != "":
			print("[PlateSlot] ❌ Cannot stack rice!")
			return false
			
		current_quantity += 1
		print("[PlateSlot] 🥞 Stacked item. New quantity: ", current_quantity)
		_update_stacking_visuals()

	emit_signal("slot_updated", item_resource, is_filled)
	get_parent().record_placement(self)
	
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
			4: next_texture = item_resource.get("plated_texture_half_4") 
	elif current_portion_type == "Whole":
		match current_quantity:
			1: next_texture = item_resource.get("plated_texture_whole")
			2: next_texture = item_resource.get("plated_texture_whole_2")
			3: next_texture = item_resource.get("plated_texture_whole_3")
			4: next_texture = item_resource.get("plated_texture_whole_4") 
	else:
		match current_quantity:
			1: next_texture = item_resource.get("texture_count_1")
			2: next_texture = item_resource.get("texture_count_2")
			3: next_texture = item_resource.get("texture_count_3")
			4: next_texture = item_resource.get("texture_count_4")
	
	if next_texture:
		_update_visuals(next_texture)

func _update_visuals(tex: Texture2D):
	if not linked_image:
		return
		
	linked_image.texture = tex
	
	if item_resource and item_resource.has_meta("RiceAmount"):
		linked_image.position = base_image_position + rice_position_offset
		linked_image.rotation_degrees = base_image_rotation + rice_rotation_offset
		linked_image.scale = Vector2(rice_scale_factor, rice_scale_factor)
	else:
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
	if rice_amt == "Empty": return {}

	if food_resource.get("is_veggie_cup"):
		if portion == "VeggieFull": final_texture = food_resource.veggie_plated_full
		elif portion == "VeggieHigh": final_texture = food_resource.veggie_plated_high
		elif portion == "VeggieMed": final_texture = food_resource.veggie_plated_med
		elif portion == "VeggieLow": final_texture = food_resource.veggie_plated_low
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
	current_rice_amount = ""
	if linked_image:
		linked_image.texture = null
		linked_image.visible = false
	emit_signal("slot_updated", item_resource, is_filled)
