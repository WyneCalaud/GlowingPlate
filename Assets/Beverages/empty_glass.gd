extends Node2D 

# This script will be attached to the root node of EmptyGlass.tscn (the 'Glass' node).

# --- PROPERTIES ---
var is_filled: bool = false
var beverage_type: String = ""

# --- DRAGGING LOGIC (Optional, but often needed for item interaction) ---
# For now, we'll keep it simple to handle filling.

func fill_with_beverage(type: String):
	if is_filled:
		print("ERROR: Glass is already filled.")
		return
		
	beverage_type = type
	is_filled = true
	# TODO: Update the Sprite2D's texture or modulate color to show liquid.
	print("Glass filled with: ", beverage_type)
