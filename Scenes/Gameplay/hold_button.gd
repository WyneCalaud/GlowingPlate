extends Control

# --- SIGNALS ---
signal fill_finished(amount_str, amount_int)

# --- TIMING CONFIGURATION (Matched to rice_scoop_mechanic.gd) ---
const TIME_TOO_FAST: float = 1.0
const TIME_SMALL: float = 2.0
const TIME_MEDIUM: float = 3.0
const TIME_PERFECT: float = 4.0
# > 4.0 is Too High

var hold_duration: float = 0.0
var is_holding: bool = false

# --- NODES ---
@onready var button: BaseButton = $VBoxContainer/TextureButton
@onready var time_label: Label = $VBoxContainer/Label

func _ready():
	if button:
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
	
	if time_label:
		time_label.text = "HOLD ME"

func _process(delta):
	if is_holding:
		hold_duration += delta
		if time_label:
			time_label.text = "%.1f s" % hold_duration

func _on_button_down():
	is_holding = true
	hold_duration = 0.0
	if time_label:
		time_label.text = "0.0 s"

func _on_button_up():
	if not is_holding: return
	is_holding = false
	calculate_result()

func calculate_result():
	var amount_int = 0
	var amount_str = "Fail"
	
	# Logic matches rice_scoop_mechanic.gd
	if hold_duration < TIME_TOO_FAST: # < 1.0s
		amount_int = 0 # Too Fast / Fail
		amount_str = "TooFast"
		
	elif hold_duration < TIME_SMALL: # 1.0s - 1.99s
		amount_int = 1 # Low
		amount_str = "Low"
		
	elif hold_duration < TIME_MEDIUM: # 2.0s - 2.99s
		amount_int = 2 # Medium
		amount_str = "Medium"
		
	elif hold_duration < TIME_PERFECT: # 3.0s - 3.99s
		amount_int = 3 # Right (Perfect)
		amount_str = "Right"
		
	else: # >= 4.0s
		amount_int = 4 # Too High
		amount_str = "TooHigh"
	
	print("UI FINISHED: Held for %.2fs -> Result: %s" % [hold_duration, amount_str])
	
	# Emit result back to Empty Glass
	emit_signal("fill_finished", amount_str, amount_int)
	
	queue_free()
