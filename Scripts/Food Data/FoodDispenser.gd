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

func _ready():
	# Keep as STOP so we can select the dispenser, 
	# but we must ensure it doesn't physically cover the plate.
	mouse_filter = Control.MOUSE_FILTER_STOP
	z_as_relative = false 
	pivot_offset = size / 2
	original_scale = scale
	
	if food_data and food_data.base_texture:
		texture = food_data.base_texture
		
	add_to_group("food_dispenser")

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle_selection()
		# Mark as handled so the plate doesn't try to place food at the same moment you select the dispenser
		get_viewport().set_input_as_handled()

func toggle_selection():
	if is_selected:
		deselect()
	else:
		select()

func select():
	get_tree().call_group("food_dispenser", "deselect")
	is_selected = true
	FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER = self
	
	# Visual lift
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
