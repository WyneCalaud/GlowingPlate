# food_item_base.gd
extends Sprite2D

# --- COMMON VARIABLES ---
var is_dragging = false
var start_position: Vector2
var current_hovered_area: Area2D = null
var drop_offset: Vector2 = Vector2.ZERO # Added for better drag/drop calculation

# --- NEW CORE EXPORT (The single source of data) ---
# This must be assigned a FoodItemData.tres file in the Inspector.
@export var food_data: Resource

# NEW: Getter function for external scripts (like Plate Slot) to safely access the resource
func get_food_resource() -> Resource:
	return food_data
	
func _ready() -> void:
	# Set the initial texture from the resource's base_texture
	if food_data:
		texture = food_data.base_texture
		
	start_position = global_position
	z_index = 20
	var area_node = get_node_or_null("Area2D")
	
	if area_node:
		# --- SAFEGUARD SIGNAL CONNECTIONS ---
		# Check if the signal is already connected before connecting it.
		
		if not area_node.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
			area_node.connect("input_event", Callable(self, "_on_area_2d_input_event"))
			
		if not area_node.is_connected("area_entered", Callable(self, "_on_area_2d_area_entered")):
			area_node.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
			
		if not area_node.is_connected("area_exited", Callable(self, "_on_area_2d_area_exited")):
			area_node.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))
	else:
		printerr("FATAL ERROR: Child Area2D node 'Area2D' is missing in food_item_base.gd's scene.")

func _process(_delta: float) -> void:
	if is_dragging:
		# Use offset for smoother dragging (prevents the object from snapping its center to the mouse)
		global_position = get_global_mouse_position() - drop_offset

# --- INPUT LOGIC (Identical for all items) ---
func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var area_node = get_node_or_null("Area2D")
	if area_node and area_node.input_pickable: # Check input_pickable
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch):
			if event.is_pressed():
				# Calculate offset on press
				drop_offset = get_global_mouse_position() - global_position
				start_dragging()
				# Consume event to prevent other nodes/base scene from receiving it
				get_viewport().set_input_as_handled() 
			elif event.is_released():
				is_dragging = false
				z_index = 20
				handle_drop()

# --- AREA DETECTION (The connected functions) ---
func _on_area_2d_area_entered(area: Area2D) -> void:
	current_hovered_area = area

func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_hovered_area == area:
		current_hovered_area = null

# --- RETURN LOGIC (Identical for all items) ---
func return_to_start():
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_position, 0.3).set_ease(Tween.EASE_OUT)

# --- CORE DROP LOGIC (UPDATED) ---
func handle_drop():
	if current_hovered_area == null:
		return_to_start()
		return
	
	if current_hovered_area.has_method("try_place_food"):
		
		# PASS THE RICE CUP INSTANCE (self) INSTEAD OF JUST food_data
		# This allows the plate to read the current_rice_amount state from the cup.
		var success = current_hovered_area.try_place_food(self)
		
		if success:
			# Use the Resource property for the printout
			print("Placed on plate: %s" % food_data.item_name)
			
			# The rice cup's implementation of this function will handle cleanup
			on_plate_placement_success()	
			
		else:
			return_to_start()
			
	# If not a plate, check for other unique drop zones
	else:
		on_unique_drop_zone_check()
		
# --- VIRTUAL FUNCTIONS (To be overridden by child classes) ---

func on_plate_placement_success():
	# Default: If the food is placed, we assume it's consumed/removed.
	# Child scripts (e.g., rice cup) will override this to change texture/scale.
	queue_free()

func on_unique_drop_zone_check():
	return_to_start()
	
func start_dragging():
	is_dragging = true
	z_index = 30
