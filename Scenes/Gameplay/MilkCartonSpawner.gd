extends TextureButton

@export var milk_scene: PackedScene 
@export var mat1: Node2D 
@export var mat2: Node2D 
@export var spawn_anim_speed: float = 0.5
@export var milk_scale: Vector2 = Vector2(1.0, 1.0) 
@export var placement_offset: Vector2 = Vector2(0, -250) 

var beverage_station_root: Node = null
var is_spawning: bool = false
var has_spawned_milk: bool = false # DEFENSIVE: Prevents multiple milk spawns

func _ready():
	pressed.connect(_on_pressed)
	
	var current_node = get_parent()
	while is_instance_valid(current_node) and current_node.get_parent() != null:
		current_node = current_node.get_parent()
	beverage_station_root = current_node
	
	if not is_instance_valid(mat1) and is_instance_valid(beverage_station_root):
		mat1 = beverage_station_root.find_child("Mat1", true, false) as Node2D
		
	if not is_instance_valid(mat2) and is_instance_valid(beverage_station_root):
		mat2 = beverage_station_root.find_child("Mat2", true, false) as Node2D

func is_mat_available(mat: Node2D) -> bool:
	if not is_instance_valid(mat): return false
	if mat.get_meta("reserved", false): return false
	
	for child in mat.get_children():
		if is_instance_valid(child) and not child.is_queued_for_deletion():
			if child is CanvasItem and not child.visible:
				continue
			return false 
	return true

func _on_pressed():
	# DEFENSIVE CHECK: Lock out spawner if already spawned or spawning
	if is_spawning or has_spawned_milk: 
		print("DEBUG [MilkCarton]: Spawning locked.")
		return
		
	if not is_instance_valid(milk_scene): return

	var target_mat: Node2D = null
	if is_mat_available(mat1): target_mat = mat1
	elif is_mat_available(mat2): target_mat = mat2
	else: return

	is_spawning = true
	has_spawned_milk = true # Lock the spawner
	target_mat.set_meta("reserved", true)
	
	# --- TUTORIAL TRIGGER ---
	if is_inside_tree():
		var in_tutorial = get_tree().get_node_count_in_group("InteractiveTutorial") > 0
		if in_tutorial:
			get_tree().call_group("InteractiveTutorial", "action_completed", "MilkCartons_Pressed")
	
	var milk_instance = milk_scene.instantiate()
	if not is_instance_valid(milk_instance):
		is_spawning = false
		has_spawned_milk = false
		target_mat.set_meta("reserved", false)
		return
	
	if is_instance_valid(beverage_station_root): 
		beverage_station_root.add_child(milk_instance)
	else: 
		add_child(milk_instance)
		
	if milk_instance is Control:
		milk_instance.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
		milk_instance.pivot_offset = Vector2.ZERO
		
	milk_instance.scale = milk_scale
	
	var center_offset = Vector2.ZERO
	if milk_instance is Control:
		center_offset = (milk_instance.size * milk_scale) / 2.0
		
	var spawner_center = self.get_global_rect().get_center()
	var global_placement_offset = placement_offset * target_mat.global_scale
	var final_target_center = target_mat.global_position + global_placement_offset
	
	milk_instance.global_position = spawner_center - center_offset

	var tween = create_tween()
	if tween:
		tween.tween_property(milk_instance, "global_position", final_target_center - center_offset, spawn_anim_speed)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tween.finished
	
	if not is_instance_valid(milk_instance) or not is_instance_valid(target_mat):
		is_spawning = false
		has_spawned_milk = false
		if is_instance_valid(target_mat): target_mat.set_meta("reserved", false)
		return
	
	var current_parent = milk_instance.get_parent()
	if is_instance_valid(current_parent): current_parent.remove_child(milk_instance)
	
	target_mat.add_child(milk_instance)
	
	var final_local_scale = milk_scale / target_mat.global_scale
	milk_instance.scale = final_local_scale
	milk_instance.position = -final_local_scale / 2.0 + placement_offset
	
	if "start_position" in milk_instance:
		milk_instance.start_position = milk_instance.global_position
		
	target_mat.set_meta("reserved", false)
	is_spawning = false

# DEFENSIVE SAFETY NET: Reset functionality
func reset_spawner():
	has_spawned_milk = false
