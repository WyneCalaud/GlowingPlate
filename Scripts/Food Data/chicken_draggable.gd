extends "res://Scripts/Food Data/food_item_base_2.gd"

func on_plate_placement_success():
	# Success: Destroy this temporary node
	queue_free()
	
# Called when dropped in empty space or placement failed
func on_drop_fail():
	# Failure: Destroy this temporary node
	queue_free()
	
# Called when dropped somewhere else (not a plate slot)
func on_unique_drop_zone_check():
	# For a simple item like this, treat unique zones as failure (destroy)
	queue_free()
# This is optional — only if you want custom behavior
# like changing texture after placed, etc.
