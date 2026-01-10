extends Control

# --- SIGNALS ---
signal fill_finished(amount_str, amount_int)

# --- TIMING CONFIGURATION ---
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
@onready var progress_bar: Range = $ProgressBar 

func _ready():
	if button:
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
	
	if time_label:
		time_label.text = "HOLD ME"
		
	if progress_bar:
		progress_bar.max_value = TIME_PERFECT + 0.5 
		progress_bar.value = 0.0
		
		# Smooth animation
		if progress_bar.has_method("set_step"):
			progress_bar.step = 0.01 
		elif "step" in progress_bar:
			progress_bar.step = 0.01
			
		# FIX: Ensure the main node is WHITE (so borders don't get tinted)
		progress_bar.modulate = Color.WHITE
		
		# FIX: Initialize only the FILL color
		_apply_fill_color(Color.GRAY)

func _process(delta):
	if is_holding:
		hold_duration += delta
		
		if time_label:
			time_label.text = "%.1f s" % hold_duration
			
		if progress_bar:
			progress_bar.value = hold_duration
			_update_bar_color()

func _update_bar_color():
	if not progress_bar: return
	
	var target_color = Color.GRAY
	
	if hold_duration < TIME_TOO_FAST:
		target_color = Color.GRAY
	elif hold_duration < TIME_SMALL:
		target_color = Color.YELLOW
	elif hold_duration < TIME_MEDIUM:
		target_color = Color.ORANGE
	elif hold_duration <= TIME_PERFECT:
		target_color = Color.GREEN
	else:
		target_color = Color.RED
		
	# Apply the color to just the fill
	_apply_fill_color(target_color)

# --- NEW HELPER: Handles Color Application ---
func _apply_fill_color(color: Color):
	# Case 1: TextureProgressBar (Best for custom art)
	if progress_bar is TextureProgressBar:
		progress_bar.tint_progress = color
		
	# Case 2: Standard ProgressBar (Uses StyleBox)
	else:
		# Try to get the existing "fill" style
		var sb = progress_bar.get_theme_stylebox("fill")
		
		# If it's a flat style (editable color), change it
		if sb is StyleBoxFlat:
			sb.bg_color = color
		else:
			# If no custom style exists yet, create a new one
			var new_sb = StyleBoxFlat.new()
			new_sb.bg_color = color
			progress_bar.add_theme_stylebox_override("fill", new_sb)

func _on_button_down():
	is_holding = true
	hold_duration = 0.0
	if time_label: time_label.text = "0.0 s"
	
	if progress_bar: 
		progress_bar.value = 0.0
		_apply_fill_color(Color.GRAY)

func _on_button_up():
	if not is_holding: return
	is_holding = false
	calculate_result()

func calculate_result():
	var amount_int = 0
	var amount_str = "Fail"
	
	if hold_duration < TIME_TOO_FAST: 
		amount_int = 0 
		amount_str = "TooFast"
	elif hold_duration < TIME_SMALL: 
		amount_int = 1 
		amount_str = "Low"
	elif hold_duration < TIME_MEDIUM: 
		amount_int = 2 
		amount_str = "Medium"
	elif hold_duration <= TIME_PERFECT: 
		amount_int = 3 
		amount_str = "Right"
	else: 
		amount_int = 4 
		amount_str = "TooHigh"
	
	print("UI FINISHED: Held for %.2fs -> Result: %s" % [hold_duration, amount_str])
	emit_signal("fill_finished", amount_str, amount_int)
	queue_free()
