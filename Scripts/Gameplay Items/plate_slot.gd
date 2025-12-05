extends Area2D

# --- IMPORT DISPENSER REFERENCE ---
const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

# --- EXPORTED PROPERTIES (Data Storage) ---
# CRITICAL: These properties are read by the parent `main_plate.gd`
@export var item_resource: Resource = null # The .tres file is stored here
@export var is_filled: bool = false
@export var linked_image: Sprite2D # The sprite that shows the food on the plate
@export var plated_scale_factor: float = 0.4

# --- SIGNAL ---
# This signal notifies the parent plate when data changes (placement or clear)
signal slot_updated(resource, filled)

# --- CACHE ---
var original_position: Vector2

# --- INITIALIZATION ---
func _ready():
	self.input_pickable = true
	# Ensure the slot is in a group so the plate can find all slots easily.
	add_to_group(&"plate_slot")
	
	if linked_image == null:
		print("FATAL ERROR [Plate Slot]: 'linked_image' Sprite2D is NOT assigned in the Inspector!")
	else:
		linked_image.visible = false
	
	original_position = global_position
	
	# Connect to handle click-to-place logic on this slot area
	if not self.is_connected("input_event", Callable(self, "_on_input_event")):
		self.connect("input_event", Callable(self, "_on_input_event"))

# --- INPUT HANDLER (Click-to-Place Only) ---
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	
	# Only react to the press event
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventScreenTouch and event.is_pressed()):
		
		# --- 1. Click-to-Place (If not filled) ---
		if not is_filled and FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER != null:
			
			var selected_dispenser = FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER
			var food_resource = selected_dispenser.food_data
			
			if food_resource and not is_filled:
				var success = try_place_food(food_resource)
				if success:
					selected_dispenser.toggle_selection()
				get_viewport().set_input_as_handled()

# --- CORE PLACEMENT FUNCTION (For Click-to-Place and Rice Drop) ---
# Incoming data can be a Resource (for dispenser click) or the food item Node itself (for drag/drop)
func try_place_food(incoming_data: Variant) -> bool:
	if is_filled: return false
	
	var placement_data = _get_placement_data(incoming_data)
	if placement_data == null:
		print("Placement failed: Invalid food data.")
		return false
	
	var food_resource = placement_data.food_resource
	var final_texture = placement_data.final_texture
	var amount = placement_data.amount
	
	if final_texture == null:
		print("ERROR [Plate Slot]: Final texture is null for %s." % food_resource.get("item_name"))
		return false
	
	# CRITICAL: SET is_filled = true
	is_filled = true
	item_resource = food_resource # Set the resource!
	
	# --- DEBUG: CHECK IF RESOURCE WAS SET ---
	if item_resource == null:
		print("FATAL DEBUG [Plate Slot]: item_resource is NULL immediately after placement!")
	
	linked_image.texture = final_texture
	linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor)
	linked_image.visible = true
	
	print("DEBUG [Plate Slot]: Placed on slot: %s (Amount: %s). Is Filled: %s" % [food_resource.get("item_name"), amount, is_filled])
	
	# Emit signal to update parent/game manager after successful placement
	emit_signal("slot_updated", item_resource, is_filled)
	
	return true

# --- HELPER FUNCTION: Extracts resource and texture from incoming data ---
# (Keep this function as it handles the different ways food can be placed)
func _get_placement_data(incoming_data: Variant) -> Variant:
	# ... (Keep the full implementation of this helper function from your previous script)
	var food_resource: Resource = null
	var final_texture: Texture2D = null
	var amount: String = "RightAmount"
	
	if incoming_data is Resource:
		food_resource = incoming_data
		if food_resource.has_method("get") and food_resource.get("plated_texture") != null:
			final_texture = food_resource.plated_texture
		else:
			print("WARNING: Resource is missing 'plated_texture' property.")
			return null
	elif incoming_data is Node:
		# Rice Cup Drop
		if incoming_data.get_script() is GDScript and incoming_data.get_script().resource_path.ends_with("rice_cup.gd"):
			var rice_cup_instance = incoming_data
			food_resource = rice_cup_instance.get("food_data")
			amount = rice_cup_instance.get("current_rice_amount")
			if not food_resource: print("ERROR: Rice Cup food_data is null."); return null
			
			match amount:
				"RightAmount": final_texture = food_resource.plated_texture
				"Small": final_texture = food_resource.plated_texture_small
				"Medium": final_texture = food_resource.plated_texture_medium
				"TooHigh": final_texture = food_resource.plated_texture_too_high
				_: print("WARNING: Unknown rice amount: %s" % amount); return null
		# Generic Draggable Item
		elif incoming_data.has_method("get_food_resource"):
			food_resource = incoming_data.get_food_resource()
			if food_resource and food_resource.has_method("get") and food_resource.get("plated_texture") != null:
				final_texture = food_resource.plated_texture
			else:
				print("ERROR: Generic draggable item resource is missing plated_texture.")
				return null
		else:
			print("ERROR: Dropped node is neither Rice Cup nor a standard Food Item.")
			return null
	else:
		return null
	
	if food_resource == null or not food_resource is Resource:
		print("ERROR: Failed to obtain valid food resource in placement data extraction.")
		return null
		
	return {
		"food_resource": food_resource,
		"final_texture": final_texture,
		"amount": amount
	}
	
# --- FUNCTION TO CLEAR THE SLOT (Required for the Trash logic) ---
func clear_slot():
	if is_filled:
		is_filled = false
		item_resource = null
		if linked_image:
			linked_image.texture = null
			linked_image.visible = false
		# Signal that the slot is now empty
		emit_signal("slot_updated", item_resource, is_filled)
		print("DEBUG [Plate Slot]: Slot cleared.")
