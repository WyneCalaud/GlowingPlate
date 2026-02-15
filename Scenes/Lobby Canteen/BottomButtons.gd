extends Control

@export var hide_show_btn: BaseButton
@export var buttons_to_toggle: Array[BaseButton]

var original_positions: Array[Vector2] = []
var is_expanded: bool = true
var active_tween: Tween
@export var anim_speed: float = 0.3

func _ready():
	if not hide_show_btn:
		push_error("Please assign the HideShowButton in the Inspector!")
		return
		
	# Ensure the Hide/Show button renders on top of the collapsing buttons
	hide_show_btn.z_index = 10 
	
	# Wait one frame for the UI layout to fully calculate coordinates
	await get_tree().process_frame
	
	# Save the local positions after layout is complete
	for btn in buttons_to_toggle:
		if btn:
			original_positions.append(btn.position)
			btn.visible = true 
		
	hide_show_btn.pressed.connect(_on_hide_show_pressed)

func _on_hide_show_pressed():
	if original_positions.is_empty(): return # Prevent errors if clicked too fast
	
	is_expanded = !is_expanded
	
	# Kill existing tween to prevent glitches from rapid clicking
	if active_tween and active_tween.is_valid():
		active_tween.kill()
	
	# TRANS_BACK gives it a nice slight "bounce" effect when opening/closing
	active_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var target_collapse_pos = hide_show_btn.position
	
	for i in range(buttons_to_toggle.size()):
		var btn = buttons_to_toggle[i]
		if not btn: continue
		
		if is_expanded:
			# EXPAND (Show)
			btn.visible = true 
			active_tween.tween_property(btn, "position", original_positions[i], anim_speed)
			active_tween.tween_property(btn, "modulate:a", 1.0, anim_speed)
			btn.mouse_filter = Control.MOUSE_FILTER_STOP # Enable clicking
		else:
			# COLLAPSE (Hide)
			active_tween.tween_property(btn, "position", target_collapse_pos, anim_speed)
			active_tween.tween_property(btn, "modulate:a", 0.0, anim_speed)
			btn.mouse_filter = Control.MOUSE_FILTER_IGNORE # Disable clicking while hidden
			
	# Optional: Spin the Hide/Show button 180 degrees
	hide_show_btn.pivot_offset = hide_show_btn.size / 2
	var target_rotation = 0.0 if is_expanded else deg_to_rad(180)
	active_tween.tween_property(hide_show_btn, "rotation", target_rotation, anim_speed)
