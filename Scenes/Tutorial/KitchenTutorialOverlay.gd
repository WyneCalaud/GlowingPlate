extends CanvasLayer

var step := 0

@onready var dim := $Dim
@onready var popup := $PopupImage
@onready var pointer := $Pointer

@onready var cat_text := $CatText
@onready var cat_label := $CatText/Text
@onready var arrow := $Arrow

func _ready():
	cat_text.hide()
	arrow.hide()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	pointer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	start_step_0()

func show_cat_text(text:String):
	cat_label.text = text
	cat_text.show()

func hide_cat_text():
	cat_text.hide()

# -------------------------
# IMAGE STEPS (1–9)
# -------------------------

func start_step_0():
	show_popup("res://Assets/Tutorial/intro1.png")

func show_popup(path:String):
	popup.texture = load(path)
	popup.visible = true
	if not popup.is_connected("gui_input", _on_popup_clicked):
		popup.connect("gui_input", _on_popup_clicked)

func _on_popup_clicked(event):
	if not (event is InputEventMouseButton and event.pressed):
		return
	
	step += 1
	
	match step:
		1: show_popup("res://Assets/Tutorial/intro2.png")
		2: show_popup("res://Assets/Tutorial/intro3.png")
		3: show_popup("res://Assets/Tutorial/intro4.png")
		4: show_popup("res://Assets/Tutorial/intro5.png")
		5: show_popup("res://Assets/Tutorial/intro6.png")
		6: show_popup("res://Assets/Tutorial/intro7.png")
		7: show_popup("res://Assets/Tutorial/intro8.png")
		8: show_popup("res://Assets/Tutorial/intro9.png")
		9:
			popup.visible = false
			start_menu_highlight()
		20: show_popup("res://Assets/Tutorial/after_almanac2.png")
		21: show_popup("res://Assets/Tutorial/after_almanac3.png")
		22:
			popup.hide()
			start_rice_highlight()

func highlight_node(node):
	node.z_index = 200
	node.modulate = Color(1.8,1.8,1.8)

func start_menu_highlight():
	dim.show()
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if not hud:
		return
	
	var menu_btn = hud.menu_button
	
	highlight_node(menu_btn)

	pointer.global_position = menu_btn.global_position + Vector2(-100, -20)
	pointer.visible = true
	
	if not menu_btn.is_connected("pressed", _on_menu_pressed):
		menu_btn.pressed.connect(_on_menu_pressed)

func _on_menu_pressed():
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var hud = get_tree().get_first_node_in_group("HUD")
	var almanac_btn = hud.almanac_button
	
	highlight_node(almanac_btn)

	pointer.global_position = almanac_btn.global_position + Vector2(-100, 180)
	
	if not almanac_btn.is_connected("pressed", _on_almanac_pressed):
		almanac_btn.pressed.connect(_on_almanac_pressed)

func _on_almanac_pressed():
	pointer.hide()
	dim.hide()
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	
	var hud = get_tree().get_first_node_in_group("HUD")
	if not hud.almanac_ui.is_connected("closed", _on_almanac_closed):
		hud.almanac_ui.closed.connect(_on_almanac_closed)

func _on_almanac_closed():
	step = 20
	show_popup("res://Assets/Tutorial/after_almanac1.png")

func start_rice_highlight():
	dim.show()

	# Critical fix
	dim.mouse_filter = Control.MOUSE_FILTER_PASS
	dim.z_index = 0

	var kitchen = get_parent()
	var rice_cooker = kitchen.get_node("Go Section/RiceCooker")

	highlight_node(rice_cooker)

	pointer.global_position = rice_cooker.global_position + Vector2(-170, 230)
	pointer.show()

	start_waiting_for_rice_fill()


func start_waiting_for_rice_fill():
	var kitchen = get_parent()
	var rice_cup = kitchen.get_node("Go Section/RiceCup")

	if not rice_cup.is_connected("rice_scoop_completed", _on_rice_completed):
		rice_cup.connect("rice_scoop_completed", _on_rice_completed)


func _on_rice_completed(amount):
	pointer.hide()

	show_cat_text("For this customer, let’s fill the whole cup with rice.")

	await get_tree().create_timer(1.5).timeout

	start_rice_to_plate_step()


func start_rice_to_plate_step():
	hide_cat_text()

	var kitchen = get_parent()
	var rice_cup = kitchen.get_node("Go Section/RiceCup")
	var plate = kitchen.get_node("Plate/FoodPlate")

	highlight_node(rice_cup)

	arrow.global_position = rice_cup.global_position
	arrow.show()

	wait_for_plate_placement()
	
	
func wait_for_plate_placement():
	var kitchen = get_parent()
	var plate = kitchen.food_plate

	if not plate.is_connected("drag_state_changed", _on_plate_drag_changed):
		plate.connect("drag_state_changed", _on_plate_drag_changed)
		
		
func on_go_food_completed():
	arrow.hide()

	var kitchen = get_parent()
	var plate = kitchen.food_plate

	highlight_node(plate)

	show_cat_text("Wow! Now we have our Go Food")


func _on_plate_drag_changed(is_dragging: bool):
	if not is_dragging:
		check_plate_for_go_food()
		

func check_plate_for_go_food():
	var kitchen = get_parent()
	var contents = kitchen.food_plate.get_plate_contents()

	for entry in contents:
		var item_res = entry.get("item")
		if item_res and item_res.has_meta("RiceAmount"):
			var rice_amount = item_res.get_meta("RiceAmount")
			if rice_amount == "RightAmount":
				on_go_food_completed()
