extends Node2D

# --- REFERENCES TO YOUR FOOD DISPENSER ARRAYS ---
# Instead of one variable per category, we use Arrays of nodes.
# Make sure you create these slots in your Scene and name them accordingly!

@onready var grow_stations = [
	$Row1/Slot1/DraggableItem,
	$Row1/Slot2/DraggableItem, # Make sure this node exists in scene!
	$Row1/Slot3/DraggableItem  # Make sure this node exists in scene!
]

@onready var veg_stations = [
	$Row2/Slot1/DraggableItem,
	$Row2/Slot2/DraggableItem,
	$Row2/Slot3/DraggableItem
]

@onready var fru_stations = [
	$Row3/Slot1/DraggableItem,
	$Row3/Slot2/DraggableItem,
	$Row3/Slot3/DraggableItem
]

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
	# 1. Setup the Menu for the Day
	#setup_kitchen_for_today()

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

# --- DYNAMIC MENU LOGIC (The Stage Manager) ---
#func setup_kitchen_for_today():
	#var day = GameData.current_day
	#print("Kitchen: Setting up menu for Day %d" % day)
	#
	#var menu_key = day
	## Safety Fallback: If day 8 comes but we only have 7 days, loop back or use Day 1
	#if not OrderSystem.MENU_SCHEDULE.has(menu_key):
		#print("Warning: No menu defined for Day %d. Defaulting to Day 1." % day)
		#menu_key = 1 
	#
	#var menu = OrderSystem.MENU_SCHEDULE[menu_key]
	
	# 2. Update Stations using the List Helper
	#update_station_list(grow_stations, menu, "Grow")
	#update_station_list(veg_stations, menu, "GlowVeg")
	#update_station_list(fru_stations, menu, "GlowFru")

# --- HELPER: Handles Lists of Stations ---
#func update_station_list(station_nodes: Array, menu_data: Dictionary, category_key: String):
	## 1. Get the list of foods for today (e.g. ["Chicken", "Fish"])
	#var food_keys = []
	#if menu_data.has(category_key):
		#var data = menu_data[category_key]
		#if data is Array:
			#food_keys = data
		#else:
			#food_keys = [data]
			#
	## 2. Loop through every physical slot in the scene
	#for i in range(station_nodes.size()):
		#var dispenser = station_nodes[i]
		#
		## Do we have a food item for this slot index?
		#if i < food_keys.size():
			## YES: Show it and set it up
			#var parent = dispenser.get_parent() # The Slot Node
			#if parent: parent.show()
			#
			#var item_key = food_keys[i]
			#
			## SAFETY CHECK: Does this item key exist in the database?
			#if not OrderSystem.FOOD_DB.has(item_key):
				#printerr("CRITICAL ERROR: Item '%s' is in the Menu Schedule but NOT in FOOD_DB!" % item_key)
				#continue 
				#
			#var food_res = OrderSystem.FOOD_DB[item_key]
			#update_dispenser_visuals(dispenser, food_res)
		#else:
			## NO: Hide the empty slot
			#var parent = dispenser.get_parent()
			#if parent: parent.hide()

# --- HELPER: Swaps Data and Textures ---
#func update_dispenser_visuals(dispenser_node, food_res: Resource):
	#if not is_instance_valid(dispenser_node):
		#return
#
	## 1. Update the Data (Critical for logic)
	#if "food_data" in dispenser_node:
		#dispenser_node.food_data = food_res
	#elif "item_resource" in dispenser_node:
		#dispenser_node.item_resource = food_res
	#
	## 2. Determine which texture to use
	#var new_texture = null
	#
	#if "base_texture" in food_res:
		#new_texture = food_res.base_texture
	#elif "default_plated_texture" in food_res:
		#new_texture = food_res.default_plated_texture
	#elif "texture" in food_res:
		#new_texture = food_res.texture
	#elif "icon_texture" in food_res:
		#new_texture = food_res.icon_texture
		#
	#if new_texture == null:
		#print("ERROR: Could not find a valid texture ('base_texture', 'icon_texture', etc.) in resource: ", food_res)
		#return
#
	## 3. Apply the Visuals
	#
	## Handle "Toggle Selection" scripts (mixed_veggies.gd / watermelons.gd)
	#if "default_texture" in dispenser_node:
		#dispenser_node.default_texture = new_texture
		## Apply immediate visual update if current texture is default
		#if "texture" in dispenser_node:
			#dispenser_node.texture = new_texture
			#
	## Handle "Spawn" scripts or generic sprites (chickens.gd)
	#elif "texture" in dispenser_node:
		## Directly update the main texture
		#dispenser_node.texture = new_texture
		#
	## Fallback for nodes using a child Sprite
	#elif dispenser_node.has_node("Sprite"):
		#var sprite = dispenser_node.get_node("Sprite")
		#if sprite is Sprite2D:
			#sprite.texture = new_texture

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
