# rice_cup.gd
extends "res://Scripts/Food Data/food_item_base.gd"

# --- RICE TYPE SELECTION ---
@export_enum("White", "Brown") var rice_type: String = "White"

# --- WHITE RICE TEXTURES ---
@export_group("White Rice Textures")
@export var wr_empty_cup: Texture2D
@export var wr_small_scoop: Texture2D
@export var wr_medium_scoop: Texture2D
@export var wr_full_cup: Texture2D
@export var wr_too_high: Texture2D

# --- BROWN RICE TEXTURES ---
@export_group("Brown Rice Textures")
@export var br_empty_cup: Texture2D
@export var br_small_scoop: Texture2D
@export var br_medium_scoop: Texture2D
@export var br_full_cup: Texture2D
@export var br_too_high: Texture2D

# --- CONFIG ---
@export var target_cooker_name: String = "RiceCooker" # Change this to "BrownRiceCooker" in the inspector for your brown rice cup
const RICE_SCOOP_MECHANIC_SCRIPT = preload("res://Scripts/Gameplay Items/rice_scoop_mechanic.gd")

# --- STATE ---
var is_empty := true
var current_rice_amount := "Empty"
var hovered_cooker: Node = null
var mechanic_instance: Node = null 

# Active textures cache
var tex_empty: Texture2D
var tex_small: Texture2D
var tex_medium: Texture2D
var tex_full: Texture2D
var tex_too_high: Texture2D

# --- NODES ---
@onready var rice_cup_area: Area2D = $Area2D

# --- SIGNALS ---
signal score_change(deduction: int)
signal rice_scoop_completed(rice_amount: String)

func _ready():
	if rice_type == "White":
		tex_empty = wr_empty_cup
		tex_small = wr_small_scoop
		tex_medium = wr_medium_scoop
		tex_full = wr_full_cup
		tex_too_high = wr_too_high
	else:
		tex_empty = br_empty_cup
		tex_small = br_small_scoop
		tex_medium = br_medium_scoop
		tex_full = br_full_cup
		tex_too_high = br_too_high

	texture = tex_empty
	super._ready()

	if rice_cup_area:
		rice_cup_area.input_pickable = true
		# Connect to the area's input event to lock camera on click
		rice_cup_area.input_event.connect(_on_rice_cup_input_event)

func set_camera_lock(is_locked: bool):
	if get_node_or_null("/root/Global"):
		get_node("/root/Global").camera_can_move = !is_locked
	
	# Try both the group call and the specific variable in CameraScroller
	get_tree().call_group("MainCamera", "set_is_input_blocked", is_locked)
	get_tree().call_group("MainCamera", "set_enabled", !is_locked)

# NEW: Handle initial click to lock camera
func _on_rice_cup_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			set_camera_lock(true)

# Flexible name checker to handle renamed nodes easily
func _is_target_cooker(node: Node) -> bool:
	if not is_instance_valid(node): return false
	var target = target_cooker_name.to_lower().replace(" ", "")
	var current = node.name.to_lower().replace(" ", "")
	return current.contains(target) or target.contains(current)

func _process(delta: float) -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	
	# Call parent process to retain base dragging behavior
	super._process(delta)
	
	# --- CRASH FIX: Distance-based closing ---
	# To prevent the infinite physics loop caused by the cooker's hitbox shrinking and shifting away,
	# we manually keep the cooker open based on distance while you are dragging it.
	if is_dragging and is_instance_valid(hovered_cooker):
		var dist = global_position.distance_to(hovered_cooker.global_position)
		if dist > 250.0: # Safe pixel radius. Close if dragged completely away.
			_close_current_cooker()
			hovered_cooker = null
			current_hovered_area = null

func _on_area_2d_area_entered(area: Area2D) -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	super._on_area_2d_area_entered(area)
	
	if not is_instance_valid(area): return
	
	var parent = area.get_parent()
	
	# CRASH FIX 2: Only interact with the cooker when actively dragging.
	if is_instance_valid(parent) and _is_target_cooker(parent):
		if is_dragging:
			hovered_cooker = parent
			if hovered_cooker.has_method("open_cooker"):
				hovered_cooker.open_cooker()

func _on_area_2d_area_exited(area: Area2D) -> void:
	if not is_inside_tree() or is_queued_for_deletion(): return
	
	if is_instance_valid(area):
		var parent = area.get_parent()
		# ONLY close via the physics exit event if we dropped the cup. 
		# If we are dragging, _process handles the distance checking to prevent the crash loop.
		if is_instance_valid(hovered_cooker) and parent == hovered_cooker and not is_dragging:
			_close_current_cooker()
			hovered_cooker = null
	super._on_area_2d_area_exited(area)

