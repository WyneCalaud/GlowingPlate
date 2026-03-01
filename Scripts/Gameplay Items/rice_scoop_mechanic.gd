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
	
	# Placement logic - Find the targeted cooker
	var cooker_node = get_tree().get_first_node_in_group(cooker_name)
	if not cooker_node:
		cooker_node = get_tree().root.find_child(cooker_name, true, false)
	
	# Add to root to prevent inheriting scale issues
	get_tree().root.add_child(ui_instance)
	ui_instance.z_index = 100
	
	# Defer position calculation to ensure UI elements have their size calculated
	call_deferred("_center_ui_on_cooker", cooker_node)

	# Connect to the UI's signals (from hold_button.gd)
	if ui_instance.has_signal("fill_finished"):
		ui_instance.fill_finished.connect(_on_ui_fill_finished)
		ui_instance.popup_closed.connect(_on_popup_closed) # ⚠️ FIX: Listen for cancellation!
	else:
		# Search children if the script is not on the root of the UI scene
		for child in ui_instance.get_children():
			if child.has_signal("fill_finished"):
				child.fill_finished.connect(_on_ui_fill_finished)
			if child.has_signal("popup_closed"):
				child.popup_closed.connect(_on_popup_closed) # ⚠️ FIX: Listen for cancellation!

func _center_ui_on_cooker(cooker_node: Node):
	if not is_instance_valid(ui_instance): return
	
	if cooker_node:
		var center_pos = cooker_node.global_position
		
		# Robust centering for Sprite2D
		if cooker_node is Sprite2D:
			if cooker_node.centered:
				center_pos += (cooker_node.offset * cooker_node.global_scale)
			else:
				var tex_size = cooker_node.texture.get_size() * cooker_node.global_scale if cooker_node.texture else Vector2.ZERO
				center_pos += (cooker_node.offset * cooker_node.global_scale) + (tex_size / 2)
		elif cooker_node is Control:
			center_pos = cooker_node.get_global_rect().get_center()
			
		var ui_size = ui_instance.size
		if ui_size == Vector2.ZERO: 
			ui_size = Vector2(100, 100) # Fallback if size calculation failed
			
		# Center it and bump it up slightly so it floats cleanly over the cooker
		ui_instance.global_position = center_pos - (ui_size / 2) + Vector2(0, -60)
	else:
		# Fallback position if cooker isn't found
		ui_instance.global_position = Vector2(20, 280)

# ⚠️ NEW FIX: Called when the player clicks outside to close
func _on_popup_closed():
	# Sending "Empty" triggers a cancellation in rice_cup.gd
	finish_scoop("Empty")

func _on_ui_fill_finished(amount_str: String, _amount_int: int):
	# FIX: Actually delay the finish call using call_deferred to ensure 
	# the UI signal finishes processing without interrupting the execution!
	call_deferred("finish_scoop", amount_str)

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
	
	# Cleanup UI safely (avoiding double-free errors)
	if is_instance_valid(ui_instance) and not ui_instance.is_queued_for_deletion():
		ui_instance.queue_free()
	ui_instance = null
		
	# Use deferred queue_free to prevent the "Signal/Memory Crash"
	call_deferred("queue_free")
