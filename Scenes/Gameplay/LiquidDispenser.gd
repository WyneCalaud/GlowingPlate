extends Area2D 

# --- CONFIGURATION ---
@export var liquid_type: String = "water_1" # e.g., "cold_water" or "hot_water"
@export var unselected_texture: Texture2D
@export var selected_texture: Texture2D 

@export_group("Animations")
@export var hover_scale: float = 1.1
@export var anim_speed: float = 0.1

# --- NODE REFERENCES ---
@onready var sprite: Sprite2D = $".." 
var global_controller: Node = null

# Selection State
var is_selected: bool = false
var original_scale: Vector2

# Tap detection
var drag_threshold: float = 10.0
var press_pos: Vector2
var is_pressing: bool = false

func _ready():
	if sprite:
		if is_instance_valid(unselected_texture):
			sprite.texture = unselected_texture
		original_scale = sprite.scale
		
	var controllers = get_tree().get_nodes_in_group("global_controller")
	if controllers.size() > 0:
		global_controller = controllers[0]
	
	set_pickable(true)
	add_to_group("liquid_dispenser")

func _input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_pressing = true
			press_pos = event.position
		else:
			if is_pressing:
				var dist = press_pos.distance_to(event.position)
				if dist < drag_threshold:
					toggle_selection()
					get_viewport().set_input_as_handled()
				is_pressing = false

func toggle_selection():
	if is_selected:
		deselect()
	else:
		select()

func select():
	if is_selected: return # Break recursion
	
	# Deselect others WITHOUT triggering their global_controller logic again
	for member in get_tree().get_nodes_in_group("liquid_dispenser"):
		if member != self and member.is_selected:
			member.deselect()
	
	is_selected = true
	
	if global_controller:
		global_controller.set_liquid_selection(self, liquid_type)

	# Selection Colors
	var highlight_color = Color(1.2, 1.2, 1.8) # Bluish
	if liquid_type.to_lower().contains("hot"):
		highlight_color = Color(1.8, 1.1, 1.1) # Reddish
	
	if sprite:
		if is_instance_valid(selected_texture):
			sprite.texture = selected_texture
		
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", original_scale * hover_scale, anim_speed)
		tween.tween_property(sprite, "modulate", highlight_color, anim_speed)

func deselect():
	if not is_selected: return # Break recursion
	
	is_selected = false
	
	# Only notify controller if we are toggling ourselves off specifically
	# This prevents the "deselect all" call from loop-triggering the controller
	if global_controller and global_controller.selected_liquid == liquid_type:
		global_controller.reset_liquid_selection_visuals()
	
	if sprite:
		if is_instance_valid(unselected_texture):
			sprite.texture = unselected_texture
			
		var tween = create_tween().set_parallel(true)
		tween.tween_property(sprite, "scale", original_scale, anim_speed)
		tween.tween_property(sprite, "modulate", Color.WHITE, anim_speed)

# Used by external scripts
func set_visual_state(should_be_selected: bool):
	if should_be_selected and not is_selected:
		select()
	elif not should_be_selected and is_selected:
		deselect()
