extends Camera2D

@export var smoothing: float = 15.0
@export var drag_speed: float = 1.0
@export var min_x: float = 640.0
@export var max_x: float = 1920.0

var target_x: float = 640.0
var is_dragging: bool = false
var last_mouse_pos: Vector2

# Using a setter to detect when the lock is released
var is_input_blocked: bool = false:
	set(value):
		is_input_blocked = value
		if is_input_blocked:
			is_dragging = false
		else:
			# CRITICAL: Reset tracking when unlocked to prevent the "jerk"
			last_mouse_pos = get_viewport().get_mouse_position()

func _ready():
	target_x = min_x
	position.x = min_x
	add_to_group("MainCamera")

func _unhandled_input(event):
	if is_input_blocked:
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

func force_go_to_beverage():
	target_x = max_x

func force_go_to_kitchen():
	target_x = min_x