func handle_drop():
	if not is_inside_tree() or is_queued_for_deletion(): return
	
	# Unlock camera whenever the item is released
	set_camera_lock(false)

	var cooker_area_found = false
	
	# Since we bypassed area_exited while dragging, check our persistent distance state first
	if is_instance_valid(hovered_cooker):
		var dist = global_position.distance_to(hovered_cooker.global_position)
		if dist <= 250.0:
			cooker_area_found = true
	# Fallback if the physics engine found it at the exact moment of drop
	elif is_instance_valid(current_hovered_area) and is_instance_valid(current_hovered_area.get_parent()):
		if _is_target_cooker(current_hovered_area.get_parent()):
			cooker_area_found = true
			hovered_cooker = current_hovered_area.get_parent()

	if cooker_area_found and is_empty:
		if not is_instance_valid(mechanic_instance):
			start_hold_mechanic()
			return

	if is_empty and not cooker_area_found:
		_close_current_cooker()
		hovered_cooker = null # Ensure clean state
		return_to_start()
		return

	_close_current_cooker()
	hovered_cooker = null # Ensure clean state
	
	# CRITICAL FIX: Manually check for plate slots to ensure 100% responsive drops!
	_perform_manual_overlap_check()
	
	super.handle_drop()

func on_plate_placement_success():
	reset_cup()

func reset_cup():
	is_empty = true
	current_rice_amount = "Empty"
	texture = tex_empty
	return_to_start()

func start_hold_mechanic():
	print("DEBUG [RiceCup]: Starting hold mechanic.")
	is_dragging = false
	z_index = 0 
	current_hovered_area = null
	set_camera_lock(true)

	mechanic_instance = RICE_SCOOP_MECHANIC_SCRIPT.new()
	add_child(mechanic_instance)

	mechanic_instance.connect("score_change", Callable(self, "_on_mechanic_score_change"))
	mechanic_instance.connect("scoop_finished", Callable(self, "_on_mechanic_scoop_finished"))

	# Pass the node's name as a string since the mechanic script expects a String
	if is_instance_valid(hovered_cooker):
		mechanic_instance.start_scoop_hold(self, hovered_cooker.name)

func _on_mechanic_score_change(deduction: int):
	emit_signal("score_change", deduction)

func _on_mechanic_scoop_finished(amount: String):
	if not is_inside_tree() or is_queued_for_deletion(): return
	
	set_camera_lock(false)
	if is_instance_valid(rice_cup_area):
		rice_cup_area.input_pickable = true

	# --- MAPPING FIX ---
	# Translate the strings coming from the UI into standard game variables
	var mapped_amount = amount
	if amount == "Right": 
		mapped_amount = "RightAmount"
	elif amount == "Low": 
		mapped_amount = "Small"

	current_rice_amount = mapped_amount
	print("DEBUG [RiceCup]: Mechanic scoop finished, amount -> ", mapped_amount)

	var final_texture := tex_empty
	var success := true

	match mapped_amount:
		"RightAmount":
			final_texture = tex_full
		"Small":
			final_texture = tex_small
		"Medium":
			final_texture = tex_medium
		"TooHigh":
			final_texture = tex_too_high
		_:
			success = false

	texture = final_texture
	is_empty = !success

	_close_current_cooker()
	
	# CRITICAL FIX 3: Completely sever cooker reference BEFORE flying back to start.
	# Prevents expanded cooker hitboxes from grabbing the cup again while tweening.
	hovered_cooker = null 
	return_to_start()

	if mapped_amount == "RightAmount":
		emit_signal("rice_scoop_completed", mapped_amount)

	mechanic_instance = null

func _close_current_cooker():
	if is_instance_valid(hovered_cooker) and hovered_cooker.has_method("close_cooker"):
		hovered_cooker.close_cooker()

# --- RECOVERY: MANUAL OVERLAP CHECK ---
func _perform_manual_overlap_check():
	var area_node = get_node_or_null("Area2D")
	if not area_node: return

	var overlapping = area_node.get_overlapping_areas()
	for area in overlapping:
		# Ignore self
		if area == area_node or area.owner == self or area.get_parent() == self: 
			continue
		
		# Check if the area is a plate slot
		if area.is_in_group("plate_slot") or (area.get_parent() and area.get_parent().is_in_group("plate_slot")):
			current_hovered_area = area
			print("RECOVERY [RiceCup]: Plate Slot detected manually.")
			return
