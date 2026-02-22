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
@export var selected_z_index: int = 100 

var is_selected: bool = false
var original_scale: Vector2

# Tap detection variables
var drag_threshold: float = 10.0
var press_pos: Vector2
var is_pressing: bool = false

# Stores "Half", "Whole", "VeggieFull" or "" 
var portion_type: String = ""

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
		# If we are already selected and it's a portion/veggie item, clicking again 
		# might be intended to re-open the UI to switch choice or tap again
		if food_data and "is_portionable" in food_data and food_data.is_portionable:
			_trigger_portion_selector()
		elif food_data and "is_veggie_cup" in food_data and food_data.is_veggie_cup:
			var ui = get_tree().get_first_node_in_group("veggie_cup_ui")
			if ui and ui.visible and ui.target_dispenser == self:
				# SAFE CALL: Continuous tapping while selected
				if ui.has_method("_on_tap"):
					ui.call_deferred("_on_tap")
			else:
				_trigger_veggie_cup_ui()
		else:
			deselect()
	else:
		select()

func select():
	get_tree().call_group("food_dispenser", "deselect")
	is_selected = true
	FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = self
	
	pivot_offset = size / 2
	z_index = selected_z_index 
	
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", original_scale * hover_scale, anim_speed)
	tween.tween_property(self, "modulate", Color(1.3, 1.3, 1.3), anim_speed)

	# Check for Portion Logic or Veggie Cup Logic
	if food_data and "is_portionable" in food_data and food_data.is_portionable:
		_trigger_portion_selector()
	elif food_data and "is_veggie_cup" in food_data and food_data.is_veggie_cup:
		_trigger_veggie_cup_ui()
	else:
		portion_type = "" 

func _trigger_portion_selector():
	var selector = get_tree().get_first_node_in_group("portion_selector")
	if selector:
		selector.call_deferred("open", self)
		selector.call_deferred("move_to_front")
	else:
		print("Warning: No 'PortionSelector' found in scene group 'portion_selector'")

func _trigger_veggie_cup_ui():
	var ui = get_tree().get_first_node_in_group("veggie_cup_ui")
	if ui:
		# SAFE CALL: Deferred ensures UI logic doesn't crash input event
		ui.call_deferred("open", self)
		ui.call_deferred("move_to_front")
		# Simulated first tap
		if ui.has_method("_on_tap"):
			ui.call_deferred("_on_tap")
	else:
		print("Warning: No 'veggie_cup_ui' found in scene group 'veggie_cup_ui'")

# Called by the PortionSelector UI or VeggieCup UI when a button is clicked or cup is filled
func set_portion(type: String):
	portion_type = type
	print("Dispenser ", name, " set to portion: ", portion_type)

func deselect():
	is_selected = false
	if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER == self:
		FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = null
	
	z_index = 0 
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "scale", original_scale, anim_speed)
	tween.tween_property(self, "modulate", Color.WHITE, anim_speed)
