extends Sprite2D

# --- CONFIGURATION ---
const TRAVEL_TIME = 0.5 
const GLASS_SIZE_MULTIPLIER = 2.5
const FILLED_GLASS_SCALE = Vector2(2.5, 2.0)

# --- RESOURCES & PATHS ---
const EMPTY_GLASS_SCENE = preload("res://Assets/Beverages/EmptyGlass.tscn")
const HOLD_BUTTON_SCENE = preload("res://Scenes/Gameplay/RiceScoopUI.tscn")
const FILLED_GLASS_GENERIC_SCENE = preload("res://Assets/Beverages/FilledWaterGlass.tscn")

# --- WATER TEXTURES ---
const WATER_TEXTURE_LOW = preload("res://Assets/Beverages/Glasses/LowWater.png")
const WATER_TEXTURE_MED = preload("res://Assets/Beverages/Glasses/MedWater.png")
const WATER_TEXTURE_RIGHT = preload("res://Assets/Beverages/Glasses/RightWater.png")
const WATER_TEXTURE_HIGH = preload("res://Assets/Beverages/Glasses/TooHighWater.png")

# --- MILK TEXTURES ---

# --- CACHE NODE REFERENCES ---
@onready var mat1: Node2D = $"../../Mat/Mat1"
@onready var mat2: Node2D = $"../../Mat/Mat2" 
var beverage_station_root: Node = null
var is_spawning: bool = false 

# --- GLOBAL STATE ---
var selected_liquid: String = "" 
var current_dispenser_node: Node = null

func _ready():
	var current_node = get_parent()
	while current_node and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node
	add_to_group("global_controller")

func set_liquid_selection(dispenser_node: Node, liquid_name: String):
	reset_liquid_selection_visuals()
	selected_liquid = liquid_name
	current_dispenser_node = dispenser_node
	if is_instance_valid(dispenser_node) and dispenser_node.has_method("set_visual_state"):
		dispenser_node.set_visual_state(true)
	print("STATE: Selected liquid is now: ", selected_liquid)

func reset_liquid_selection_visuals():
	if is_instance_valid(current_dispenser_node) and current_dispenser_node.has_method("set_visual_state"):
		current_dispenser_node.set_visual_state(false)
	current_dispenser_node = null
	selected_liquid = ""
	print("STATE: Liquid selection reset.")

# --- INTERACTION LOGIC ---
func replace_glass_with_filled(empty_glass: Node2D, fill_level: int, liquid_type_override: String = ""):
	
	print("DEBUG: replace_glass called. Level: %d, Override: %s" % [fill_level, liquid_type_override])

	var check_liquid = liquid_type_override if liquid_type_override != "" else selected_liquid
	
	var valid_waters = ["water", "hot", "cold", "lukewarm"]
	var is_valid_water = false
	for w in valid_waters:
		if check_liquid.to_lower().begins_with(w):
			is_valid_water = true
			break
			
	if is_valid_water:
		# 1. Handle "TooFast" (Level 0) immediately
		if fill_level == 0:
			print("ACTION: Held too short (TooFast). Glass remains empty.")
			# FIX: Ensure visual disappearance for failure state too
			empty_glass.visible = false 
			empty_glass.queue_free()
			return false

		# 2. Determine Texture
		var target_texture: Texture2D = null
		var amount_string: String = "Right"
		
		match fill_level:
			1: 
				target_texture = WATER_TEXTURE_LOW
				amount_string = "Low"
			2: 
				target_texture = WATER_TEXTURE_MED
				amount_string = "Medium"
			3: 
				target_texture = WATER_TEXTURE_RIGHT
				amount_string = "Right"
			4: 
				target_texture = WATER_TEXTURE_HIGH
				amount_string = "TooHigh"
			_: 
				print("ERROR: Invalid fill level: %d" % fill_level)
				return false
		
		# 3. CRITICAL FIX: Hide the empty glass and ALL its children immediately
		empty_glass.visible = false
		for child in empty_glass.get_children():
			if child is CanvasItem:
				child.visible = false
		
		# 4. Create Filled Glass
		var filled_glass: Node2D = FILLED_GLASS_GENERIC_SCENE.instantiate()
		
		if filled_glass is Sprite2D:
			filled_glass.texture = target_texture
		else:
			var sprite_child = filled_glass.get_node_or_null("Sprite2D")
			if sprite_child: sprite_child.texture = target_texture

		if filled_glass.get("current_liquid_amount") != null:
			filled_glass.current_liquid_amount = amount_string

		# 5. Swap in Scene Tree
		var parent = empty_glass.get_parent()
		if parent:
			var global_pos = empty_glass.global_position
			
			# Force removal from parent
			parent.remove_child(empty_glass)
			parent.add_child(filled_glass)
			
			filled_glass.global_position = global_pos
			filled_glass.scale = FILLED_GLASS_SCALE 
			print("DEBUG: Swapped nodes on parent: %s" % parent.name)
		else:
			print("ERROR: Empty Glass has no parent! Cannot swap.")
			
		# 6. Delete Empty Glass
		empty_glass.queue_free()
		
		reset_liquid_selection_visuals()
		
		print("ACTION: Glass filled with %s. Amount: %s" % [check_liquid, amount_string])
		return true
	
	print("ACTION: Wrong liquid context for replacement.")
	return false

func _input(event: InputEvent) -> void:
	if is_spawning: return
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		var local_click_pos = to_local(get_global_mouse_position())
		if get_rect().has_point(local_click_pos):
			get_viewport().set_input_as_handled()
			reset_liquid_selection_visuals()
			spawn_and_place_glass()

func spawn_and_place_glass():
	if not EMPTY_GLASS_SCENE: return
	var target_mat: Node2D = null
	if mat1 and mat1.get_child_count() == 0: target_mat = mat1
	elif mat2 and mat2.get_child_count() == 0: target_mat = mat2
	else: return
		
	is_spawning = true 
	var empty_glass: Node2D = EMPTY_GLASS_SCENE.instantiate()
	empty_glass.name = "EmptyGlass"
	empty_glass.scale *= GLASS_SIZE_MULTIPLIER
	
	if beverage_station_root: beverage_station_root.add_child(empty_glass)
	else: add_child(empty_glass)
		
	empty_glass.global_position = self.global_position
	var final_position = target_mat.global_position + Vector2(0, -50)

	var tween = create_tween()
	tween.tween_property(empty_glass, "global_position", final_position, TRAVEL_TIME)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	var current_global_pos = empty_glass.global_position
	var current_global_scale = empty_glass.global_scale 
	
	var current_parent = empty_glass.get_parent()
	if current_parent: current_parent.remove_child(empty_glass)
	
	target_mat.add_child(empty_glass)
	empty_glass.global_position = current_global_pos
	empty_glass.global_scale = current_global_scale
	is_spawning = false
