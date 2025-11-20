extends Sprite2D

# --- Variables ---
var is_dragging = false
var start_position: Vector2 # This will now store the GLOBAL start position

# --- Textures ---
@export var empty_cup_texture: Texture2D
@export var full_cup_texture: Texture2D

func _ready() -> void:
	# Store the GLOBAL starting position when the game begins
	start_position = self.global_position

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

func _on_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch):
		if event.is_pressed():
			is_dragging = true
		elif event.is_released():
			is_dragging = false
			handle_drop()

func handle_drop():
	var overlapping_areas = $Area2D.get_overlapping_areas()
	var dropped_on_cooker = false
	
	for area in overlapping_areas:
		if area.get_parent().name == "RiceCooker":
			print("Dropped on the rice cooker!")
			self.texture = full_cup_texture
			dropped_on_cooker = true
			break
			
	return_to_start()

func return_to_start():
	var tween = create_tween()
	# Animate the GLOBAL position back to the saved GLOBAL start position
	tween.tween_property(self, "global_position", start_position, 0.3).set_ease(Tween.EASE_OUT)
