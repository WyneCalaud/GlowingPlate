# stack_glass_spawner.gd
extends Sprite2D

# --- CONFIGURATION ---
const TRAVEL_TIME = 0.5 
const GLASS_SIZE_MULTIPLIER = 2.5
const FILLED_GLASS_SCALE = Vector2(2.8, 2.3)
const EMPTY_GLASS_SCALE = Vector2(2.5, 2.5)
const RETURN_SPEED = 0.3 # Time for the glass to return from trash

# --- RESOURCES & PATHS ---
const EMPTY_GLASS_SCENE = preload("res://Assets/Beverages/EmptyGlass.tscn")
const HOLD_BUTTON_SCENE = preload("res://Scenes/LiquidDispenser/FillMechanic.tscn")
const FILLED_GLASS_GENERIC_SCENE = preload("res://Assets/Beverages/FilledWaterGlass.tscn")

# --- WATER TEXTURES ---
const WATER_TEXTURE_LOW = preload("res://Assets/UI/Water/GlassLow.png")
const WATER_TEXTURE_MED = preload("res://Assets/UI/Water/GlassMed.png")
const WATER_TEXTURE_RIGHT = preload("res://Assets/UI/Water/GlassHigh.png")
const WATER_TEXTURE_HIGH = preload("res://Assets/UI/Water/GlassFull.png")

# --- CACHE NODE REFERENCES ---
@onready var mat1: Node2D = get_node_or_null("../../Mat/Mat1")
@onready var mat2: Node2D = get_node_or_null("../../Mat/Mat2") 
var beverage_station_root: Node = null
var is_spawning: bool = false 

# --- GLOBAL STATE ---
var selected_liquid: String = "" 
var current_dispenser_node: Node = null

# --- TUTORIAL SYSTEM ---
var is_tutorial_locked: bool = false

func _ready():
	var current_node = get_parent()
	while is_instance_valid(current_node) and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node
	add_to_group("global_controller")
	
	# DEFENSIVE FALLBACK: Auto-find mats if relative path failed
	if not is_instance_valid(mat1) and is_instance_valid(beverage_station_root):
		mat1 = beverage_station_root.find_child("Mat1", true, false) as Node2D
	if not is_instance_valid(mat2) and is_instance_valid(beverage_station_root):
		mat2 = beverage_station_root.find_child("Mat2", true, false) as Node2D

func set_liquid_selection(dispenser_node: Node, liquid_name: String):
	reset_liquid_selection_visuals()
	selected_liquid = liquid_name
	current_dispenser_node = dispenser_node
	if is_instance_valid(dispenser_node) and dispenser_node.has_method("set_visual_state"):
		dispenser_node.set_visual_state(true)
	print("STATE: Selected liquid is now: ", selected_liquid)

func reset_liquid_selection_visuals():
	var dispenser_to_reset = current_dispenser_node
	
	current_dispenser_node = null
	selected_liquid = ""
	
	if is_instance_valid(dispenser_to_reset) and dispenser_to_reset.has_method("set_visual_state"):
		dispenser_to_reset.set_visual_state(false)
		
	print("STATE: Liquid selection reset.")

# --- SWAP FILLED GLASS FOR EMPTY GLASS (TRASHING) ---
func replace_filled_with_empty(filled_glass: Node2D):
	if not is_instance_valid(filled_glass): 
		return
	
	var parent = filled_glass.get_parent()
	if not is_instance_valid(parent):
		filled_glass.queue_free()
		return
		
	var global_pos_start = filled_glass.global_position
	var global_scale = EMPTY_GLASS_SCALE 
	
	var return_pos_on_mat = filled_glass.get("start_position")
	if return_pos_on_mat == null:
		return_pos_on_mat = parent.global_position + Vector2(0, -50)
		print("WARNING: Using fallback return position.")
		
	parent.remove_child(filled_glass)
	
	var empty_glass: Node2D = EMPTY_GLASS_SCENE.instantiate()
	if not is_instance_valid(empty_glass): return
	
	empty_glass.name = "EmptyGlass"
	parent.add_child(empty_glass)
	
	empty_glass.global_position = global_pos_start
	empty_glass.global_scale = global_scale 
	
	var tween = create_tween()
	if tween:
		tween.tween_property(empty_glass, "global_position", return_pos_on_mat, RETURN_SPEED)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	filled_glass.queue_free()
	print("ACTION: Filled glass trashed and replaced with new empty glass on Mat. Initiating return animation.")

