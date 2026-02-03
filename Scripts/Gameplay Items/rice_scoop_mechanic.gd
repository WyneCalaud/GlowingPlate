# rice_scoop_mechanic.gd
extends Control

# --- CONFIGURATION ---
const RICE_SCOOP_UI_SCENE = preload("res://Scenes/Gameplay/RiceScoopUI.tscn") 

# --- STATE ---
var parent_cup: Node = null
var ui_instance: Control = null
var is_mechanic_active: bool = false

# --- SIGNALS ---
signal scoop_finished(amount: String)
signal score_change(deduction: int)

func start_scoop_hold(cup_node: Node, cooker_name: String, _empty_texture: Texture2D = null, _scale_factor: float = 0.0):
	parent_cup = cup_node
	is_mechanic_active = true
	
	# Lock cup movement during mechanic
	var cup_area = parent_cup.get_node_or_null("Area2D")
	if is_instance_valid(cup_area):
		cup_area.input_pickable = false
	
	ui_instance = RICE_SCOOP_UI_SCENE.instantiate()
	
	# Placement logic
	var cooker_node = get_tree().get_first_node_in_group(cooker_name)
	if cooker_node:
		cooker_node.add_child(ui_instance)
		ui_instance.position = Vector2(0, 50) 
		ui_instance.z_index = 100
	else:
		get_tree().root.add_child(ui_instance)
		ui_instance.global_position = Vector2(20, 280)
		ui_instance.z_index = 100

	# Connect to the UI's signal (from hold_button.gd)
	# This ensures we only have ONE source of truth for the result
	if ui_instance.has_signal("fill_finished"):
		ui_instance.fill_finished.connect(_on_ui_fill_finished)
	else:
		# Search children if the script is not on the root of the UI scene
		for child in ui_instance.get_children():
			if child.has_signal("fill_finished"):
				child.fill_finished.connect(_on_ui_fill_finished)
				break

func _on_ui_fill_finished(amount_str: String, _amount_int: int):
	# Delay the finish call slightly to ensure the UI signal finishes processing
	finish_scoop(amount_str)

func finish_scoop(amount: String):
	if not is_mechanic_active:
		return
		
	is_mechanic_active = false
	
	# Re-enable cup interaction
	if is_instance_valid(parent_cup):
		var cup_area = parent_cup.get_node_or_null("Area2D")
		if is_instance_valid(cup_area):
			cup_area.input_pickable = true
		
	# Emit to rice_cup.gd
	emit_signal("scoop_finished", amount)
	
	# Cleanup UI
	if is_instance_valid(ui_instance):
		ui_instance.queue_free()
		ui_instance = null
		
	# Use deferred queue_free to prevent the "Signal/Memory Crash"
	call_deferred("queue_free")
