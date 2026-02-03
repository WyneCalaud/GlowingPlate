# food_item_base.gd
extends Sprite2D

var is_dragging = false
var start_position: Vector2
var current_hovered_area: Area2D = null
var drop_offset: Vector2 = Vector2.ZERO 

@export var food_data: Resource

func get_food_resource() -> Resource:
	return food_data
	
func _ready() -> void:
	if food_data:
		texture = food_data.base_texture
		
	start_position = global_position
	z_index = 20
	var area_node = get_node_or_null("Area2D")
	
	if area_node:
		if not area_node.is_connected("input_event", Callable(self, "_on_area_2d_input_event")):
			area_node.connect("input_event", Callable(self, "_on_area_2d_input_event"))
		if not area_node.is_connected("area_entered", Callable(self, "_on_area_2d_area_entered")):
			area_node.connect("area_entered", Callable(self, "_on_area_2d_area_entered"))
		if not area_node.is_connected("area_exited", Callable(self, "_on_area_2d_area_exited")):
			area_node.connect("area_exited", Callable(self, "_on_area_2d_area_exited"))

func _process(_delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position() - drop_offset

func _on_area_2d_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	var area_node = get_node_or_null("Area2D")
	if area_node and area_node.input_pickable: 
		if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch):
			if event.is_pressed():
				drop_offset = get_global_mouse_position() - global_position
				start_dragging()
				get_viewport().set_input_as_handled() 
			elif event.is_released() and is_dragging:
				is_dragging = false
				z_index = 20
				handle_drop()

func _on_area_2d_area_entered(area: Area2D) -> void:
	current_hovered_area = area

func _on_area_2d_area_exited(area: Area2D) -> void:
	if current_hovered_area == area:
		current_hovered_area = null

func return_to_start():
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_position, 0.3).set_ease(Tween.EASE_OUT)

func handle_drop():
	if current_hovered_area == null:
		return_to_start()
		return
	
	if current_hovered_area.has_method("try_place_food"):
		var success = current_hovered_area.try_place_food(self)
		if success:
			on_plate_placement_success()	
		else:
			return_to_start()
	else:
		on_unique_drop_zone_check()
		
func on_plate_placement_success():
	queue_free()

func on_unique_drop_zone_check():
	return_to_start()
	
func start_dragging():
	is_dragging = true
	z_index = 30