# --- INTERACTION LOGIC ---
func replace_glass_with_filled(empty_glass: Node2D, fill_level: int, liquid_type_override: String = ""):
	if not is_instance_valid(empty_glass): return false
	
	print("DEBUG: replace_glass called. Level: %d, Override: %s" % [fill_level, liquid_type_override])

	var check_liquid = liquid_type_override if liquid_type_override != "" else selected_liquid
	var liquid_lower = check_liquid.to_lower()
	
	var valid_waters = ["water", "hot", "cold", "lukewarm"]
	var is_water = false
	for w in valid_waters:
		if liquid_lower.begins_with(w):
			is_water = true
			break
	
	if is_water:
		if fill_level == 0:
			print("ACTION: Held too short (TooFast). Glass remains empty.")
			empty_glass.visible = false 
			
			var p = empty_glass.get_parent()
			if is_instance_valid(p): p.remove_child(empty_glass)
			empty_glass.queue_free()
			return false

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
		
		empty_glass.visible = false
		for child in empty_glass.get_children():
			if child is CanvasItem:
				child.visible = false
		
		var filled_glass: Node2D = FILLED_GLASS_GENERIC_SCENE.instantiate()
		if not is_instance_valid(filled_glass): return false
		
		var os = get_node_or_null("/root/OrderSystem")
		if is_instance_valid(os):
			if liquid_lower.contains("hot"):
				filled_glass.water_data = os.FOOD_DB.get("HOT_WATER", null)
			elif liquid_lower.contains("cold"):
				filled_glass.water_data = os.FOOD_DB.get("COLD_WATER", null)

		if filled_glass is Sprite2D:
			filled_glass.texture = target_texture
		else:
			var sprite_child = filled_glass.get_node_or_null("Sprite2D")
			if is_instance_valid(sprite_child): sprite_child.texture = target_texture

		if "current_liquid_amount" in filled_glass:
			filled_glass.current_liquid_amount = amount_string
			filled_glass.set_meta("LiquidType", check_liquid)
			
		var parent = empty_glass.get_parent()
		if is_instance_valid(parent):
			var global_pos = empty_glass.global_position
			
			parent.remove_child(empty_glass)
			parent.add_child(filled_glass)
			
			filled_glass.global_position = global_pos
			filled_glass.scale = FILLED_GLASS_SCALE
			
			if "start_position" in filled_glass:
				filled_glass.set("start_position", global_pos) 
			
			print("DEBUG: Swapped nodes on parent: %s" % parent.name)
		else:
			print("ERROR: Empty Glass has no parent! Cannot swap.")
			
		empty_glass.queue_free()
		reset_liquid_selection_visuals()
		
		print("ACTION: Glass filled with %s. Amount: %s" % [check_liquid, amount_string])
		return true
	
	print("ACTION: Wrong liquid context for replacement.")
	return false

func _input(event: InputEvent) -> void:
	if is_tutorial_locked or is_spawning: return
	
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.is_pressed()):
		var local_click_pos = to_local(get_global_mouse_position())
		if get_rect().has_point(local_click_pos):
			get_viewport().set_input_as_handled()
			reset_liquid_selection_visuals()
			spawn_and_place_glass()
			
			var in_tutorial = get_tree().get_node_count_in_group("InteractiveTutorial") > 0
			if in_tutorial:
				get_tree().call_group("InteractiveTutorial", "action_completed", "Stack_Glass_Pressed")
				is_tutorial_locked = true

func is_mat_available(mat: Node2D) -> bool:
	if not is_instance_valid(mat): 
		print("DEBUG [StackGlass]: Mat is invalid or null!")
		return false
		
	if mat.get_meta("reserved", false): 
		print("DEBUG [StackGlass]: %s is currently RESERVED!" % mat.name)
		return false
	
	for child in mat.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			# DEFENSIVE CHECK: Ignore nodes that are hidden (leftover ghosts from ServeZone)
			if child is CanvasItem and not child.visible:
				continue
			print("DEBUG [StackGlass]: %s has active child: %s" % [mat.name, child.name])
			return false 
			
	return true

func spawn_and_place_glass():
	if not EMPTY_GLASS_SCENE: return
	var target_mat: Node2D = null
	
	if is_mat_available(mat1): target_mat = mat1
	elif is_mat_available(mat2): target_mat = mat2
	else: 
		print("DEBUG [StackGlass]: Both mats are occupied or reserved.")
		return
		
	is_spawning = true 
	target_mat.set_meta("reserved", true)
	
	var empty_glass: Node2D = EMPTY_GLASS_SCENE.instantiate()
	if not is_instance_valid(empty_glass):
		is_spawning = false
		target_mat.set_meta("reserved", false)
		return
		
	empty_glass.name = "EmptyGlass"
	empty_glass.scale = Vector2(GLASS_SIZE_MULTIPLIER, GLASS_SIZE_MULTIPLIER)
	
	if is_instance_valid(beverage_station_root): beverage_station_root.add_child(empty_glass)
	else: add_child(empty_glass)
		
	empty_glass.global_position = self.global_position
	var final_position = target_mat.global_position + Vector2(0, -50)

	var tween = create_tween()
	if tween:
		tween.tween_property(empty_glass, "global_position", final_position, TRAVEL_TIME)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
	
	if not is_instance_valid(empty_glass) or not is_instance_valid(target_mat):
		is_spawning = false
		if is_instance_valid(target_mat): target_mat.set_meta("reserved", false)
		return
	
	var current_global_pos = empty_glass.global_position
	var current_global_scale = empty_glass.global_scale
	
	var current_parent = empty_glass.get_parent()
	if is_instance_valid(current_parent): current_parent.remove_child(empty_glass)
	
	target_mat.add_child(empty_glass)
	empty_glass.global_position = current_global_pos
	empty_glass.global_scale = current_global_scale
	
	target_mat.set_meta("reserved", false)
	is_spawning = false

func clear_all_mats():
	print("TUTORIAL: Force clearing mats for next phase.")
	if is_instance_valid(mat1):
		for child in mat1.get_children():
			mat1.remove_child(child) 
			if is_instance_valid(child):
				child.queue_free()
		mat1.set_meta("reserved", false)
		
	if is_instance_valid(mat2):
		for child in mat2.get_children():
			mat2.remove_child(child) 
			if is_instance_valid(child):
				child.queue_free()
		mat2.set_meta("reserved", false)
