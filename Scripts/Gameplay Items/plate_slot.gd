extends Area2D

# --- IMPORT DISPENSER REFERENCE ---
const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

@export var accepted_food_type: String = "Go" 
@export var linked_image: Sprite2D 
@export var plated_scale_factor: float = 0.4

var item_resource: Resource = null
var is_filled: bool = false

signal plate_updated

# --- INITIALIZATION AND SIGNAL CONNECTION FIX ---
func _ready():
	# CRITICAL FIX 1: Ensure input is enabled on this Area2D
	self.input_pickable = true
	
	# CRITICAL FIX 2: Programmatically connect the input_event signal
	if not self.is_connected("input_event", Callable(self, "_on_input_event")):
		self.connect("input_event", Callable(self, "_on_input_event"))
		print("DEBUG [Plate Slot]: Input signal connected programmatically.")
		
	# Ensure the linked image is present for placement
	if linked_image == null:
		print("FATAL ERROR [Plate Slot]: 'linked_image' Sprite2D is NOT assigned in the Inspector!")

# --- NEW: INPUT HANDLER FOR CLICK-TO-PLACE ---
func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	# Only react to the press event
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()) or (event is InputEventScreenTouch and event.is_pressed()):
		
		# --- DEBUG 1: Confirms the click reached the Plate Slot ---
		print("DEBUG [Plate Slot]: Input received.")
		
		# 1. Check if a dispenser is globally selected
		if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER != null:
			
			var selected_dispenser = FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER
			var food_resource = selected_dispenser.food_data
			
			# --- DEBUG 2: Confirms the dispenser and resource are valid ---
			print("DEBUG [Plate Slot]: Selected Dispenser is: %s" % selected_dispenser.name)
			# Safety check before accessing item_name
			if food_resource and food_resource.has_method("get_item_name"):
				print("DEBUG [Plate Slot]: Food Resource Name is: %s" % food_resource.item_name)
			
			# 2. If valid food data exists and slot is empty, attempt placement
			if food_resource and not is_filled:
				
				# --- DEBUG 3: Confirms we are about to call placement ---
				print("DEBUG [Plate Slot]: Calling try_place_food.")
				
				var success = try_place_food(food_resource) 
				
				if success:
					# 3. Placement successful: Deselect the dispenser
					selected_dispenser.toggle_selection()
					print("DEBUG [Plate Slot]: Placement Success. Dispenser deselected.")
					
				get_viewport().set_input_as_handled()
				
# --- CORE PLACEMENT FUNCTION (Used by both Drag-and-Drop AND Click-to-Place) ---
func try_place_food(incoming_resource: Resource) -> bool:
	
	# Check if the slot is already filled
	if is_filled:
		print("DEBUG [Plate Slot]: Slot already filled. Placement denied.")
		return false

	is_filled = true
	
	# PLACEMENT: Update visuals and store the data
	if incoming_resource.plated_texture:
		
		# --- DEBUG 4: Check if linked_image is missing (The common culprit!) ---
		if linked_image == null:
			print("FATAL ERROR [Plate Slot]: 'linked_image' Sprite2D is NOT assigned in the Inspector!")
			is_filled = false # Don't mark as filled if we can't display it
			return false
			
		linked_image.texture = incoming_resource.plated_texture
		linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor)
		linked_image.visible = true 
		print("DEBUG [Plate Slot]: Plated texture applied successfully.")
	else:
		# --- DEBUG 5: Check if the resource is missing the texture ---
		if incoming_resource.has_method("get_item_name"):
			print("ERROR [Plate Slot]: Incoming resource (%s) is missing its plated_texture!" % incoming_resource.item_name)
		else:
			print("ERROR [Plate Slot]: Incoming resource is missing its plated_texture!")
			
		is_filled = false # Placement failed due to missing resource data
		return false
	
	item_resource = incoming_resource 
	
	# Notify the Gameplay Manager that something was placed
	emit_signal("plate_updated", item_resource)
	
	return true
