extends TextureRect

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

@export var food_data: Resource:
	set(val):
		food_data = val
		if food_data and food_data.base_texture:
			texture = food_data.base_texture

@export_group("Animations")
@export var hover_scale: float = 1.1
@export var anim_speed: float = 0.1

var is_selected: bool = false
var original_scale: Vector2

# Tap detection variables
var drag_threshold: float = 10.0
var press_pos: Vector2
var is_pressing: bool = false

func _ready():
	# Use PASS so the CameraScroller can still see the input for dragging
	mouse_filter = Control.MOUSE_FILTER_PASS
	z_as_relative = false 
	pivot_offset = size / 2
	original_scale = scale
	
	if food_data and food_data.base_texture:
		texture = food_data.base_texture
		
	add_to_group("food_dispenser")

func _gui_input(event):
	# Only process if we are visible
	if not is_visible_in_tree():
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressing = true
			press_pos = event.position
		else:
			if is_pressing:
				# Check if the mouse moved significantly (it was a scroll, not a tap)
				var dist = press_pos.distance_to(event.position)
				if dist < drag_threshold:
					toggle_selection()
					# Optional: Consume event only on a successful tap
					get_viewport().set_input_as_handled()
				is_pressing = false

	if event is InputEventMouseMotion and is_pressing:
		var dist = press_pos.distance_to(event.position)
		if dist >= drag_threshold:
			# It's a drag, don't trigger selection on release
			is_pressing = false

func toggle_selection():
	if is_selected:
		deselect()
	else:
		select()

func select():
	get_tree().call_group("food_dispenser", "deselect")
	is_selected = true
	FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = self
	
	z_index = 10 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", original_scale * hover_scale, anim_speed)
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3), anim_speed)

func deselect():
	is_selected = false
	if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER == self:
		FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = null
	
	z_index = 0
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", original_scale, anim_speed)
	tween.tween_property(self, "modulate", Color.WHITE, anim_speed)
