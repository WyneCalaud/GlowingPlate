extends Control # Use Control as the base for a UI component

# --- CONFIGURATION ---
const RICE_SCOOP_UI_SCENE = preload("res://Scenes/Gameplay/RiceScoopUI.tscn") 

# Timing thresholds (in seconds)
const TIME_TOO_FAST: float = 1.0
const TIME_SMALL: float = 2.0
const TIME_MEDIUM: float = 3.0
const TIME_PERFECT: float = 4.0
const TIME_TOO_HIGH: float = 4.0

# --- STATE ---
var parent_cup: Node = null
var ui_instance: Control = null
var hold_timer: float = 0.0
var debug_timer: float = 0.0
var is_holding: bool = false
var is_mechanic_active: bool = false

# --- CACHED REFERENCES ---
@onready var hold_button: TextureButton = null 
var progress_bar: Range = null # Reference for the bar in the spawned UI

# --- SIGNALS ---
signal scoop_finished(amount: String)
signal score_change(deduction: int)

# --- CORE SETUP: Called by rice_cup.gd to start the mechanic ---
func start_scoop_hold(cup_node: Node, cooker_name: String, _empty_texture: Texture2D, _scale_factor: float):
	parent_cup = cup_node
	is_mechanic_active = true
	
	# CRITICAL FIX: Temporarily disable the cup's Area2D input 
	# to prevent the base class drag logic from interfering on mouse release.
	var cup_area = parent_cup.get_node_or_null("Area2D")
	if is_instance_valid(cup_area):
		cup_area.input_pickable = false
	
	# 1. Instantiate UI
	ui_instance = RICE_SCOOP_UI_SCENE.instantiate()
	get_tree().root.add_child(ui_instance) # Add to the root for better Z-indexing
	
	# 2. Setup Z-Index (Drawing Order)
	ui_instance.z_index = 100
	
	# 3. Position the UI
	var cooker_node = get_tree().get_first_node_in_group(cooker_name)
	if cooker_node and cooker_node is Node2D:
		var cooker_position = cooker_node.global_position
		# Offset it to place it under the rice cooker
		ui_instance.global_position = cooker_position + Vector2(168, 232)
		print("DEBUG: Setting UI position under cooker.")
	else:
		ui_instance.global_position = Vector2(20, 520)

	# 4. Connect Button Signals
	hold_button = ui_instance.find_child("TextureButton") # Find the button in the UI scene
	if hold_button:
		hold_button.connect("button_down", Callable(self, "_on_hold_button_down"))
		hold_button.connect("button_up", Callable(self, "_on_hold_button_up"))
		print("DEBUG: Hold button signals connected.")
	else:
		printerr("ERROR: Could not find TextureButton in RiceScoopUI.tscn.")

	# 5. FIND AND SETUP PROGRESS BAR (NEW)
	# This looks for a node named "ProgressBar" inside the instantiated UI
	progress_bar = ui_instance.find_child("ProgressBar") 
	if progress_bar:
		progress_bar.max_value = TIME_PERFECT + 0.5
		progress_bar.value = 0.0
		# Ensure smooth filling by setting step to a small value
		if progress_bar.has_method("set_step"):
			progress_bar.step = 0.01 
		elif "step" in progress_bar:
			progress_bar.step = 0.01
			
		# FIX: Set the whole node to White so borders aren't affected
		progress_bar.modulate = Color.WHITE
		# FIX: Initialize only the FILL color to Gray
		_apply_fill_color(Color.GRAY)
	else:
		print("DEBUG: No ProgressBar found in RiceScoopUI.tscn (Optional)")

# --- INPUT AND TIMER LOGIC ---

func _process(delta):
	if is_mechanic_active and is_holding:
		hold_timer += delta
		
		# --- Update Progress Bar (NEW) ---
		if progress_bar:
			progress_bar.value = hold_timer
			_update_bar_color()
		
		# --- Throttled Debug Output ---
		debug_timer += delta
		if debug_timer >= 0.1:
			# print("DEBUG: Hold Timer: %.2f" % hold_timer)
			debug_timer = 0.0

# --- HELPER: UPDATE BAR COLOR (NEW) ---
func _update_bar_color():
	if not progress_bar: return
	
	# Determine target color based on thresholds
	var target_color = Color.GRAY
	
	if hold_timer < TIME_TOO_FAST:
		target_color = Color.GRAY   # Too Fast / Nothing
	elif hold_timer < TIME_SMALL:
		target_color = Color.YELLOW # Small
	elif hold_timer < TIME_MEDIUM:
		target_color = Color.ORANGE # Medium
	elif hold_timer <= TIME_PERFECT:
		target_color = Color.GREEN  # Perfect!
	else:
		target_color = Color.RED    # Too High!
		
	# Apply color ONLY to the fill
	_apply_fill_color(target_color)

# --- NEW HELPER: Handles Color Application Specifics ---
func _apply_fill_color(color: Color):
	# Case 1: TextureProgressBar (Best for custom art)
	if progress_bar is TextureProgressBar:
		# 'tint_progress' only colors the filling texture, leaving under/over textures alone
		progress_bar.tint_progress = color
		
	# Case 2: Standard ProgressBar (Uses StyleBox)
	elif progress_bar is ProgressBar:
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

# --- HOLD BUTTON CALLBACKS ---

func _on_hold_button_down():
	is_holding = true
	hold_timer = 0.0 # Reset timer on press
	debug_timer = 0.0 # Reset debug timer
	
	# Reset bar visually
	if progress_bar:
		progress_bar.value = 0.0
		_apply_fill_color(Color.GRAY)
		
	print("Hold started.")

func _on_hold_button_up():
	is_holding = false
	print("Hold ended at time: %.2f" % hold_timer)
	
	var final_amount: String = ""
	
	# Determine the outcome based on the hold time
	if hold_timer < TIME_TOO_FAST: # < 1.0s
		final_amount = "TooFast"
		
	elif hold_timer < TIME_SMALL: # 1.0s to 1.9s
		final_amount = "Small"
		
	elif hold_timer < TIME_MEDIUM: # 2.0s to 2.9s
		final_amount = "Medium" 
		
	elif hold_timer <= TIME_PERFECT: # 3.0s to 4.0s (Matches hold_button.gd logic)
		final_amount = "RightAmount" 
		
	else: # > 4.0s
		final_amount = "TooHigh" 
	
	# Pass the result back to the RiceCup
	finish_scoop(final_amount)

# --- MECHANIC COMPLETION ---

func finish_scoop(amount: String):
	is_mechanic_active = false
	
	# CRITICAL FIX: Re-enable the cup's Area2D input now that the mechanic is done.
	var cup_area = parent_cup.get_node_or_null("Area2D")
	if is_instance_valid(cup_area):
		cup_area.input_pickable = true
	
	# 1. Remove the UI from the scene root
	if ui_instance:
		ui_instance.queue_free()
		ui_instance = null
	
	# 2. Emit signal back to the RiceCup to update its state
	emit_signal("scoop_finished", amount)
	
	# 3. Destroy this mechanic node
	queue_free()
