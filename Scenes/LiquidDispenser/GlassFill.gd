# GlassFill.gd
extends Control

# --- SIGNALS ---
signal fill_finished(amount_str, amount_int)

# --- CONFIGURATION ---
const MIN_FILL_TIME: float = 1.0
const TIME_LOW: float = 2.0
const TIME_MED: float = 3.0
const TIME_FULL: float = 4.0        
const PENALTY_INTERVAL: float = 1.0 
const PENALTY_AMOUNT: int = 1

# Colors for the Progress Bar
const COLOR_START = Color.WHITE
const COLOR_PERFECT = Color.DEEP_SKY_BLUE
const COLOR_PENALTY_FLASH = Color.RED

# --- STATE ---
var hold_duration: float = 0.0
var is_holding: bool = false
var last_penalty_time: float = 4.0
var original_position: Vector2 

# Dynamic Scale Ratio (Inherited from Spawner)
var target_scale_ratio: float = 0.8 # Default fallback

# --- TUTORIAL SYSTEM ---
var is_tutorial_locked: bool = false

# --- NODES ---
@onready var button: BaseButton = $HoldButton
# We assume this UI is a child of the EmptyGlass node, so we look up the tree or siblings
var target_glass_sprite: Sprite2D 
var tex_original: Texture2D # To store the empty state
var scale_original: Vector2 = Vector2.ONE # To store the empty scale

@onready var progress_bar: TextureProgressBar = get_node_or_null("FillingIndicator")

# Texture references (For the Actual Glass Sprite)
var tex_low: Texture2D
var tex_med: Texture2D
var tex_right: Texture2D
var tex_too_high: Texture2D

func _ready():
	# --- TUTORIAL INJECTION ---
	add_to_group("interactable")
	name = "HoldButton" # Force the node name so the Tutorial Inspector finds it!

	if button:
		button.button_down.connect(_on_button_down)
		button.button_up.connect(_on_button_up)
	
	if progress_bar:
		progress_bar.max_value = TIME_FULL
		progress_bar.value = 0
		progress_bar.tint_progress = COLOR_START
		original_position = progress_bar.position 
	
	# FIND THE PARENT SPRITE (The actual Empty Glass)
	var parent = get_parent()
	if parent:
		# Try to find a Sprite2D child in the parent
		if parent.has_node("Sprite2D"):
			target_glass_sprite = parent.get_node("Sprite2D")
		else:
			for child in parent.get_children():
				if child is Sprite2D:
					target_glass_sprite = child
					break
		
		# Capture the original empty texture and scale so we can reset if needed
		if target_glass_sprite:
			tex_original = target_glass_sprite.texture
			scale_original = target_glass_sprite.scale

	_setup_textures_and_scale()

func _setup_textures_and_scale():
	var controllers = get_tree().get_nodes_in_group("global_controller")
	if controllers.size() > 0:
		var sc = controllers[0]
		var liquid = "water"
		if "selected_liquid" in sc:
			liquid = sc.selected_liquid.to_lower()
		
		# 1. Inherit Scale from Spawner Constants
		# We check if the constants exist on the controller instance to ensure correct ratio
		var filled_y = 2.0 
		var empty_y = 2.5 
		
		# Attempt to read constants from the spawner instance
		if "FILLED_GLASS_SCALE" in sc: filled_y = sc.FILLED_GLASS_SCALE.y
		if "EMPTY_GLASS_SCALE" in sc: empty_y = sc.EMPTY_GLASS_SCALE.y
		
		if empty_y != 0:
			target_scale_ratio = filled_y / empty_y
		
		# 2. Assign textures
		tex_low = sc.WATER_TEXTURE_LOW
		tex_med = sc.WATER_TEXTURE_MED
		tex_right = sc.WATER_TEXTURE_RIGHT
		tex_too_high = sc.WATER_TEXTURE_HIGH
		
		if liquid.contains("almondmilk"):
			tex_low = sc.ALMOND_MILK_TEXTURE_LOW
			tex_med = sc.ALMOND_MILK_TEXTURE_MED
			tex_right = sc.ALMOND_MILK_TEXTURE_RIGHT
			tex_too_high = sc.ALMOND_MILK_TEXTURE_HIGH
		elif liquid.contains("regularmilk"):
			tex_low = sc.MILK_TEXTURE_LOW
			tex_med = sc.MILK_TEXTURE_MED
			tex_right = sc.MILK_TEXTURE_RIGHT
			tex_too_high = sc.MILK_TEXTURE_HIGH

