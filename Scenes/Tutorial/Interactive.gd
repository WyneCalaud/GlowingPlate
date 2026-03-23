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
@onready var tutorial_overlay = $TutorialUI/TutorialOverlaySteps

# --- Scene Tree References ---
@onready var kitchen_area = $KitchenArea
@onready var beverage_station = $BeverageStation
@onready var lobby_canteen = $LobbyCanteen
@onready var serve_or_trash = $ServeOrTrash

# --- Drop Zone & Plate Variables ---
var drop_zones_default_position: Vector2
var food_plate: Node2D = null

var current_phase: int = 0
var current_step: int = 0
var is_in_retry_state: bool = false

func _ready():
	add_to_group("InteractiveTutorial")
	
	if tutorial_overlay:
		tutorial_overlay.pressed.connect(_on_tutorial_overlay_pressed)
	else:
		push_error("Tutorial Overlay not found! Check node path.")
		
	# --- Setup Drop Zones (Serve & Trash) ---
	if serve_or_trash:
		serve_or_trash.visible = false
		serve_or_trash.z_index = 50
		drop_zones_default_position = serve_or_trash.global_position
		
	# --- Hook up the Plate Drag Signal ---
	if kitchen_area:
		food_plate = kitchen_area.get_node_or_null("Plate/FoodPlate")
		if food_plate and not food_plate.is_connected("drag_state_changed", _on_plate_drag_state_changed):
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
		_set_node_interactable(item, false)

func unlock_item(target_node_name: String):
	if target_node_name == "":
		return 
		
	var all_interactables = get_tree().get_nodes_in_group("interactable")
	var found = false
	
	for item in all_interactables:
		if item.name == target_node_name:
			_set_node_interactable(item, true)
			print("Tutorial: Successfully unlocked -> ", target_node_name)
			found = true
			break 
			
	if not found:
		push_warning("Tutorial Warning: Could not find node named '" + target_node_name + "'")

func unlock_all_inputs():
	var all_interactables = get_tree().get_nodes_in_group("interactable")
	for item in all_interactables:
		_set_node_interactable(item, true)

# THE MAGIC FUNCTION: This aggressively digs through the node to disable clicks!
func _set_node_interactable(node: Node, can_interact: bool):
	# 1. If this node has a custom variable called "is_tutorial_locked", set it!
	if "is_tutorial_locked" in node:
		node.is_tutorial_locked = not can_interact

	# 2. Disable standard Godot Collision (Area2D, StaticBody2D)
	if "input_pickable" in node:
		node.input_pickable = can_interact
		
	# 3. Disable UI Elements (Buttons, TextureRects)
	elif node is Control:
		node.mouse_filter = Control.MOUSE_FILTER_STOP if can_interact else Control.MOUSE_FILTER_IGNORE
		if node is BaseButton:
			node.disabled = not can_interact

	# 4. RECURSIVELY check all children (Fixes the Node2D root problem)
	for child in node.get_children():
		_set_node_interactable(child, can_interact)

# =========================================================================
# --- DROP ZONE CONTROL (SERVE & TRASH) ---
# =========================================================================

func move_zones_to_kitchen():
	if is_instance_valid(serve_or_trash):
		serve_or_trash.global_position = drop_zones_default_position

func show_drop_zones():
	if is_instance_valid(serve_or_trash):
		serve_or_trash.visible = true

func hide_drop_zones():
	if is_instance_valid(serve_or_trash):
		serve_or_trash.visible = false
		move_zones_to_kitchen()

func _on_plate_drag_state_changed(is_dragging_now: bool):
	if not is_instance_valid(serve_or_trash):
		return

	if is_dragging_now:
		# Check if the plate actually has food on it before showing Serve/Trash
		if food_plate and food_plate.has_method("get_plate_contents"):
			var contents = food_plate.get_plate_contents()
			if contents.size() > 0:
				move_zones_to_kitchen()
				show_drop_zones()
		else:
			# Fallback just in case get_plate_contents isn't available
			move_zones_to_kitchen()
			show_drop_zones()
	else:
		hide_drop_zones()

# =========================================================================

func trigger_rice_retry():
	if tutorial_overlay and rice_retry_texture:
		is_in_retry_state = true
		tutorial_overlay.texture_normal = rice_retry_texture
		tutorial_overlay.show()
	else:
		push_error("Tutorial Error: Missing rice retry texture or overlay!")

func trigger_veggie_retry(): 
	if tutorial_overlay and veggie_retry_texture:
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
	tutorial_overlay.show()
	if step_data.image != null:
		tutorial_overlay.texture_normal = step_data.image

func setup_interactive_step(step_data: TutorialStep):
	tutorial_overlay.hide()
	
	if step_data.node_to_unlock != "":
		unlock_item(step_data.node_to_unlock)
	
	if step_data.action_name == "OrderTicket_Close":
		get_tree().call_group("OrderTicketGroup", "allow_closing_from_tutorial")

func _on_tutorial_overlay_pressed():
	if is_in_retry_state:
		is_in_retry_state = false
		tutorial_overlay.hide()
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
	if kitchen_area: kitchen_area.hide()
	if beverage_station: beverage_station.hide()
	if lobby_canteen: lobby_canteen.hide()
	
	# Always hide serve_or_trash when changing stations. 
	# It will only reappear when the player picks up a plate!
	if serve_or_trash: serve_or_trash.hide()
	
	if station == "kitchen":
		if kitchen_area: kitchen_area.show()
	elif station == "beverage":
		if beverage_station: beverage_station.show()
	elif station == "lobby":
		if lobby_canteen: lobby_canteen.show()

func finish_tutorial():
	print("🎉 Tutorial Completely Finished!")
	if tutorial_overlay: tutorial_overlay.hide()
	unlock_all_inputs()
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
