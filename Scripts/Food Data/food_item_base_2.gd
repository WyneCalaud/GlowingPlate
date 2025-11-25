# food_item_base.gd
extends Sprite2D

# --- COMMON VARIABLES ---
var is_dragging = false
var start_position: Vector2
var current_hovered_area: Area2D = null

# --- NEW CORE EXPORT (The single source of data) ---
# This must be assigned a FoodItemData.tres file in the Inspector.
@export var food_data: Resource

func _ready() -> void:
	# Set the initial texture from the resource's base_texture
	if food_data:
		texture = food_data.base_texture
		
	z_index = 20
	var area_node = get_node_or_null("Area2D")
	if area_node:
		area_node.connect("input_event", _on_area_2d_input_event)
		area_node.connect("area_entered", _on_area_2d_area_entered)
		area_node.connect("area_exited", _on_area_2d_area_exited)
	else:
		pass

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

# --- INPUT LOGIC (Identical for all items) ---
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch):
		if event.is_pressed():
			is_dragging = true
			z_index = 30
		elif event.is_released():
			is_dragging = false
			z_index = 20
			handle_drop()

func _on_area_2d_area_entered(area: Area2D) -> void:
	current_hovered_area = area

func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_hovered_area == area:
		current_hovered_area = null

# --- RETURN LOGIC (Identical for all items) ---
func return_to_start():
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_position, 0.3).set_ease(Tween.EASE_OUT)

# --- CORE DROP LOGIC ---
func handle_drop():
	if current_hovered_area == null:
		queue_free()
		return
	
	if current_hovered_area.has_method("try_place_food"):
		
		# Pass the FoodItemData Resource object itself to the plate slot
		var success = current_hovered_area.try_place_food(food_data) 
		
		if success:
			# Use the Resource property for the printout
			print("Placed on plate: %s" % food_data.item_name) 
			
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
