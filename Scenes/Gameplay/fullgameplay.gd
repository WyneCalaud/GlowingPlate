extends Node2D

# --- REFERENCES TO YOUR FOOD DISPENSERS ---
# CRITICAL: You must ensure these paths match your Scene Tree!
# If your nodes are named "ChickenContainer", please rename them to these generic names
# or update the paths below.
@onready var grow_dispenser = $FoodStations/Grow_Station/DraggableItem
@onready var veg_dispenser = $FoodStations/Veg_Station/DraggableItem
@onready var fru_dispenser = $FoodStations/Fruit_Station/DraggableItem

# --- Node References for Drag Logic ---
@onready var drop_zones_parent: Node2D = $ServeOrTrash
@onready var food_plate: Node2D = $Plate/FoodPlate 

# --- CONSTANTS ---
const PLATE_SLOT_GROUP_NAME = "plate_slot"
const PLATE_SLOT_SCRIPT_NAME = "plate_slot.gd"
const PLATE_DRAGGABLE_SCRIPT_NAME = "food_plate_draggable.gd"

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")

# --- INITIALIZATION ---
func _ready():
	# 1. Setup the Menu for the Day (Load Fish, Sitaw, etc. if Day 2)
	setup_kitchen_for_today()

	# 2. Ensure the drop zones are hidden initially
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = false
	else:
		print("FATAL ERROR [GamePlayFull]: Drop zones parent ('ServeOrTrash') is not a valid node.")
		
	# Defer connection to ensure the Plate's _ready runs first
	await get_tree().process_frame
	
	# 3. Connect the PLATE's drag signal for visibility handling
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

# --- DYNAMIC MENU LOGIC ---
func setup_kitchen_for_today():
	var day = GameData.current_day
	print("Kitchen: Setting up menu for Day %d" % day)
	
	# 1. Get the Menu Schedule
	var menu_key = day
	if not OrderSystem.MENU_SCHEDULE.has(menu_key):
		menu_key = 1 # Default back to Day 1
	
	var menu = OrderSystem.MENU_SCHEDULE[menu_key]
	
	# 2. Update GROW Station (e.g., Chicken vs Fish)
	# This station uses 'chickens.gd' logic (Spawns items)
	if grow_dispenser:
		var grow_key = menu["Grow"]
		var grow_res = OrderSystem.FOOD_DB[grow_key]
		update_dispenser(grow_dispenser, grow_res)
	
	# 3. Update VEG Station
	# This station uses 'mixed_veggies.gd' logic (Toggle Selection)
	if veg_dispenser:
		var veg_key = menu["GlowVeg"]
		var veg_res = OrderSystem.FOOD_DB[veg_key]
		update_dispenser(veg_dispenser, veg_res)
	
	# 4. Update FRUIT Station
	# This station uses 'watermelons.gd' logic (Toggle Selection)
	if fru_dispenser:
		var fru_key = menu["GlowFru"]
		var fru_res = OrderSystem.FOOD_DB[fru_key]
		update_dispenser(fru_dispenser, fru_res)

# Helper to swap the data and texture dynamically based on script type
func update_dispenser(dispenser_node, food_res: Resource):
	if not is_instance_valid(dispenser_node):
		return

	# 1. Update the Data (Critical for logic)
	# Your scripts (chickens.gd, mixed_veggies.gd) inherit 'food_item_base.gd', 
	# so they likely share the 'food_data' variable.
	if "food_data" in dispenser_node:
		dispenser_node.food_data = food_res
	elif "item_resource" in dispenser_node:
		dispenser_node.item_resource = food_res
	
	# 2. Update the Visuals
	# Handle "Toggle Selection" scripts (mixed_veggies.gd)
	if "default_texture" in dispenser_node:
		dispenser_node.default_texture = food_res.icon_texture
		# Apply immediate visual update
		if "texture" in dispenser_node:
			dispenser_node.texture = food_res.icon_texture
			
	# Handle "Spawn" scripts or generic sprites (chickens.gd)
	elif "texture" in dispenser_node:
		# Directly update the main texture
		dispenser_node.texture = food_res.icon_texture
		
	# Fallback for nodes using a child Sprite
	elif dispenser_node.has_node("Sprite"):
		var sprite = dispenser_node.get_node("Sprite")
		if sprite is Sprite2D:
			sprite.texture = food_res.icon_texture

# --- HANDLER: Toggles visibility of Serve/Trash Zones based on drag state ---
func _on_plate_drag_state_changed(is_dragging_now: bool):
	
	if not is_instance_valid(drop_zones_parent):
		return
		
	if not is_instance_valid(food_plate) or not food_plate.has_method("get_plate_contents"):
		print("ERROR [GamePlayFull]: FoodPlate is invalid or missing required method.")
		return

	if is_dragging_now:
		# Check if the plate actually has food
		var plate_contents = food_plate.get_plate_contents()
		
		if plate_contents.size() > 0:
			drop_zones_parent.visible = true
		else:
			drop_zones_parent.visible = false
	else:
		drop_zones_parent.visible = false
