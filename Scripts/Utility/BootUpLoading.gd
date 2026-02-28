extends Control

# We only need one path now, since the Main Menu handles the intro logic!
@export_file("*.tscn") var main_menu_scene_path: String = "res://Scenes/Main Menu/Main_menu.tscn"

# How long the loading screen should stay visible (in seconds)
@export var display_time: float = 5.0

# Connect this to your ProgressBar node. 
@onready var progress_bar = get_node_or_null("ProgressBar")

var active_tween: Tween

func _ready() -> void:
	# CRASH-PROOF: Set engine clear color to black immediately upon boot
	RenderingServer.set_default_clear_color(Color.BLACK)
	
	# Hide the mouse cursor during the splash screen
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

	# Check if the progress bar exists so the game doesn't crash if it's missing
	if progress_bar:
		progress_bar.min_value = 0
		progress_bar.max_value = 100
		progress_bar.value = 0

		# Create a safe Tween to smoothly fill the bar
		active_tween = create_tween()
		active_tween.tween_property(progress_bar, "value", 100.0, display_time)
		
		await active_tween.finished
	else:
		printerr("BootUpLoading: ProgressBar node not found! Make sure you added one and named it 'ProgressBar'.")
		await get_tree().create_timer(display_time).timeout

	# SAFETY CHECK: If the game was closed while waiting, stop right here
	if not is_inside_tree():
		return

	# Bring the mouse cursor back before changing scenes
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	# Transition to the next scene
	_transition_to_next_scene()

func _transition_to_next_scene() -> void:
	if main_menu_scene_path == "":
		printerr("BootUpLoading: No Main Menu scene selected!")
		return

	# CRASH-PROOF: Use a CanvasLayer to guarantee the fade covers everything without Z-fighting
	var canvas_layer = CanvasLayer.new()
	canvas_layer.layer = 128
	add_child(canvas_layer)

	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0) # Transparent black
	fade_rect.set_anchors_preset(PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP # Block random clicks during the fade
	canvas_layer.add_child(fade_rect)

	# Safely kill any previous tweens and start the fade
	if active_tween: active_tween.kill()
	active_tween = create_tween()
	active_tween.tween_property(fade_rect, "color:a", 1.0, 1.0)

	# Safe await: Moves execution outside the Tween's internal loop
	await active_tween.finished

	# Final safety net to ensure the frame is 100% finished
	if is_inside_tree():
		get_tree().call_deferred("change_scene_to_file", main_menu_scene_path)
