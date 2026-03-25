extends Camera2D

@export var smoothing: float = 15.0
@export var drag_speed: float = 1.0
@export var min_x: float = 640.0
@export var max_x: float = 1672.0 

var target_x: float = 640.0
var is_dragging: bool = false
var last_mouse_pos: Vector2

# A flag to ensure we only trigger the tutorial step once
var has_completed_scroll_tutorial: bool = false

# DEFENSIVE FIX: Variable expected by draggable items to block camera movement
var is_input_blocked: bool = false

# Renamed to "is_tutorial_locked" so Interactive.gd automatically controls it!
var is_tutorial_locked: bool = true:
	set(value):
		is_tutorial_locked = value
		if is_tutorial_locked:
			is_dragging = false
		else:
			# Reset tracking when unlocked to prevent the camera from "jerking"
			last_mouse_pos = get_viewport().get_mouse_position()

func _ready():
	target_x = min_x
	position.x = min_x
	add_to_group("MainCamera")

# Changed to _input to capture events even if UI is clicked (like dispensers)
func _input(event):
	# DEFENSIVE FIX: Block input if tutorial locked OR an item is being dragged
	if is_tutorial_locked or is_input_blocked:
		is_dragging = false
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_pos = event.position

	if event is InputEventMouseMotion and is_dragging:
		var delta_x = event.position.x - last_mouse_pos.x
		target_x = clamp(target_x - (delta_x * drag_speed), min_x, max_x)
		last_mouse_pos = event.position

func _process(delta):
	position.x = lerp(position.x, target_x, smoothing * delta)
	
	# --- TUTORIAL COMPLETION CHECK ---
	# If we are unlocked and haven't completed the step yet, check if we reached the water station
	if not is_tutorial_locked and not has_completed_scroll_tutorial:
		# If the target is sufficiently close to the max_x (Water Station)
		if target_x >= max_x - 20.0: 
			has_completed_scroll_tutorial = true
			# Tell the Tutorial script that the step is done!
			if get_tree().has_group("InteractiveTutorial"):
				get_tree().call_group("InteractiveTutorial", "action_completed", "Move_Camera_To_Water_Station")

func force_go_to_beverage():
	target_x = max_x

func force_go_to_kitchen():
	target_x = min_x