func _process(delta):
	if is_holding:
		hold_duration += delta
		_update_ui_realtime(delta)
		_check_penalty()

func _update_ui_realtime(_delta):
	if not progress_bar: return

	# 1. Update Progress Bar Value & Color
	progress_bar.value = hold_duration
	
	if not progress_bar.has_meta("is_flashing") or not progress_bar.get_meta("is_flashing"):
		if hold_duration <= TIME_FULL:
			var t = clamp(hold_duration / TIME_FULL, 0.0, 1.0)
			progress_bar.tint_progress = COLOR_START.lerp(COLOR_PERFECT, t)
		else:
			progress_bar.tint_progress = COLOR_PERFECT

	# Shaking Logic (Triggered when overfilling)
	if hold_duration > TIME_FULL:
		var shake_offset = Vector2(randf_range(-1.5, 1.5), randf_range(-1.5, 1.5))
		progress_bar.position = original_position + shake_offset
	else:
		progress_bar.position = original_position

	# 2. Update Actual Glass Sprite Texture & Scale
	if target_glass_sprite:
		var next_tex = null
		if hold_duration >= TIME_FULL:
			next_tex = tex_too_high
		elif hold_duration >= TIME_MED:
			next_tex = tex_right
		elif hold_duration >= TIME_LOW:
			next_tex = tex_med
		elif hold_duration >= MIN_FILL_TIME:
			next_tex = tex_low
		
		# Only update if we have a texture to show and it's different
		if next_tex and target_glass_sprite.texture != next_tex:
			target_glass_sprite.texture = next_tex
			# Apply calculated dynamic scale correction inherited from spawner
			target_glass_sprite.scale = Vector2(scale_original.x, scale_original.y * target_scale_ratio)

func _check_penalty():
	if hold_duration > last_penalty_time + PENALTY_INTERVAL:
		last_penalty_time += PENALTY_INTERVAL
		_trigger_penalty_event()

func _trigger_penalty_event():
	var gd = get_tree().get_first_node_in_group("GameData")
	if gd and gd.has_method("add_money"):
		gd.add_money(-PENALTY_AMOUNT)
	
	# 3. Flash the progress bar red
	if progress_bar:
		progress_bar.set_meta("is_flashing", true)
		var tween = create_tween()
		progress_bar.tint_progress = COLOR_PENALTY_FLASH
		tween.tween_property(progress_bar, "tint_progress", COLOR_PERFECT, 0.3)
		tween.tween_callback(func(): progress_bar.set_meta("is_flashing", false))

func _on_button_down():
	# Ignore input if the tutorial has locked this UI
	if is_tutorial_locked: return
	
	is_holding = true
	hold_duration = 0.0
	last_penalty_time = TIME_FULL
	
	# Reset Glass to Empty and Restore Scale
	if target_glass_sprite and tex_original:
		target_glass_sprite.texture = tex_original
		target_glass_sprite.scale = scale_original
		
	if progress_bar:
		progress_bar.value = 0
		progress_bar.position = original_position
		progress_bar.tint_progress = COLOR_START
		if progress_bar.has_meta("is_flashing"):
			progress_bar.set_meta("is_flashing", false)

func _on_button_up():
	if not is_holding: return
	is_holding = false
	
	if progress_bar:
		progress_bar.position = original_position
	
	if hold_duration < MIN_FILL_TIME:
		# Reset visuals if too fast
		if progress_bar: progress_bar.value = 0
		if target_glass_sprite and tex_original:
			target_glass_sprite.texture = tex_original
			target_glass_sprite.scale = scale_original
		return

	calculate_result()

func calculate_result():
	var amount_int = 0
	var amount_str = "TooFast"
	
	if hold_duration < MIN_FILL_TIME: amount_str = "TooFast"; amount_int = 0
	elif hold_duration < TIME_LOW: amount_str = "Low"; amount_int = 1
	elif hold_duration < TIME_MED: amount_str = "Medium"; amount_int = 2
	elif hold_duration < TIME_FULL: amount_str = "Right"; amount_int = 3
	else: amount_str = "TooHigh"; amount_int = 4
	
	emit_signal("fill_finished", amount_str, amount_int)
