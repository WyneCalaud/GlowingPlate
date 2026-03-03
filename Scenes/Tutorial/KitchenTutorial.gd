extends Control

signal tutorial_finished

# --- UI ELEMENTS ---
# Using get_node_or_null prevents a hard crash if a node is missing or renamed
@onready var tutorial_overlay: TextureButton = get_node_or_null("TutorialOverlay")
@onready var layout_1: Node = get_node_or_null("Layout1")
@onready var layout_2: Node = get_node_or_null("Layout2")

# --- TUTORIAL STORYBOARD SLOTS ---
@export var tutorial_frames: Array[Texture2D] = []

# --- STATE ---
var current_step_index: int = 0
var is_transitioning: bool = false
var _active_tween: Tween = null # Tracks the current tween to prevent overlaps

func _ready() -> void:
	# Failsafe: Abort if the main overlay button is missing
	if not is_instance_valid(tutorial_overlay):
		push_error("TutorialOverlay node is missing! Cannot start tutorial.")
		return
		
	# Connect the built-in button pressed signal safely
	if not tutorial_overlay.pressed.is_connected(_on_overlay_pressed):
		tutorial_overlay.pressed.connect(_on_overlay_pressed)
		
	tutorial_overlay.visible = true
	tutorial_overlay.modulate.a = 0.0 # Start invisible for initial fade-in
		
	# Ensure starting layouts are in the correct state
	if is_instance_valid(layout_1): layout_1.visible = true
	if is_instance_valid(layout_2): layout_2.visible = false
	
	# Start the storyboard if we have frames
	if tutorial_frames.size() > 0:
		call_deferred("_load_step", 0)
	else:
		push_warning("Tutorial frames array is empty! Please add textures in the Inspector.")
		# Deferring signal emission in _ready is safer to ensure all other nodes are ready to listen
		call_deferred("emit_signal", "tutorial_finished")

# ==========================================================
# STEP LOGIC & TRANSITIONS
# ==========================================================

func _load_step(index: int) -> void:
	# Failsafe: if the node is destroyed mid-game, safely abort
	if not is_instance_valid(self) or not is_instance_valid(tutorial_overlay):
		return

	# Prevent tween overlap bugs by killing any currently active tween
	if _active_tween and _active_tween.is_valid():
		_active_tween.kill()

	# If we reached the end of the slots, finish the tutorial
	if index >= tutorial_frames.size() or index < 0:
		_finish_tutorial()
		return
		
	current_step_index = index
	is_transitioning = true
	
	# Grab the texture for this step (with a failsafe for empty slots)
	var next_texture: Texture2D = tutorial_frames[index]
	if not next_texture:
		push_warning("Tutorial frame at index " + str(index) + " is empty/null!")
	
	# Create a new tween. bind_node(self) ensures the tween safely deletes itself if this scene is closed.
	_active_tween = create_tween().bind_node(self).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	
	# If it's not the very first frame, fade out the current image smoothly
	if index > 0:
		_active_tween.tween_property(tutorial_overlay, "modulate:a", 0.0, 0.15)
		
	# Swap the texture and handle layout visibility while the overlay is faded out
	_active_tween.tween_callback(func(): 
		# Double check validity inside the delayed lambda just in case the scene closed mid-fade
		if not is_instance_valid(self) or not is_instance_valid(tutorial_overlay):
			return
			
		tutorial_overlay.texture_normal = next_texture
		
		# --- LAYOUT SWAP LOGIC ---
		if index == 48:
			if is_instance_valid(layout_1): layout_1.visible = false
			if is_instance_valid(layout_2): layout_2.visible = true
	)
	
	# Fade back in with the new texture
	_active_tween.tween_property(tutorial_overlay, "modulate:a", 1.0, 0.15)
	
	# Allow clicking again once the fade is entirely finished
	_active_tween.tween_callback(func(): 
		if is_instance_valid(self):
			is_transitioning = false
	)

func _finish_tutorial() -> void:
	if not is_instance_valid(tutorial_overlay):
		tutorial_finished.emit()
		return
		
	_active_tween = create_tween().bind_node(self).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_SINE)
	_active_tween.tween_property(tutorial_overlay, "modulate:a", 0.0, 1.5)
	
	# CHANGED: Handles both "Standalone Scene" and "Popup inside KitchenArea" seamlessly
	_active_tween.tween_callback(func(): 
		if is_instance_valid(self) and is_instance_valid(tutorial_overlay):
			tutorial_overlay.visible = false
			tutorial_finished.emit()
			
			# Check if this scene is running as the MAIN screen right now
			if get_tree().current_scene == self:
				# We are in Intro -> Tutorial -> Lobby flow, so load the Lobby!
				get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
			else:
				# We are a popup inside the KitchenArea. Safely delete ourselves.
				queue_free()
	)

func advance_step() -> void:
	_load_step(current_step_index + 1)

# ==========================================================
# INTERACTIONS
# ==========================================================

func _on_overlay_pressed() -> void:
	# Ignore clicks if we are currently fading to the next slide or if invalid
	if is_transitioning or not is_instance_valid(self): 
		return
	
	# Move to the next storyboard frame
	advance_step()
