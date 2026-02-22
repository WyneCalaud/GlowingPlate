extends TextureButton

@export var milk_scene: PackedScene # Assign your draggable Milk scene here
@export var mat1: Node2D # Assign Mat1 here
@export var mat2: Node2D # Assign Mat2 here
@export var spawn_anim_speed: float = 0.5
@export var milk_scale: Vector2 = Vector2(1.0, 1.0) # Matches the glass size multiplier approach
@export var placement_offset: Vector2 = Vector2(0, -250) # Adjust Y negatively to move it UP

var beverage_station_root: Node = null
var is_spawning: bool = false

func _ready():
	pressed.connect(_on_pressed)
	
	# Find the root node to safely animate global positions
	var current_node = get_parent()
	while current_node and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node

func is_mat_available(mat: Node2D) -> bool:
	# Checks if it has no children AND isn't currently reserved by another mid-air item
	return mat != null and mat.get_child_count() == 0 and not mat.get_meta("reserved", false)

func _on_pressed():
	if is_spawning: return
	if not milk_scene:
		print("Error: Milk scene not assigned in Inspector.")
		return

	# Check for an empty and unreserved mat
	var target_mat: Node2D = null
	if is_mat_available(mat1):
		target_mat = mat1
	elif is_mat_available(mat2):
		target_mat = mat2
	else:
		print("Both mats are currently occupied or reserved!")
		return

	is_spawning = true
	
	# INSTANTLY reserve the mat so rapid clicks don't steal it while animating
	target_mat.set_meta("reserved", true)
	
	# Spawn the milk
	var milk_instance = milk_scene.instantiate()
	
	# Add to root first for a smooth global coordinate animation
	if beverage_station_root: 
		beverage_station_root.add_child(milk_instance)
	else: 
		add_child(milk_instance)
		
	# Strip anchors and reset pivot to guarantee predictable position math
	if milk_instance is Control:
		milk_instance.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
		milk_instance.pivot_offset = Vector2.ZERO
		
	# 1. Apply exact scaling globally
	milk_instance.scale = milk_scale
	
	# 2. Calculate offsets to achieve "dead center" alignment
	var center_offset = Vector2.ZERO
	if milk_instance is Control:
		center_offset = (milk_instance.size * milk_scale) / 2.0
		
	var spawner_center = self.get_global_rect().get_center()
	
	# 3. Add custom offset to target center
	var global_placement_offset = placement_offset * target_mat.global_scale
	var final_target_center = target_mat.global_position + global_placement_offset
	
	# 4. Set start position so the milk appears exactly over the Spawner button
	milk_instance.global_position = spawner_center - center_offset

	# 5. Animate smoothly to the offset target mat position
	var tween = create_tween()
	tween.tween_property(milk_instance, "global_position", final_target_center - center_offset, spawn_anim_speed)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	await tween.finished
	
	# 6. Securely reparent the milk to the target mat
	var current_parent = milk_instance.get_parent()
	if current_parent: current_parent.remove_child(milk_instance)
	
	target_mat.add_child(milk_instance)
	
	# 7. Lock in final local scale to counteract the Mat's global scale (prevents shrinking/growing)
	var final_local_scale = milk_scale / target_mat.global_scale
	milk_instance.scale = final_local_scale
	
	# 8. Perfectly center the TextureRect relative to the Mat's origin (0, 0) plus your custom offset
	milk_instance.position = -final_local_scale / 2.0 + placement_offset
	
	# Update its home position so food_item_base.gd knows exactly where to return it if dropped illegally
	if "start_position" in milk_instance:
		milk_instance.start_position = milk_instance.global_position
		
	# Clear the reservation now that the item is physically inside the mat 
	# (get_child_count() will now properly return > 0)
	target_mat.set_meta("reserved", false)
	is_spawning = false
