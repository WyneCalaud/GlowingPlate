# KitchenArea.gd
extends Node2D

# --- STATE ---
var plate_served: bool = false
var beverage_served: bool = false
var default_positions: Dictionary = {}

# --- STORE ORIGINAL DROP ZONE POSITION ---
var drop_zones_default_position: Vector2

# --- REFERENCES TO FOOD DISPENSER ARRAYS ---
@onready var go_stations = [
	$Row1/HBoxContainter/Slot3,
	$Row3/HBoxContainter/Slot2,
	$Row1/HBoxContainter/Slot6
]

@onready var grow_stations = [
	$Row1/HBoxContainter/Slot1,
	$Row1/HBoxContainter/Slot2,
	$Row1/HBoxContainter/Slot5,
]

@onready var veg_stations = [
	$Row2/HBoxContainter/Slot1,
	$Row2/HBoxContainter/Slot2,
	$Row2/HBoxContainter/Slot3,
	$Row1/HBoxContainter/Slot4,
]

@onready var fru_stations = [
	$Row3/HBoxContainter/Slot1,
	$Row3/HBoxContainter/Slot3,
	$Row3/HBoxContainter/Slot4,
	$Row2/HBoxContainter/Slot4
]

# --- Node References ---
@onready var food_plate: Node2D = $Plate/FoodPlate 
@onready var camera: Camera2D = get_viewport().get_camera_2d()

@onready var order_ticket = $OrderTicket

# --- DYNAMIC LAYOUT NODES (BROWN RICE) ---
@onready var brown_rice_mat = get_node_or_null("Go Section/BrownRiceCupMat")
@onready var brown_rice_cooker = get_node_or_null("Go Section/BrownRiceCooker")
@onready var brown_rice_cup = get_node_or_null("Go Section/BrownRiceCup")

@onready var row1 = get_node_or_null("Row1")
@onready var row2 = get_node_or_null("Row2")
@onready var row3 = get_node_or_null("Row3")
@onready var mat_node = get_node_or_null("Mat")
@onready var plate_parent = get_node_or_null("Plate")
@onready var beverages_station = get_node_or_null("BeveragesStation")

# --- UI & HUD ---
@onready var game_hud = $OverlayCanvas/GameHUD

# --- SERVE & TRASH ZONES ---
@onready var drop_zones_parent: Node2D = $ServeOrTrash
@onready var serve_zone: Area2D = $ServeOrTrash/Serve/GlobalServeZone
@onready var trash_zone: Area2D = $ServeOrTrash/Trash/GlobalTrashZone

func _ready():
	# 1. Store Default Positions
	if row1: default_positions["row1"] = row1.position
	if row2: default_positions["row2"] = row2.position
	if row3: default_positions["row3"] = row3.position
	if mat_node: default_positions["mat_node"] = mat_node.position
	if plate_parent: default_positions["plate_parent"] = plate_parent.position
	if beverages_station: default_positions["beverages_station"] = beverages_station.position

	add_to_group("service_manager")

	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = false
		drop_zones_parent.z_index = 50
		drop_zones_default_position = drop_zones_parent.global_position
	else:
		print("Error: ServeOrTrash node not found at $ServeOrTrash")

	setup_kitchen_for_today()

	await get_tree().process_frame
	if is_instance_valid(food_plate):
		if not food_plate.is_connected("drag_state_changed", _on_plate_drag_state_changed):
			food_plate.connect("drag_state_changed", _on_plate_drag_state_changed)

	if is_instance_valid(game_hud):
		game_hud.update_all_labels()
		if game_hud.has_method("show_finish_button"):
			game_hud.show_finish_button(false)

	if GameData.saved_customer_order and is_instance_valid(order_ticket):
		order_ticket.set_order_display(GameData.saved_customer_order)

# ---------------------------------------------------------
# DROP ZONE CONTROL
# ---------------------------------------------------------

