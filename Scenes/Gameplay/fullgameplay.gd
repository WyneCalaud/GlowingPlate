extends Node2D

# --- Node References ---
@onready var drop_zones_parent: Node2D = $ServeOrTrash
# Assuming the Plate node is a direct child of the GamePlayFull root node
@onready var food_plate: Node2D = $Plate/FoodPlate 

# --- CONSTANTS ---
const PLATE_SLOT_GROUP_NAME = "plate_slot"
const PLATE_SLOT_SCRIPT_NAME = "plate_slot.gd"
const PLATE_DRAGGABLE_SCRIPT_NAME = "food_plate_draggable.gd"

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")

# --- INITIALIZATION ---
func _ready():
	# 1. Ensure the drop zones are hidden initially
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = false
	else:
		print("FATAL ERROR [GamePlayFull]: Drop zones parent ('ServeOrTrash') is not a valid node or the path is wrong.")
		
	# Defer connection to ensure the Plate's _ready runs first
	await get_tree().process_frame
	
	# 2. Connect the PLATE's drag signal for visibility handling
	if is_instance_valid(food_plate):
		var plate_script = food_plate.get_script()
		
		if plate_script is GDScript and plate_script.resource_path.ends_with(PLATE_DRAGGABLE_SCRIPT_NAME):
			
			if not food_plate.is_connected("drag_state_changed", Callable(self, "_on_plate_drag_state_changed")):
				food_plate.connect("drag_state_changed", Callable(self, "_on_plate_drag_state_changed"))
				print("DEBUG [GamePlayFull]: Plate drag signal connected successfully.")
			else:
				print("WARNING [GamePlayFull]: Plate drag signal was already connected.")
		else:
			print("FATAL ERROR [GamePlayFull]: FoodPlate node does not have the correct draggable script attached.")
	else:
		print("FATAL ERROR [GamePlayFull]: FoodPlate node not found at path '$Plate/FoodPlate'. Check node path.")

# --- HANDLER: Toggles visibility of Serve/Trash Zones based on drag state ---
func _on_plate_drag_state_changed(is_dragging_now: bool):
	
	if not is_instance_valid(drop_zones_parent):
		return
		
	# Ensure the plate is valid and has the content-checking method
	if not is_instance_valid(food_plate) or not food_plate.has_method("get_plate_contents"):
		print("ERROR [GamePlayFull]: FoodPlate is invalid or missing required method.")
		return

	if is_dragging_now:
		# Check if the plate actually has food
		var plate_contents = food_plate.get_plate_contents()
		
		if plate_contents.size() > 0:
			drop_zones_parent.visible = true
			print("ACTION [GamePlayFull]: Serve/Trash zones SHOWN.")
		else:
			# If a drag event fires on an empty plate (should be rare due to plate script logic), keep hidden
			drop_zones_parent.visible = false
			print("WARNING [GamePlayFull]: Drag started but plate is empty. Zones kept hidden.")
	else:
		# Dragging stopped, hide the zones
		drop_zones_parent.visible = false
		print("ACTION [GamePlayFull]: Serve/Trash zones HIDDEN.")


# NOTE: Removed the outdated _on_plate_slot_updated handler as it is no longer needed
# for drag visibility, which is now handled directly by the plate's signal.
