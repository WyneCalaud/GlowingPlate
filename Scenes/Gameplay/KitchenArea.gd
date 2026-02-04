# KitchenArea.gd

extends Node2D

# --- STATE ---
var plate_served: bool = false
var beverage_served: bool = false

# --- REFERENCES TO FOOD DISPENSER ARRAYS ---
@onready var go_stations = []

@onready var grow_stations = [
	$Row1/HBoxContainter/Slot1,
	$Row1/HBoxContainter/Slot2,
	$Row1/HBoxContainter/Slot3,
	$Row1/HBoxContainter/Slot4,
	$Row1/HBoxContainter/Slot5,
	$Row1/HBoxContainter/Slot6
]

@onready var veg_stations = [
	$Row2/HBoxContainter/Slot1,
	$Row2/HBoxContainter/Slot2,
	$Row2/HBoxContainter/Slot3,
	$Row2/HBoxContainter/Slot4
]

@onready var fru_stations = [
	$Row3/HBoxContainter/Slot1,
	$Row3/HBoxContainter/Slot2,
	$Row3/HBoxContainter/Slot3,
	$Row3/HBoxContainter/Slot4
]

# --- Node References ---
@onready var food_plate: Node2D = $Plate/FoodPlate 
@onready var camera: Camera2D = get_viewport().get_camera_2d()

# --- UI & HUD ---
@onready var game_hud = $OverlayCanvas/GameHUD

# --- SERVE & TRASH ZONES (FIXED PATHS) ---
# These are now in the KitchenArea root, NOT inside GameHUD
@onready var drop_zones_parent: Node2D = $ServeOrTrash
@onready var serve_zone: Area2D = $ServeOrTrash/Serve/GlobalServeZone
@onready var trash_zone: Area2D = $ServeOrTrash/Trash/GlobalTrashZone

func _ready():
	# 1. Setup Service Group for Plate Interaction
	add_to_group("service_manager")

	# 2. Setup Initial State
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = false
	else:
		print("Error: ServeOrTrash node not found at $ServeOrTrash")
	
	# 3. Setup the Menu for the Day
	setup_kitchen_for_today()
		
	# 4. Connect Plate Signals
	await get_tree().process_frame
	if is_instance_valid(food_plate):
		if not food_plate.is_connected("drag_state_changed", _on_plate_drag_state_changed):
			food_plate.connect("drag_state_changed", _on_plate_drag_state_changed)
	
	# 5. Initialize HUD
	if is_instance_valid(game_hud):
		game_hud.update_all_labels()
		if game_hud.has_method("show_finish_button"):
			game_hud.show_finish_button(false)

# --- SERVICE MECHANICS (Called by Plate/Glass) ---

func serve_plate(contents: Array):
	var GD = get_node("/root/GameData")
	if GD:
		GD.store_plate_contents(contents)
	
	plate_served = true
	_check_requirements()
	print("KitchenArea: Plate Served")

func serve_beverage():
	beverage_served = true
	_check_requirements()
	print("KitchenArea: Beverage Served")

func trash_item():
	print("KitchenArea: Item Trashed")
	# Add trash sound effect here if desired

func _check_requirements():
	if plate_served and beverage_served:
		if game_hud:
			game_hud.show_finish_button(true)

func reset_service():
	plate_served = false
	beverage_served = false
	if game_hud:
		game_hud.show_finish_button(false)

# --- KITCHEN SETUP LOGIC ---

func setup_kitchen_for_today():
	var GD = get_node_or_null("/root/GameData")
	var OS = get_node_or_null("/root/OrderSystem")
	
	if !GD or !OS:
		push_error("KitchenArea: Missing Singletons!")
		return

	var day = GD.current_day
	var menu_key = day if OS.MENU_SCHEDULE.has(day) else 1
	var menu = OS.MENU_SCHEDULE[menu_key]
	
	if has_node("Row0"): update_station_list(go_stations, menu, "Go")
	update_station_list(grow_stations, menu, "Grow")
	update_station_list(veg_stations, menu, "GlowVeg")
	update_station_list(fru_stations, menu, "GlowFru")

func update_station_list(station_nodes: Array, menu_data: Dictionary, category_key: String):
	var food_data = menu_data.get(category_key, [])
	var food_keys = []
	
	if food_data is String:
		food_keys = [food_data]
	elif food_data is Array:
		food_keys = food_data
			
	for i in range(station_nodes.size()):
		var dispenser = station_nodes[i]
		if !dispenser: continue
		
		if i < food_keys.size():
			dispenser.show()
			var item_key = food_keys[i]
			var db = get_node("/root/OrderSystem").FOOD_DB
			
			if db.has(item_key):
				update_dispenser_visuals(dispenser, db[item_key])
		else:
			dispenser.hide()

func update_dispenser_visuals(dispenser_node, food_res: Resource):
	if "food_data" in dispenser_node:
		dispenser_node.food_data = food_res
	elif "item_resource" in dispenser_node:
		dispenser_node.item_resource = food_res

func _on_plate_drag_state_changed(is_dragging_now: bool):
	if not is_instance_valid(drop_zones_parent): return
	
	if is_dragging_now:
		# Only show if there is actually food on the plate
		var contents = food_plate.get_plate_contents()
		if contents.size() > 0:
			drop_zones_parent.visible = true
		
		var cam = get_tree().get_first_node_in_group("MainCamera")
		if cam: cam.is_input_blocked = true
	else:
		drop_zones_parent.visible = false
		var cam = get_tree().get_first_node_in_group("MainCamera")
		if cam: cam.is_input_blocked = false

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
