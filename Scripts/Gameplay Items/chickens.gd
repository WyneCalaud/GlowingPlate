extends Sprite2D
@export var draggable_scene: PackedScene  # Assign ChickenDraggable.tscn

func _input(event):
	if event is InputEventMouseButton \
	and event.button_index == MOUSE_BUTTON_LEFT \
	and event.pressed:

		if get_rect().has_point(to_local(get_global_mouse_position())):
			_spawn_draggable()

func _spawn_draggable():
	var item = draggable_scene.instantiate()
	get_tree().current_scene.add_child(item)
	item.global_position = get_global_mouse_position()
	item.top_level = true
	item.z_index = 999
	
