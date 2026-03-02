extends Node

var is_transitioning := false

func fade_to(scene_path: String, fade_time: float = 1.5):

	if is_transitioning:
		return

	is_transitioning = true

	var tree = get_tree()
	if not tree:
		return

	var root = tree.root

	# Create top CanvasLayer
	var fade_canvas = CanvasLayer.new()
	fade_canvas.layer = 999
	root.add_child(fade_canvas)

	var fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 0)
	fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	fade_canvas.add_child(fade_rect)

	var tween = fade_rect.create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, fade_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.tween_callback(func():
		tree.change_scene_to_file(scene_path)
	)

	# Wait one frame so new scene loads
	tween.tween_interval(0.05)

	# Fade back in
	tween.tween_property(fade_rect, "color:a", 0.0, fade_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN_OUT)

	tween.finished.connect(func():
		if is_instance_valid(fade_canvas):
			fade_canvas.queue_free()
		is_transitioning = false
)
