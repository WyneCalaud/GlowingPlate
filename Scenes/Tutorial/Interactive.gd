extends Control

# -------------------------------------------------------------------------
# TUTORIAL MASTER CONTROLLER (INSPECTOR VERSION)
# -------------------------------------------------------------------------

@export var tutorial_phases: Array[TutorialPhase] = []

# --- TUTORIAL ASSETS ---
@export_group("Tutorial Specific Assets")
@export var rice_retry_texture: Texture2D 
@export var veggie_retry_texture: Texture2D 

# --- UI Reference ---
@onready var tutorial_overlay = get_node_or_null("TutorialUI/TutorialOverlaySteps")

# --- Scene Tree References ---
@onready var kitchen_area = get_node_or_null("KitchenArea")
@onready var beverage_station = get_node_or_null("BeverageStation")
@onready var lobby_canteen = get_node_or_null("LobbyCanteen")
@onready var serve_or_trash = get_node_or_null("ServeOrTrash")

# --- Drop Zone & Plate Variables ---
var drop_zones_default_position: Vector2
var food_plate: Node2D = null

var current_phase: int = 0
var current_step: int = 0
var is_in_retry_state: bool = false

# --- SKIP BUTTON ---
@onready var skip_tutorial = get_node_or_null("CanvasLayer2/SkipTutorialButton")

func _ready():
	add_to_group("InteractiveTutorial")
	add_to_group("service_manager") # DEFENSIVE FIX: Allow Draggables to find this script as a service manager
	
	if is_instance_valid(tutorial_overlay):
		if not tutorial_overlay.pressed.is_connected(_on_tutorial_overlay_pressed):
			tutorial_overlay.pressed.connect(_on_tutorial_overlay_pressed)
	else:
		push_error("Tutorial Overlay not found! Check node path.")
		
	if is_instance_valid(skip_tutorial):
		if not skip_tutorial.pressed.is_connected(_on_skip_tutorial_pressed):
			skip_tutorial.pressed.connect(_on_skip_tutorial_pressed)
	else:
		push_warning("SkipTutorialButton not found! Check node path.")
		
	if is_instance_valid(serve_or_trash):
		serve_or_trash.visible = false
		serve_or_trash.z_index = 50
		drop_zones_default_position = serve_or_trash.global_position
		
	if is_instance_valid(kitchen_area):
		food_plate = kitchen_area.get_node_or_null("Plate/FoodPlate")
		if is_instance_valid(food_plate) and not food_plate.is_connected("drag_state_changed", _on_plate_drag_state_changed):
			food_plate.connect("drag_state_changed", _on_plate_drag_state_changed)
			
	play_step()

# =========================================================================
# --- ADVANCED INPUT LOCKING SYSTEM ---
# =========================================================================

func lock_all_inputs():
	var all_interactables = get_tree().get_nodes_in_group("interactable")
	if all_interactables.is_empty():
		push_warning("TUTORIAL WARNING: No nodes found in the 'interactable' group!")
		
	for item in all_interactables:
		if is_instance_valid(item):
			_set_node_interactable(item, false)

func unlock_item(target_node_name: String):
	if target_node_name == "": return 
		
	var all_interactables = get_tree().get_nodes_in_group("interactable")
	var found = false
	
	for item in all_interactables:
		if is_instance_valid(item) and target_node_name.to_lower() in item.name.to_lower():
			_set_node_interactable(item, true)
			print("Tutorial: Successfully unlocked -> ", item.name)
			found = true
			
	if not found:
		push_warning("Tutorial Warning: Could not find node containing '" + target_node_name + "'")

func unlock_all_inputs():
	var all_interactables = get_tree().get_nodes_in_group("interactable")
	for item in all_interactables:
		if is_instance_valid(item):
			_set_node_interactable(item, true)

func _set_node_interactable(node: Node, can_interact: bool):
	if not is_instance_valid(node) or node == skip_tutorial: return
		
	if "is_tutorial_locked" in node:
		node.is_tutorial_locked = not can_interact

	if "input_pickable" in node:
		node.input_pickable = can_interact
		
	elif node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP if can_interact else Control.MOUSE_FILTER_IGNORE
		if node is BaseButton:
			node.disabled = not can_interact

	for child in node.get_children():
		_set_node_interactable(child, can_interact)

# =========================================================================
# --- DROP ZONE CONTROL (SERVE & TRASH) ---
# =========================================================================

func move_zones_to_kitchen():
	if is_instance_valid(serve_or_trash):
		serve_or_trash.global_position = drop_zones_default_position

func move_zones_to_beverage(x_pos: float = 1240.0):
	if is_instance_valid(serve_or_trash):
		serve_or_trash.global_position = Vector2(x_pos, drop_zones_default_position.y)

func show_drop_zones():
	if is_instance_valid(serve_or_trash):
		serve_or_trash.visible = true

