extends Node2D

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")

# --- Node References ---
@onready var drop_zones_parent: Node2D = $ServeOrTrash

# --- INITIALIZATION ---
func _ready():
	# 1. Ensure the drop zones are hidden initially
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = false
	else:
		print("FATAL ERROR [GamePlayFull]: Drop zones parent ('ServeOrTrash') is not a valid node or the path is wrong.")
		
	# 2. Connect the plate slot's plate_updated signal to this handler using a group search
	var connected: bool = false
	
	# Defer the search until the end of the frame to ensure all children are loaded
	await get_tree().process_frame
	
	# CORRECTED: Use the actual script name, plate_slot.gd
	const PLATE_SLOT_SCRIPT_NAME = "plate_slot.gd"
	
	for node in get_tree().get_nodes_in_group("plate_slots"):
		# Check if the node is an Area2D and has the correct script attached
		if node is Area2D and node.get_script() is GDScript and node.get_script().resource_path.ends_with(PLATE_SLOT_SCRIPT_NAME):
			
			if not node.is_connected("plate_updated", Callable(self, "_on_plate_slot_updated")):
				# Signal name 'plate_updated' must be defined in plate_slot.gd
				node.plate_updated.connect(_on_plate_slot_updated)
				print("DEBUG [GamePlayFull]: Plate Slot signal connected successfully to node: ", node.name)
				connected = true
				break # Stop after finding and connecting the first valid slot
	
	if not connected:
		print("FATAL ERROR [GamePlayFull]: Could not find or connect to any plate slot. Ensure all plate slot Area2D nodes are in the 'plate_slots' group AND have ", PLATE_SLOT_SCRIPT_NAME, " attached.")


# --- SIGNAL HANDLER: Toggles visibility of Serve/Trash Zones ---
func _on_plate_slot_updated(_resource: Resource, filled: bool, dragging: bool):
	
	# We only care about visibility if the parent node is valid
	if is_instance_valid(drop_zones_parent):
		
		# Show drop zones only if the plate is filled AND actively being dragged
		if filled and dragging:
			drop_zones_parent.visible = true
			# No need to print this frequently, but keep it for confirmation
			# print("DEBUG [GamePlayFull]: Serve/Trash zones SHOWN.") 
		else:
			# Hide the zones when dragging stops or the plate is empty
			drop_zones_parent.visible = false
			# print("DEBUG [GamePlayFull]: Serve/Trash zones HIDDEN.")
	else:
		print("ERROR [GamePlayFull]: Cannot set visibility. Drop zones parent node is invalid.")
