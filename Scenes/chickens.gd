extends Sprite2D

# --- Variables ---
var is_dragging = false
var start_position: Vector2
var current_hovered_area: Area2D = null

# --- Exports ---
@export var food_type: String = "Grow" # CHANGED: Set to "Grow"
@export var plated_texture: Texture2D 
@export var cooked_texture: Texture2D # RENAMED: Used for the final cooked chicken image
@export var raw_texture: Texture2D # RENAMED: Used for the initial raw chicken image
@export var cooked_scale_factor: float = 0.4 # RENAMED: Adjust as needed for the cooked image size

func _ready() -> void:
	start_position = global_position
	z_index = 20

func _process(delta: float) -> void:
	if is_dragging:
		global_position = get_global_mouse_position()

func handle_drop():
	if current_hovered_area == null:
		return_to_start()
		return

	# --- PLATE LOGIC (Same logic) ---
	if current_hovered_area.has_method("try_place_food"):
		
		var texture_to_send = plated_texture
		if texture_to_send == null:
			texture_to_send = texture
			
		var success = current_hovered_area.try_place_food(food_type, texture_to_send)
		
		if success:
			print("Placed on plate!")
			
			# Revert to 'Raw' texture (if you want the chicken to be reusable/raw again)
			texture = raw_texture
			scale = Vector2(0.5, 0.5) # Use your standard base scale
			return_to_start()
			
		else:
			return_to_start()
			
	# --- COOKER LOGIC ---
	# Assuming chicken is cooked on the RiceCooker/Stove
	elif current_hovered_area.get_parent().name == "RiceCooker": 
		texture = cooked_texture # Swap to the cooked image
		scale = Vector2(cooked_scale_factor, cooked_scale_factor)
		plated_texture = plated_texture # Keep your resource-loading fix
		# This is the "cooked" version of the item, so it's ready for the plate now.
		return_to_start()
		
	else:
		return_to_start()
		
func return_to_start():
	var tween = create_tween()
	tween.tween_property(self, "global_position", start_position, 0.3).set_ease(Tween.EASE_OUT)