func hide_drop_zones():
	if is_instance_valid(serve_or_trash):
		serve_or_trash.visible = false
		move_zones_to_kitchen()

func _on_plate_drag_state_changed(is_dragging_now: bool):
	if not is_instance_valid(serve_or_trash): return

	if is_dragging_now:
		if is_instance_valid(food_plate) and food_plate.has_method("get_plate_contents"):
			var contents = food_plate.get_plate_contents()
			if contents.size() > 0:
				move_zones_to_kitchen()
				show_drop_zones()
		else:
			move_zones_to_kitchen()
			show_drop_zones()
	else:
		hide_drop_zones()

# =========================================================================

func trigger_rice_retry():
	if is_instance_valid(tutorial_overlay) and is_instance_valid(rice_retry_texture):
		is_in_retry_state = true
		tutorial_overlay.texture_normal = rice_retry_texture
		tutorial_overlay.show()
	else:
		push_error("Tutorial Error: Missing rice retry texture or overlay!")

func trigger_veggie_retry(): 
	if is_instance_valid(tutorial_overlay) and is_instance_valid(veggie_retry_texture):
		is_in_retry_state = true
		tutorial_overlay.texture_normal = veggie_retry_texture
		tutorial_overlay.show()
	else:
		push_error("Tutorial Error: Missing veggie retry texture or overlay!")

func play_step():
	lock_all_inputs()

	if current_phase >= tutorial_phases.size():
		finish_tutorial()
		return

	var phase_data: TutorialPhase = tutorial_phases[current_phase]
	var steps_array: Array[TutorialStep] = phase_data.steps

	if current_step >= steps_array.size():
		current_phase += 1  
		current_step = 0    
		play_step()         
		return

	var step_data: TutorialStep = steps_array[current_step]

	if step_data.station_change != "":
		switch_station(step_data.station_change)

	if step_data.step_type == TutorialStep.StepType.IMAGE:
		setup_image_step(step_data)
	elif step_data.step_type == TutorialStep.StepType.INTERACTIVE:
		setup_interactive_step(step_data)

func setup_image_step(step_data: TutorialStep):
	if is_instance_valid(tutorial_overlay):
		tutorial_overlay.show()
		if step_data.image != null:
			tutorial_overlay.texture_normal = step_data.image

func setup_interactive_step(step_data: TutorialStep):
	if is_instance_valid(tutorial_overlay): tutorial_overlay.hide()
	
	if step_data.node_to_unlock != "":
		unlock_item(step_data.node_to_unlock)
	
	if step_data.action_name == "OrderTicket_Close":
		get_tree().call_group("OrderTicketGroup", "allow_closing_from_tutorial")

func _on_tutorial_overlay_pressed():
	if is_in_retry_state:
		is_in_retry_state = false
		if is_instance_valid(tutorial_overlay): tutorial_overlay.hide()
		return
		
	if current_phase < tutorial_phases.size():
		var steps_array = tutorial_phases[current_phase].steps
		if current_step < steps_array.size():
			var step_data = steps_array[current_step]
			if step_data.step_type == TutorialStep.StepType.IMAGE:
				current_step += 1
				play_step()

func action_completed(action: String):
	if current_phase >= tutorial_phases.size(): return
	var steps_array = tutorial_phases[current_phase].steps
	if current_step >= steps_array.size(): return
	
	var step_data = steps_array[current_step]
	
	if step_data.step_type == TutorialStep.StepType.INTERACTIVE and step_data.action_name == action:
		print("✅ Tutorial Action Unlocked: ", action)
		current_step += 1
		play_step()

func switch_station(station: String):
	if is_instance_valid(kitchen_area): kitchen_area.hide()
	if is_instance_valid(beverage_station): beverage_station.hide()
	if is_instance_valid(lobby_canteen): lobby_canteen.hide()
	if is_instance_valid(serve_or_trash): serve_or_trash.hide()
	
	if station == "kitchen":
		if is_instance_valid(kitchen_area): kitchen_area.show()
	elif station == "beverage":
		if is_instance_valid(beverage_station): beverage_station.show()
	elif station == "lobby":
		if is_instance_valid(lobby_canteen): lobby_canteen.show()

func _on_skip_tutorial_pressed():
	print("⏭️ Player chose to skip the tutorial.")
	finish_tutorial()

func finish_tutorial():
	print("🎉 Tutorial Completely Finished!")
	if is_instance_valid(tutorial_overlay): tutorial_overlay.hide()
	unlock_all_inputs()
	
	# 🔥 FLAG TO AUTOSTART THE DAY
	if has_node("/root/GameData"):
		var gd = get_node("/root/GameData")
		if "auto_start_day" in gd:
			gd.auto_start_day = true
		if gd.has_method("start_next_day_flow"):
			gd.start_next_day_flow()
			return
		else:
			push_warning("GameData.start_next_day_flow() not found. Falling back to Lobby.")

	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
