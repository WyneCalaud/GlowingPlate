extends Camera2D

@export var smoothing: float = 15.0
@export var drag_speed: float = 1.0
@export var min_x: float = 640.0
@export var max_x: float = 1920.0

var target_x: float = 640.0
var is_dragging: bool = false
var last_mouse_pos: Vector2

# Set this to true from your Chicken/Rice script's _input_event to block scrolling
var is_input_blocked: bool = false

func _ready():
	target_x = min_x
	position.x = min_x

func _unhandled_input(event):
	# If an ingredient script has flagged the input as blocked, ignore dragging logic
	if is_input_blocked:
		is_dragging = false
		return

	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			is_dragging = event.pressed
			last_mouse_pos = event.position

	if event is InputEventMouseMotion and is_dragging:
		var delta_x = event.position.x - last_mouse_pos.x
		# Standard free-scroll: move target by the mouse delta
		target_x = clamp(target_x - (delta_x * drag_speed), min_x, max_x)
		last_mouse_pos = event.position

func _process(delta):
	# Smooth movement to the target position without snapping logic
	position.x = lerp(position.x, target_x, smoothing * delta)

# Helper functions to still allow UI buttons to jump to locations
func force_go_to_beverage():
	target_x = max_x

func force_go_to_kitchen():
	target_x = min_x
