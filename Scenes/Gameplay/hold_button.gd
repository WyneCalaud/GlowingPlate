# hold_button.gd
extends Control

# --- SIGNALS ---
signal fill_finished(amount_str, amount_int)

# --- TIMING CONFIGURATION ---
const TIME_TOO_FAST: float = 1.0
const TIME_SMALL: float = 2.0
const TIME_MEDIUM: float = 3.0
const TIME_PERFECT: float = 4.0
# > 4.0 is Too High

# --- TEXTURES ---
@export var tex_empty: Texture2D
@export var tex_low: Texture2D
@export var tex_med: Texture2D
@export var tex_right: Texture2D
@export var tex_too_high: Texture2D

var hold_duration: float = 0.0
var is_holding: bool = false

# --- NODES ---
# Ensure these paths match your scene tree exactly
@onready var button: BaseButton = $VBoxContainer/HoldButton
@onready var time_label: Label = $VBoxContainer/Label
@onready var cup_display: TextureRect = $CupProgress 

func _ready():
	if button:
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
	
	if time_label:
		time_label.text = "HOLD ME"
		
	# Initialize visual state
	if cup_display:
		cup_display.texture = tex_empty

func _process(delta):
	if is_holding:
		hold_duration += delta
		
		if time_label:
			time_label.text = "%.1f s" % hold_duration
			
		_update_cup_texture()

func _update_cup_texture():
	if not cup_display: return
	
	var next_tex = tex_empty
	
	if hold_duration < TIME_TOO_FAST:
		next_tex = tex_empty
	elif hold_duration < TIME_SMALL:
		next_tex = tex_low
	elif hold_duration < TIME_MEDIUM:
		next_tex = tex_med
	elif hold_duration <= TIME_PERFECT:
		next_tex = tex_right
	else:
		next_tex = tex_too_high
		
	# Only update if changed to save performance
	if cup_display.texture != next_tex:
		cup_display.texture = next_tex

func _on_button_down():
	is_holding = true
	hold_duration = 0.0
	if time_label: time_label.text = "0.0 s"
	
	# Reset visual
	if cup_display:
		cup_display.texture = tex_empty

func _on_button_up():
	if not is_holding: return
	is_holding = false
	calculate_result()

func calculate_result():
	var amount_int = 0
	var amount_str = "TooFast"
	
	# Logic MUST match rice_cup.gd expectations
	if hold_duration < TIME_TOO_FAST: 
		amount_int = 0 
		amount_str = "TooFast"
	elif hold_duration < TIME_SMALL: 
		amount_int = 1 
		amount_str = "Small"
	elif hold_duration < TIME_MEDIUM: 
		amount_int = 2 
		amount_str = "Medium"
	elif hold_duration <= TIME_PERFECT: 
		amount_int = 3 
		amount_str = "RightAmount" 
	else: 
		amount_int = 4 
		amount_str = "TooHigh"
	
	print("UI FINISHED: Held for %.2fs -> Result: %s" % [hold_duration, amount_str])
	emit_signal("fill_finished", amount_str, amount_int)
	
	# IMPORTANT: Do NOT queue_free() here. The parent mechanic script handles it.
