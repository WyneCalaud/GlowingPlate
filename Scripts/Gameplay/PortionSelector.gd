extends Control

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

signal portion_selected(type: String)

@onready var btn_half: BaseButton = $HBoxContainer/HalfPieceButton
@onready var img_half: TextureRect = $HBoxContainer/HalfPieceButton/HalfPieceImage

@onready var btn_whole: BaseButton = $HBoxContainer/WholePieceButton
@onready var img_whole: TextureRect = $HBoxContainer/WholePieceButton/WholePieceImage

var target_dispenser: Node = null
var has_selection: bool = false 
var current_selection_type: String = "" 
var active_tween: Tween # Tween reference for the blink animations

func _ready():
	add_to_group("portion_selector")
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	if btn_half: btn_half.pressed.connect(func(): _on_select("Half"))
	if btn_whole: btn_whole.pressed.connect(func(): _on_select("Whole"))
	
	hide() 
	z_index = 100

func _process(_delta):
	if visible and target_dispenser != null:
		# PASSIVE MONITOR: Continuously check if our target is still the globally selected item.
		if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER != target_dispenser:
			_close_selector()
		else:
			# CRITICAL FIX: Continuously track the dispenser so camera scrolling doesn't misalign it
			var center_pos = target_dispenser.get_global_rect().get_center()
			global_position = center_pos - (size / 2)
			global_position.y -= 50

# Using unhandled input for background clicks so we don't intercept/block plate slots or other food clicks
func _unhandled_input(event):
	if visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# If the click wasn't consumed by any UI or Game Element, it was an empty background click.
		if not get_global_rect().has_point(event.global_position):
			if is_instance_valid(target_dispenser) and target_dispenser.has_method("deselect"):
				target_dispenser.deselect()
			_close_selector()

func open(dispenser: Node):
	target_dispenser = dispenser
	has_selection = false 
	current_selection_type = ""
	
	if btn_half: btn_half.visible = true
	if btn_whole: btn_whole.visible = true
	
	if dispenser is Control:
		var center_pos = dispenser.get_global_rect().get_center()
		global_position = center_pos - (size / 2)
		global_position.y -= 50 
	
	if dispenser and "food_data" in dispenser and dispenser.food_data:
		var data = dispenser.food_data
		
		if img_half:
			if data.selector_icon_half: img_half.texture = data.selector_icon_half
			elif data.plated_texture_half: img_half.texture = data.plated_texture_half
				
		if img_whole:
			if data.selector_icon_whole: img_whole.texture = data.selector_icon_whole
			elif data.plated_texture_whole: img_whole.texture = data.plated_texture_whole
	
	show()
	move_to_front()

	# --- BLINK IN ANIMATION ---
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	pivot_offset = size / 2 # Set pivot to center for scaling
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)

	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	active_tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func _on_select(type: String):
	if has_selection and current_selection_type == type:
		has_selection = false
		current_selection_type = ""
		
		if is_instance_valid(target_dispenser) and target_dispenser.has_method("set_portion"):
			target_dispenser.set_portion("")
		
		if btn_half: btn_half.visible = true
		if btn_whole: btn_whole.visible = true
		
		emit_signal("portion_selected", "")
		return

	if is_instance_valid(target_dispenser):
		if target_dispenser.has_method("set_portion"):
			target_dispenser.set_portion(type)
	
	emit_signal("portion_selected", type)
	
	has_selection = true
	current_selection_type = type
	
	if type == "Half":
		if btn_half: btn_half.visible = true
		if btn_whole: btn_whole.visible = false
	elif type == "Whole":
		if btn_whole: btn_whole.visible = true
		if btn_half: btn_half.visible = false

func _close_selector():
	target_dispenser = null # Null immediately to prevent _process from calling this again
	
	# --- BLINK OUT ANIMATION ---
	if active_tween and active_tween.is_valid():
		active_tween.kill()

	pivot_offset = size / 2

	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	active_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.15)
	
	# Hide entirely once the animation finishes
	active_tween.chain().tween_callback(func(): hide())
