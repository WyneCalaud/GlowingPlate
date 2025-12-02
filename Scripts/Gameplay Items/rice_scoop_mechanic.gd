extends Control # Use Control as the base for a UI component

# --- CONFIGURATION ---
const RICE_SCOOP_UI_SCENE = preload("res://Scenes/Gameplay/RiceScoopUI.tscn") # Assume you have a scene for the UI (e.g., the Hold button)

# Timing thresholds (in seconds) - UPDATED TO NEW RANGES
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

# --- CACHED REFERENCES for UI elements (Assuming RiceScoopUI.tscn structure) ---
@onready var hold_button: TextureButton = null # Will be set during instantiation

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
	
	# 3. Position the UI (REVERTED TO ORIGINAL POSITIONING LOGIC)
	var cooker_node = get_tree().get_first_node_in_group(cooker_name)
	if cooker_node and cooker_node is Node2D:
		var cooker_position = cooker_node.global_position
		# Offset it to place it under the rice cooker
		ui_instance.global_position = cooker_position + Vector2(-50, 350)
		print("DEBUG: Setting UI position under cooker.")
	else:
		ui_instance.global_position = Vector2(-480, 300)

	# 4. Connect Button Signals
	hold_button = ui_instance.find_child("TextureButton") # Find the button in the UI scene
	if hold_button:
		hold_button.connect("button_down", Callable(self, "_on_hold_button_down"))
		hold_button.connect("button_up", Callable(self, "_on_hold_button_up"))
		print("DEBUG: Hold button signals connected.")
	else:
		printerr("ERROR: Could not find TextureButton in RiceScoopUI.tscn.")

# --- INPUT AND TIMER LOGIC ---

func _process(delta):
	if is_mechanic_active and is_holding:
		hold_timer += delta
		
		# --- Throttled Debug Output ---
		debug_timer += delta
		if debug_timer >= 0.1:
			print("DEBUG: Hold Timer: %.2f" % hold_timer)
			debug_timer = 0.0

# --- HOLD BUTTON CALLBACKS ---

func _on_hold_button_down():
	is_holding = true
	hold_timer = 0.0 # Reset timer on press
	debug_timer = 0.0 # Reset debug timer
	print("Hold started.")

func _on_hold_button_up():
	is_holding = false
	print("Hold ended at time: %.2f" % hold_timer)
	
	var final_amount: String = ""
	
	# Determine the outcome based on the hold time (New Ranges)
	if hold_timer < TIME_TOO_FAST: # < 1.0s
		final_amount = "TooFast"
		
	elif hold_timer < TIME_SMALL: # 1.0s to 1.9s
		final_amount = "Small"
		
	elif hold_timer < TIME_MEDIUM: # 2.0s to 2.9s
		final_amount = "Medium" # NEW NAME
		
	elif hold_timer < TIME_PERFECT: # 3.0s to 3.9s
		final_amount = "RightAmount" # NEW NAME (The only successful state)
		
	else: # hold_timer >= 4.0s
		final_amount = "TooHigh" # NEW NAME (Burnt)
	
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