func move_zones_to_kitchen():
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.global_position = drop_zones_default_position

func move_zones_to_beverage(target_x: float):
	if is_instance_valid(drop_zones_parent):
		var pos = drop_zones_parent.global_position
		pos.x = target_x
		drop_zones_parent.global_position = pos

func show_drop_zones():
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = true

func hide_drop_zones():
	if is_instance_valid(drop_zones_parent):
		drop_zones_parent.visible = false
		move_zones_to_kitchen()

# ---------------------------------------------------------
# SERVICE MECHANICS
# ---------------------------------------------------------

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

func _check_requirements():
	if plate_served and beverage_served:
		if game_hud:
			game_hud.show_finish_button(true)

func reset_service():
	plate_served = false
	beverage_served = false
	if game_hud:
		game_hud.show_finish_button(false)

# ---------------------------------------------------------
# KITCHEN SETUP
# ---------------------------------------------------------

func setup_kitchen_for_today():
	var GD = get_node_or_null("/root/GameData")
	var OS = get_node_or_null("/root/OrderSystem")

	if !GD or !OS:
		push_error("KitchenArea: Missing Singletons!")
		return

	var day = GD.current_day
	var menu_key = day if OS.MENU_SCHEDULE.has(day) else 1
	var menu = OS.MENU_SCHEDULE[menu_key]

	update_station_list(go_stations, menu, "Go")
	update_station_list(grow_stations, menu, "Grow")
	update_station_list(veg_stations, menu, "GlowVeg")
	update_station_list(fru_stations, menu, "GlowFru")

	# --- BROWN RICE DYNAMIC LAYOUT ---
	var has_brown_rice = false
	if menu.has("Go"):
		var go_items = menu["Go"]
		if go_items is String and go_items == "BROWN_RICE":
			has_brown_rice = true
		elif go_items is Array and "BROWN_RICE" in go_items:
			has_brown_rice = true

	# Toggle Visibility
	if brown_rice_mat: brown_rice_mat.visible = has_brown_rice
	if brown_rice_cooker: brown_rice_cooker.visible = has_brown_rice
	if brown_rice_cup: brown_rice_cup.visible = has_brown_rice

	# Adjust Positions Safely (using set_deferred to prevent infinite layout loops)
	if has_brown_rice:
		if beverages_station: beverages_station.set_deferred("position", Vector2(1575.0, 1.0))
		if row1: row1.set_deferred("position", Vector2(564.0, 77.0))
		if row2: row2.set_deferred("position", Vector2(1005.0, 288.0))
		if row3: row3.set_deferred("position", Vector2(998.0, 494.0))
		if mat_node: mat_node.set_deferred("position", Vector2(272.0, 0.0))
		if plate_parent: plate_parent.set_deferred("position", Vector2(272.0, 0.0))
	else:
		if beverages_station and default_positions.has("beverages_station"): beverages_station.set_deferred("position", default_positions["beverages_station"])
		if row1 and default_positions.has("row1"): row1.set_deferred("position", default_positions["row1"])
		if row2 and default_positions.has("row2"): row2.set_deferred("position", default_positions["row2"])
		if row3 and default_positions.has("row3"): row3.set_deferred("position", default_positions["row3"])
		if mat_node and default_positions.has("mat_node"): mat_node.set_deferred("position", default_positions["mat_node"])
		if plate_parent and default_positions.has("plate_parent"): plate_parent.set_deferred("position", default_positions["plate_parent"])

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

# ---------------------------------------------------------
# PLATE DRAG HANDLER
# ---------------------------------------------------------

func _on_plate_drag_state_changed(is_dragging_now: bool):
	if not is_instance_valid(drop_zones_parent):
		return

	if is_dragging_now:
		var contents = food_plate.get_plate_contents()
		if contents.size() > 0:
			move_zones_to_kitchen()
			show_drop_zones()
	else:
		hide_drop_zones()

func _on_exit_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
