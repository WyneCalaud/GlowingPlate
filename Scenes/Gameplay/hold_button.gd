# hold_button.gd
extends Control

# --- SIGNALS ---
signal fill_finished(amount_str, amount_int)
signal popup_closed # NEW: Emitted when the player clicks outside to close

# --- TIMING CONFIGURATION ---
const TIME_TOO_FAST: float = 0.5
const TIME_LOW: float = 1.0
const TIME_MEDIUM: float = 2.0
const TIME_RIGHT: float = 3.0
const TIME_FULL: float = 4.0
const PENALTY_INTERVAL: float = 1.0 # Every 1 second over 4s

# --- RICE TYPE SELECTION ---
@export_enum("White", "Brown") var default_rice_type: String = "White"

# --- WHITE RICE TEXTURES ---
@export_group("White Rice Textures")
@export var wr_empty: Texture2D
@export var wr_low: Texture2D
@export var wr_med: Texture2D
@export var wr_right: Texture2D
@export var wr_too_high: Texture2D

# --- BROWN RICE TEXTURES ---
@export_group("Brown Rice Textures")
@export var br_empty: Texture2D
@export var br_low: Texture2D
@export var br_med: Texture2D
@export var br_right: Texture2D
@export var br_too_high: Texture2D

var hold_duration: float = 0.0
var is_holding: bool = false
var last_penalty_time: float = 4.0

# Active textures cache
var tex_empty: Texture2D
var tex_low: Texture2D
var tex_med: Texture2D
var tex_right: Texture2D
var tex_too_high: Texture2D

# --- NODES ---
@onready var button: BaseButton = $VBoxContainer/HoldButton
@onready var cup_display: TextureRect = $CupProgress 

func _ready():
	set_rice_type(default_rice_type)
	
	if button:
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
		
	if cup_display:
		cup_display.texture = tex_empty

# --- NEW: CLICK OUTSIDE TO CLOSE MECHANIC ---
func _input(event: InputEvent) -> void:
	# Check if the popup is visible and the user left-clicks
	if visible and event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = event.global_position
		
		# If the click position is OUTSIDE the bounding box of this Control node
		if not get_global_rect().has_point(click_pos):
			# Consume the input so it doesn't accidentally click things behind the popup
			get_viewport().set_input_as_handled()
			close_scoop()

func close_scoop() -> void:
	if is_holding: return # Prevent closing if they dragged outside while holding the fill button
	
	hide() # Or you can use queue_free() if you spawn a new one every time
	popup_closed.emit()
# --------------------------------------------

func set_rice_type(type: String):
	if type == "Brown":
		tex_empty = br_empty
		tex_low = br_low
		tex_med = br_med
		tex_right = br_right
		tex_too_high = br_too_high
	else:
		tex_empty = wr_empty
		tex_low = wr_low
		tex_med = wr_med
		tex_right = wr_right
		tex_too_high = wr_too_high
		
	if cup_display and not is_holding:
		cup_display.texture = tex_empty

func _process(delta):
	if is_holding:
		hold_duration += delta
			
		_update_cup_texture()
		_check_penalty(delta)

func _check_penalty(_delta):
	if hold_duration > TIME_FULL:
		if hold_duration >= last_penalty_time + PENALTY_INTERVAL:
			apply_waste_penalty()
			last_penalty_time += PENALTY_INTERVAL

func apply_waste_penalty():
	print("PENALTY: Overfilling! -$1.00")
	var gd = get_tree().get_first_node_in_group("GameData")
	if gd and gd.has_method("adjust_money"):
		gd.adjust_money(-1.0)

func _update_cup_texture():
	if not cup_display: return
	
	var next_tex = tex_empty
	
	if hold_duration < TIME_TOO_FAST:
		next_tex = tex_empty
	elif hold_duration < TIME_LOW:
		next_tex = tex_low
	elif hold_duration < TIME_MEDIUM:
		next_tex = tex_med
	elif hold_duration < TIME_RIGHT:
		next_tex = tex_right
	else:
		next_tex = tex_too_high
		
	if cup_display.texture != next_tex:
		cup_display.texture = next_tex

func _on_button_down():
	is_holding = true
	hold_duration = 0.0
	last_penalty_time = TIME_FULL
	if cup_display: cup_display.texture = tex_empty

func _on_button_up():
	if not is_holding: return
	is_holding = false
	calculate_result()

func calculate_result():
	var amount_int = 0
	var amount_str = "TooFast"
	
	if hold_duration < TIME_TOO_FAST: 
		amount_int = 0 
		amount_str = "TooFast"
	elif hold_duration < TIME_LOW: 
		amount_int = 1 
		amount_str = "Low"
	elif hold_duration < TIME_MEDIUM: 
		amount_int = 2 
		amount_str = "Medium"
	elif hold_duration < TIME_RIGHT: 
		amount_int = 3 
		amount_str = "Right" 
	else: 
		amount_int = 4 
		amount_str = "TooHigh"
	
	emit_signal("fill_finished", amount_str, amount_int)
