# rice_cup.gd
extends "res://Scripts/Food Data/food_item_base.gd"

# --- UNIQUE EXPORTS ---
@export var empty_cup_texture: Texture2D
@export var small_scoop_texture: Texture2D
@export var medium_scoop_texture: Texture2D
@export var full_cup_texture: Texture2D
@export var too_high_texture: Texture2D

# --- SCALE FACTORS ---
@export var empty_cup_texture_factor: float = 0.4
@export var small_scoop_scale_factor: float = 0.2 
@export var medium_scoop_scale_factor: float = 0.2 
@export var full_cup_scale_factor: float = 0.15 
@export var too_high_scale_factor: float = 0.2 

# --- CONFIG ---
const RICE_COOKER_NAME = "RiceCooker" 
const RICE_SCOOP_MECHANIC_SCRIPT = preload("res://Scripts/Gameplay Items/rice_scoop_mechanic.gd")

# --- STATE ---
var is_empty := true
var current_rice_amount := "Empty"
var hovered_cooker: Node = null
var mechanic_instance: Node = null 

# --- NODES ---
@onready var rice_cup_area: Area2D = $Area2D

# --- SIGNALS ---
signal score_change(deduction: int)
signal rice_scoop_completed(rice_amount: String)

func _ready():
	texture = empty_cup_texture
	scale = Vector2(empty_cup_texture_factor, empty_cup_texture_factor)
	super._ready()

	if rice_cup_area:
		rice_cup_area.input_pickable = true
		_update_hitbox_scale(empty_cup_texture_factor)
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

func handle_drop():
	# Unlock camera whenever the item is released
	set_camera_lock(false)

	var cooker_area_found := (
		current_hovered_area
		and current_hovered_area.get_parent()
		and current_hovered_area.get_parent().name == RICE_COOKER_NAME
	)

	if cooker_area_found and is_empty:
		if not mechanic_instance:
			start_hold_mechanic()
			return

	if is_empty and not cooker_area_found:
		_close_current_cooker()
		return_to_start()
		return

	_close_current_cooker()
	super.handle_drop()

func on_plate_placement_success():
	reset_cup()

func reset_cup():
	is_empty = true
	current_rice_amount = "Empty"
	texture = empty_cup_texture
	scale = Vector2(empty_cup_texture_factor, empty_cup_texture_factor)
	_update_hitbox_scale(empty_cup_texture_factor)
	return_to_start()

func start_hold_mechanic():
	is_dragging = false
	z_index = 0 
	current_hovered_area = null
	set_camera_lock(true)

	mechanic_instance = RICE_SCOOP_MECHANIC_SCRIPT.new()
	add_child(mechanic_instance)

	mechanic_instance.connect("score_change", Callable(self, "_on_mechanic_score_change"))
	mechanic_instance.connect("scoop_finished", Callable(self, "_on_mechanic_scoop_finished"))

	mechanic_instance.start_scoop_hold(self, RICE_COOKER_NAME)

func _on_mechanic_score_change(deduction: int):
	emit_signal("score_change", deduction)

func _on_mechanic_scoop_finished(amount: String):
	set_camera_lock(false)
	if rice_cup_area:
		rice_cup_area.input_pickable = true

	current_rice_amount = amount

	var final_texture := empty_cup_texture
	var target_scale := empty_cup_texture_factor
	var success := true

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
		_:
			success = false

	texture = final_texture
	scale = Vector2(target_scale, target_scale)
	is_empty = !success
	_update_hitbox_scale(target_scale)

	_close_current_cooker()
	return_to_start()

	if amount == "RightAmount":
		emit_signal("rice_scoop_completed", amount)

	mechanic_instance = null

func _close_current_cooker():
	if hovered_cooker and hovered_cooker.has_method("close_cooker"):
		hovered_cooker.close_cooker()

func _update_hitbox_scale(current_scale: float):
	if rice_cup_area:
		rice_cup_area.scale = Vector2(0.5 / current_scale, 0.5 / current_scale)
