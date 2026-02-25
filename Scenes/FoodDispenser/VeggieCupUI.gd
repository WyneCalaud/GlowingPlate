extends Control

const FoodDispenserGlobals = preload("res://Scripts/Global/FoodDispenserGlobal.gd")

signal veggie_cup_filled()

# --- NODES ---
@onready var cup_progress: TextureRect = $CupProgress

# --- STATE ---
var target_dispenser: Node = null
var tap_count: int = 0
var active_tween: Tween

# --- TEXTURE CACHE ---
var tex_low: Texture2D
var tex_med: Texture2D
var tex_high: Texture2D
var tex_full: Texture2D

func _ready():
	add_to_group("veggie_cup_ui")
	mouse_filter = Control.MOUSE_FILTER_PASS
	top_level = true
	z_index = 4096 
	hide() 

func _process(_delta):
	if visible and is_instance_valid(target_dispenser):
		if FoodDispenserGlobals.CURRENTLY_SELECTED_DISPENSER != target_dispenser:
			_close_ui()
		else:
			var center_pos = target_dispenser.get_global_rect().get_center()
			global_position = center_pos - (size / 2)
			global_position.y -= 75

func _unhandled_input(event):
	if visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not get_global_rect().has_point(event.global_position):
			if is_instance_valid(target_dispenser) and target_dispenser.has_method("deselect"):
				target_dispenser.deselect()
			_close_ui()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		_on_tap()

func open(dispenser: Node):
	target_dispenser = dispenser
	tap_count = 0
	
	if dispenser and "food_data" in dispenser and dispenser.food_data:
		var data = dispenser.food_data
		tex_low = data.veggie_cup_low
		tex_med = data.veggie_cup_med
		tex_high = data.veggie_cup_high
		tex_full = data.veggie_cup_full
		
		if cup_progress:
			cup_progress.texture = null 
			cup_progress.visible = true
	
	var center_pos = dispenser.get_global_rect().get_center()
	global_position = center_pos - (size / 2)
	global_position.y -= 75 
	
	show()
	move_to_front()

	if active_tween and active_tween.is_valid():
		active_tween.kill()

	pivot_offset = size / 2
	modulate.a = 0.0
	scale = Vector2(0.5, 0.5)

	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	active_tween.tween_property(self, "modulate:a", 1.0, 0.2)
	active_tween.tween_property(self, "scale", Vector2.ONE, 0.2)

func _on_tap():
	if tap_count >= 4:
		return 

	tap_count += 1
	
	var bounce = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scale = Vector2(1.1, 1.1)
	bounce.tween_property(self, "scale", Vector2.ONE, 0.15)

	if cup_progress:
		match tap_count:
			1: 
				cup_progress.texture = tex_low
				# Silently set to VeggieHigh so it's ready to serve if they stop tapping here
				if is_instance_valid(target_dispenser) and target_dispenser.has_method("set_portion"):
					target_dispenser.set_portion("VeggieLow")
			2: 
				cup_progress.texture = tex_med
				# Silently set to VeggieHigh so it's ready to serve if they stop tapping here
				if is_instance_valid(target_dispenser) and target_dispenser.has_method("set_portion"):
					target_dispenser.set_portion("VeggieMed")
			3: 
				cup_progress.texture = tex_high
				# Silently set to VeggieHigh so it's ready to serve if they stop tapping here
				if is_instance_valid(target_dispenser) and target_dispenser.has_method("set_portion"):
					target_dispenser.set_portion("VeggieHigh")
			4: 
				cup_progress.texture = tex_full
				_on_cup_full("VeggieFull")

func _on_cup_full(portion_key: String):
	emit_signal("veggie_cup_filled")
	
	if is_instance_valid(target_dispenser) and target_dispenser.has_method("set_portion"):
		target_dispenser.set_portion(portion_key)
		
	var pop_tween = create_tween().set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	pop_tween.tween_property(cup_progress, "scale", Vector2(1.2, 1.2), 0.3)
	pop_tween.tween_property(cup_progress, "scale", Vector2.ONE, 0.2)

func _close_ui():
	target_dispenser = null 
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	pivot_offset = size / 2
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	active_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	active_tween.tween_property(self, "scale", Vector2(0.5, 0.5), 0.15)
	active_tween.chain().tween_callback(func(): hide())
