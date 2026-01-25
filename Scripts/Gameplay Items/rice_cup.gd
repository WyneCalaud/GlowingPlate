extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var empty_cup_texture: Texture2D
@export var small_scoop_texture: Texture2D
@export var medium_scoop_texture: Texture2D
@export var full_cup_texture: Texture2D
@export var too_high_texture: Texture2D

# --- NEW SCALE FACTORS ---
@export var empty_cup_texture_factor: float = 0.4
@export var small_scoop_scale_factor: float = 0.2 
@export var medium_scoop_scale_factor: float = 0.2 
@export var full_cup_scale_factor: float = 0.15 
@export var too_high_scale_factor: float = 0.2 

# --- RICE SCOOP MECHANIC CONFIGURATION ---
const RICE_COOKER_NAME = "RiceCooker" 

# --- CACHED RESOURCES ---
const RICE_SCOOP_MECHANIC_SCRIPT = preload("res://Scripts/Gameplay Items/rice_scoop_mechanic.gd")

# --- STATE ---
var is_empty: bool = true 
var current_rice_amount: String = "Empty"
var hovered_cooker: Node = null

# --- CACHED NODES ---
@onready var rice_cup_area: Area2D = $Area2D
var mechanic_instance: Node = null 

# --- SIGNALS ---
signal score_change(deduction: int)
signal rice_scoop_completed(rice_amount: String)

func _ready():
	texture = empty_cup_texture 
	scale = Vector2(empty_cup_texture_factor, empty_cup_texture_factor)
	is_empty = true 
	current_rice_amount = "Empty"
	super._ready()
	
	if is_instance_valid(rice_cup_area):
		rice_cup_area.input_pickable = true
		_update_hitbox_scale(empty_cup_texture_factor)

# --- CAMERA LOCK LOGIC ---
# This assumes you have a Global script or can access your Camera script
func set_camera_lock(is_locked: bool):
	# Option A: If using a Global/Autoload script
	if get_node_or_null("/root/Global"):
		get_node("/root/Global").camera_can_move = !is_locked
	
	# Option B: Use a group if your camera is in one
	get_tree().call_group("MainCamera", "set_enabled", !is_locked)

# --- OVERRIDING BASE DRAG LOGIC ---
# We lock camera when we pick up the cup
func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	super._on_area_2d_input_event(viewport, event, shape_idx)
	if is_dragging:
		set_camera_lock(true)

func _on_area_2d_area_entered(area: Area2D) -> void:
	super._on_area_2d_area_entered(area) 
	
	var parent = area.get_parent()
	if parent and parent.name == RICE_COOKER_NAME:
		hovered_cooker = parent
		if hovered_cooker.has_method("open_cooker"):
			hovered_cooker.open_cooker()

func _on_area_2d_area_exited(area: Area2D) -> void:
	var parent = area.get_parent()
	if parent == hovered_cooker:
		_close_current_cooker()
		hovered_cooker = null
	
	super._on_area_2d_area_exited(area) 

func _close_current_cooker():
	if hovered_cooker and hovered_cooker.has_method("close_cooker"):
		hovered_cooker.close_cooker()

# --- OVERRIDING BASE DROP LOGIC ---
func handle_drop():
	# Unlock camera whenever the item is released
	set_camera_lock(false)
	
	var cooker_area_found = false
	if current_hovered_area and current_hovered_area.get_parent():
		cooker_area_found = current_hovered_area.get_parent().name == RICE_COOKER_NAME
	
	if cooker_area_found:
		if is_empty:
			start_hold_mechanic()
			return 
		else:
			_close_current_cooker()
			return_to_start()
			return 

	_close_current_cooker()
	super.handle_drop()

func on_plate_placement_success():
	set_camera_lock(false) # Safety unlock
	texture = empty_cup_texture
	scale = Vector2(empty_cup_texture_factor, empty_cup_texture_factor) 
	_update_hitbox_scale(empty_cup_texture_factor)
	is_empty = true
	current_rice_amount = "Empty"
	return_to_start()

# --- MECHANIC LOGIC ---
func start_hold_mechanic():
	if mechanic_instance != null and is_instance_valid(mechanic_instance):
		return
	# Re-lock camera during the hold mechanic phase
	set_camera_lock(true)
	
	mechanic_instance = RICE_SCOOP_MECHANIC_SCRIPT.new()
	add_child(mechanic_instance)
	mechanic_instance.connect("score_change", Callable(self, "_on_mechanic_score_change"))
	mechanic_instance.connect("scoop_finished", Callable(self, "_on_mechanic_scoop_finished"))
	mechanic_instance.start_scoop_hold(self, RICE_COOKER_NAME, empty_cup_texture, full_cup_scale_factor)

func _on_mechanic_score_change(deduction: int):
	emit_signal("score_change", deduction)

func _on_mechanic_scoop_finished(amount: String):
	# Unlock camera when the mechanic finishes
	set_camera_lock(false)
	
	current_rice_amount = amount
	var final_texture: Texture2D = empty_cup_texture
	var target_scale: float = empty_cup_texture_factor
	var is_scoop_successful: bool = true 
	
	match amount:
		"RightAmount":
			final_texture = full_cup_texture
			target_scale = full_cup_scale_factor
		"Small":
			final_texture = small_scoop_texture
			target_scale = small_scoop_scale_factor
		"Medium":
			final_texture = medium_scoop_texture
			target_scale = medium_scoop_scale_factor
		"TooHigh":
			final_texture = too_high_texture
			target_scale = too_high_scale_factor
		"TooFast":
			is_scoop_successful = false
		_:
			is_scoop_successful = false
	
	texture = final_texture
	scale = Vector2(target_scale, target_scale)
	is_empty = !is_scoop_successful
	
	_update_hitbox_scale(target_scale)
	_close_current_cooker()
	return_to_start()

	if amount == "RightAmount":
		emit_signal("rice_scoop_completed", amount)
	
	if mechanic_instance:
		mechanic_instance.queue_free()
		mechanic_instance = null

func _update_hitbox_scale(current_scale: float):
	if is_instance_valid(rice_cup_area):
		rice_cup_area.scale = Vector2(0.5 / current_scale, 0.5 / current_scale)
