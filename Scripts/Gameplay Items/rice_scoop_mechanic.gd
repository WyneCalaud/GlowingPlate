extends Control

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
var hold_button: TextureButton = null 
var progress_bar: Range = null 

# --- SIGNALS ---
signal scoop_finished(amount: String)
signal score_change(deduction: int)

# --- CORE SETUP ---
func start_scoop_hold(cup_node: Node, cooker_name: String, _empty_texture: Texture2D, _scale_factor: float):
	parent_cup = cup_node
	is_mechanic_active = true
	
	# Disable cup input during mechanic
	var cup_area = parent_cup.get_node_or_null("Area2D")
	if is_instance_valid(cup_area):
		cup_area.input_pickable = false
	
	# 1. Instantiate UI
	ui_instance = RICE_SCOOP_UI_SCENE.instantiate()
	
	# 2. Find the Cooker and Parent the UI to it
	var cooker_node = get_tree().get_first_node_in_group(cooker_name)
	if cooker_node:
		# Parenting to the cooker makes the UI follow the cooker's transform automatically
		cooker_node.add_child(ui_instance)
		
		# Reset position to cooker's center, then apply a local offset
		# Adjust the Vector2(0, 50) to position it exactly where you want relative to the cooker sprite
		ui_instance.position = Vector2(0, 50) 
		ui_instance.z_index = 100
		print("DEBUG: UI attached to Cooker. Local position set.")
	else:
		# Fallback to root if cooker is missing
		get_tree().root.add_child(ui_instance)
		ui_instance.global_position = Vector2(20, 280)
		ui_instance.z_index = 100
		print("WARNING: Cooker node not found, falling back to global position.")

	# 3. Connect Button Signals
	hold_button = ui_instance.find_child("TextureButton")
	if hold_button:
		hold_button.connect("button_down", Callable(self, "_on_hold_button_down"))
		hold_button.connect("button_up", Callable(self, "_on_hold_button_up"))
	
	# 4. Setup Progress Bar
	progress_bar = ui_instance.find_child("ProgressBar") 
	if progress_bar:
		progress_bar.max_value = TIME_PERFECT + 0.5
		progress_bar.value = 0.0
		if "step" in progress_bar:
			progress_bar.step = 0.01
		_apply_fill_color(Color.GRAY)

func _process(delta):
	if is_mechanic_active and is_holding:
		hold_timer += delta
		if progress_bar:
			progress_bar.value = hold_timer
			_update_bar_color()

func _update_bar_color():
	if not progress_bar: return
	var target_color = Color.GRAY
	if hold_timer < TIME_TOO_FAST: target_color = Color.GRAY
	elif hold_timer < TIME_SMALL: target_color = Color.YELLOW
	elif hold_timer < TIME_MEDIUM: target_color = Color.ORANGE
	elif hold_timer <= TIME_PERFECT: target_color = Color.GREEN
	else: target_color = Color.RED
	_apply_fill_color(target_color)

func _apply_fill_color(color: Color):
	if progress_bar is TextureProgressBar:
		progress_bar.tint_progress = color
	elif progress_bar is ProgressBar:
		var sb = progress_bar.get_theme_stylebox("fill")
		if sb is StyleBoxFlat:
			sb.bg_color = color
		else:
			var new_sb = StyleBoxFlat.new()
			new_sb.bg_color = color
			progress_bar.add_theme_stylebox_override("fill", new_sb)

func _on_hold_button_down():
	is_holding = true
	hold_timer = 0.0
	if progress_bar:
		progress_bar.value = 0.0
		_apply_fill_color(Color.GRAY)

func _on_hold_button_up():
	is_holding = false
	var final_amount: String = ""
	if hold_timer < TIME_TOO_FAST: final_amount = "TooFast"
	elif hold_timer < TIME_SMALL: final_amount = "Small"
	elif hold_timer < TIME_MEDIUM: final_amount = "Medium" 
	elif hold_timer <= TIME_PERFECT: final_amount = "RightAmount" 
	else: final_amount = "TooHigh" 
	finish_scoop(final_amount)

func finish_scoop(amount: String):
	is_mechanic_active = false
	var cup_area = parent_cup.get_node_or_null("Area2D")
	if is_instance_valid(cup_area):
		cup_area.input_pickable = true
	if ui_instance:
		ui_instance.queue_free()
		ui_instance = null
	emit_signal("scoop_finished", amount)
	queue_free()
