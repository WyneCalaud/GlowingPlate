# food_item_base.gd
extends Sprite2D

# --- COMMON VARIABLES ---
var is_dragging = false
var start_position: Vector2
var current_hovered_area: Area2D = null

# --- COMMON EXPORTS ---
@export var food_type: String = "Go"
@export var plated_texture: Texture2D

func _ready() -> void:
	start_position = global_position
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

# --- CORE DROP LOGIC (Must be implemented by the child) ---
func handle_drop():
	if current_hovered_area == null:
		return_to_start()
		return
	
	if current_hovered_area.has_method("try_place_food"):
		
		var texture_to_send = plated_texture
		if texture_to_send == null:
			texture_to_send = texture
			
		var success = current_hovered_area.try_place_food(food_type, texture_to_send)
		
		if success:
			print("Placed on plate!")
			
			on_plate_placement_success() 
			
		else:
			return_to_start()
			
	# If not a plate, check for other unique drop zones (like the cooker)
	else:
		on_unique_drop_zone_check()
		
# --- VIRTUAL FUNCTIONS (To be overridden by child classes) ---

func on_plate_placement_success():
	return # Default implementation does nothing

func on_unique_drop_zone_check():
	return_to_start()
	
func start_dragging():
	is_dragging = true
	z_index = 30
