extends Control

signal portion_selected(type: String)

# Updated paths based on your request
@onready var btn_half: BaseButton = $HBoxContainer/HalfPieceButton
@onready var img_half: TextureRect = $HBoxContainer/HalfPieceButton/HalfPieceImage

@onready var btn_whole: BaseButton = $HBoxContainer/WholePieceButton
@onready var img_whole: TextureRect = $HBoxContainer/WholePieceButton/WholePieceImage

# We store which dispenser triggered this popup
var target_dispenser: Node = null

func _ready():
	# Add to group so Dispensers can find this UI easily
	add_to_group("portion_selector")
	
	if btn_half: btn_half.pressed.connect(func(): _on_select("Half"))
	if btn_whole: btn_whole.pressed.connect(func(): _on_select("Whole"))
	
	hide() # Start hidden
	
	# Ensure this UI is always on top
	z_index = 100

func _input(event):
	# Auto-close if clicking outside
	if visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not get_global_rect().has_point(event.global_position):
			# Add a small delay/check to ensure we didn't just click the dispenser that opened us
			# (Optional, but usually safe to just close)
			_close_selector()

func open(dispenser: Node):
	target_dispenser = dispenser
	
	# --- 1. Position Logic ---
	# Center this UI over the dispenser
	# We use global_position to ensure it lines up regardless of parent containers
	if dispenser is Control:
		# Calculate center offset: Dispenser Center - Half of Selector Size
		var center_pos = dispenser.global_position + (dispenser.size / 2)
		global_position = center_pos - (size / 2)
		
		# Optional: Nudge it up slightly so it doesn't cover the dispenser completely
		global_position.y -= 20 
	
	# --- 2. Update Icons based on the Food Data ---
	if dispenser and "food_data" in dispenser and dispenser.food_data:
		var data = dispenser.food_data
		
		# Update Half Image
		if img_half:
			if data.selector_icon_half:
				img_half.texture = data.selector_icon_half
			elif data.plated_texture_half:
				img_half.texture = data.plated_texture_half
				
		# Update Whole Image
		if img_whole:
			if data.selector_icon_whole:
				img_whole.texture = data.selector_icon_whole
			elif data.plated_texture_whole:
				img_whole.texture = data.plated_texture_whole
	
	show()
	move_to_front()

func _on_select(type: String):
	# Send the data back to the specific dispenser that called us
	if is_instance_valid(target_dispenser):
		if target_dispenser.has_method("set_portion"):
			target_dispenser.set_portion(type)
	
	emit_signal("portion_selected", type)
	_close_selector()

func _close_selector():
	hide() 
	target_dispenser = null
