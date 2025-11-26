# customer.gd
extends Sprite2D

var target_x: float = 370  # where they should stop when entering
var exit_x: float = -370 # where they go when exiting
var speed: float = 200
var is_leaving: bool = false

func _process(delta):
	if not is_leaving:
		# Move IN
		global_position.x = move_toward(global_position.x, target_x, speed * delta)
	else:
		# Move OUT
		global_position.x = move_toward(global_position.x, exit_x, speed * delta)
		if abs(global_position.x - exit_x) < 1:
			queue_free()
