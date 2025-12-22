extends Node2D

# --- References ---
@onready var darken_overlay = $OverlayCanvas/DarkenOverlay
@onready var almanac_ui = $OverlayCanvas/AlmanacUI
@onready var bulletin_board_ui = $OverlayCanvas/BulletinBoardUI

# --- State Variables ---
var current_open_popup: Control = null 
var current_popup_tween: Tween 
var button_type = null 

# --- Scene Transition Functions ---
func _start_transition(type: String):
	button_type = type
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_In")

func _on_day_button_pressed() -> void:
	var GD := get_node("/root/GameData")

	var day_orders: Array[CustomerOrder] = []
	# Ensure these paths match your actual resource paths
	day_orders.append(preload("res://Data/Customer/CustomerOrderTest2.tres"))
	day_orders.append(preload("res://Data/Customer/CustomerOrderTest3.tres"))
	day_orders.append(preload("res://Data/Customer/CustomerOrderTest.tres"))

	# GameData still handles the start of day logic wrapper
	GD.start_day_with_orders(day_orders)
	
	$DayScene/NextCustomer.show()
	$BottomButtons/Almanac/Almanac.hide()
	$"BottomButtons/Bulletin Board/Bulletin Board".hide()
	$"BottomButtons/Day/Day Button".hide()


func _on_fade_timer_timeout() -> void:
	if button_type == "menu" :
		get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_menu.tscn")

func _on_settings_button_pressed() -> void:
	_start_transition("menu")

# --- Popup Button Triggers ---
func _on_almanac_pressed() -> void:
	if current_open_popup == almanac_ui: close_popup()
	elif current_open_popup == null: open_popup(almanac_ui)

func _on_bulletin_board_pressed() -> void:
	if current_open_popup == bulletin_board_ui: close_popup()
	elif current_open_popup == null: open_popup(bulletin_board_ui)

# --- Generic Popup Functions ---
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and current_open_popup != null:
		close_popup()

func open_popup(popup_node: Control) -> void:
	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	current_open_popup = popup_node 
	darken_overlay.show()
	current_open_popup.show()
	
	current_popup_tween = create_tween()
	current_popup_tween.set_parallel(true)
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.5, 0.3)
	current_popup_tween.tween_property(current_open_popup, "modulate:a", 1.0, 0.3).from(0.0)
	
func close_popup() -> void:
	if current_open_popup == null: return
		
	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	var popup_to_close = current_open_popup
	current_open_popup = null 
	
	current_popup_tween = create_tween()
	current_popup_tween.set_parallel(true)
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.0, 0.3)
	current_popup_tween.tween_property(popup_to_close, "modulate:a", 0.0, 0.3)
	
	current_popup_tween.finished.connect(func(): 
		darken_overlay.hide()
		popup_to_close.hide()
		popup_to_close.modulate.a = 1.0
	)

func _on_almanac_ui_closed() -> void: close_popup()
func _on_bulletin_board_ui_closed() -> void: close_popup()

func _ready():
	$DayScene/DialogueBox.hide()
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()

	_check_for_returned_items()
	_restore_day_ui_state()

func _restore_day_ui_state():
	var gd := get_node("/root/GameData")

	if gd.day_started:
		if gd.service_state == GameData.ServiceState.IDLE:
			$DayScene/NextCustomer.show()
		else:
			$DayScene/NextCustomer.hide()
		$BottomButtons/Almanac/Almanac.hide()
		$"BottomButtons/Bulletin Board/Bulletin Board".hide()
		$"BottomButtons/Day/Day Button".hide()
	else:
		$DayScene/NextCustomer.hide()
		$BottomButtons/Almanac/Almanac.show()
		$"BottomButtons/Bulletin Board/Bulletin Board".show()
		$"BottomButtons/Day/Day Button".show()

func _check_for_returned_items():
	# FIX: Access OrderSystem instead of GameData for food checks
	# GameData no longer holds these variables directly.

	# ---- PLATE ----
	if OrderSystem.prepared_plate_contents.size() > 0:
		show_final_plate(OrderSystem.prepared_plate_contents)
	else:
		$FinalPlateDisplay.hide()

	# ---- BEVERAGES ----
	if OrderSystem.prepared_beverage_data.size() > 0:
		show_final_beverages(OrderSystem.prepared_beverage_data)
	else:
		$FinalBeverageDisplay.hide()


func show_final_plate(contents: Array) -> void:
	$FinalPlateDisplay.show()
	$FinalPlateDisplay/PlateDisplay.texture = preload("res://Items/Plates/Plate Final.png")

	$FinalPlateDisplay/PlateSpriteGo.hide()
	$FinalPlateDisplay/PlateSpriteGrow.hide()
	$FinalPlateDisplay/PlateSpriteVeg.hide()
	$FinalPlateDisplay/PlateSpriteFru.hide()

	var food_scale = Vector2(0.1, 0.1)

	for entry in contents:
		var res = entry.get("item")
		var category = entry.get("accepted_type")

		if not res: continue

		var tex = null
		if "default_plated_texture" in res:
			tex = res.default_plated_texture

		# Rice visual logic preserved from your old file
		if res.has_meta("RiceAmount"):
			match res.get_meta("RiceAmount"):
				"Small":  tex = res.plated_texture_small
				"TooHigh": tex = res.plated_texture_too_high

		var sprite: Sprite2D = null
		match category:
			"Go": sprite = $FinalPlateDisplay/PlateSpriteGo
			"Grow": sprite = $FinalPlateDisplay/PlateSpriteGrow
			"GlowVeg": sprite = $FinalPlateDisplay/PlateSpriteVeg
			"GlowFru": sprite = $FinalPlateDisplay/PlateSpriteFru

		if sprite and tex:
			sprite.texture = tex
			sprite.scale = food_scale
			sprite.show()

func _on_btn_final_serve_pressed() -> void:
	var GD = get_node("/root/GameData")

	# OrderSystem handles the logic
	var correct : bool = GD.is_plate_correct() and GD.is_beverage_correct()

	print("Customer happy!" if correct else "Customer unhappy!")

	var day_result = {
		"earned_money": 10 if correct else 0,
		"reputation_change": 1.0 if correct else -0.5
	}

	# This call handles the scene transition if the day is over
	GD.finalize_service(day_result)
	GD.clear_customer()
	GD.service_state = GameData.ServiceState.SERVED

	$FinalBeverageDisplay.hide()
	$FinalPlateDisplay.hide()

	var manager := $DayScene/CustomerManager
	
	# Show reaction
	$DayScene/DialogueBox.show()
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()

	var emoji := "😊" if correct else "😢"
	$DayScene/DialogueBox/OrderText.text = emoji
	manager.next_customer()

	# SAFETY: If the day ended, GameData has already changed the scene.
	# We only show the next button if there are actually customers left.
	if not GD.remaining_customers.is_empty():
		$DayScene/NextCustomer.show()

func _emit_customer_exit():
	var manager := get_tree().get_first_node_in_group("CustomerManager")
	if manager and manager.current_customer:
		manager.customer_leave()

func show_final_beverages(beverage_data: Dictionary) -> void:
	$FinalBeverageDisplay.show()
	$FinalBeverageDisplay/BeverageSprite1.hide()
	$FinalBeverageDisplay/BeverageSprite2.hide()

	var drink_scale := Vector2(0.3, 0.3)

	var index := 0
	for entry in beverage_data.values():
		if index >= 2: break
		
		var res: CustomItemData = entry.get("item")
		if not res: continue

		var tex: Texture2D = null
		if "default_plated_texture" in res:
			tex = res.default_plated_texture

		if res.has_meta("DrinkAmount"):
			match res.get_meta("DrinkAmount"):
				"Low":
					if res.has("plated_texture_small"): tex = res.plated_texture_small
				"Medium":
					if res.has("plated_texture_medium"): tex = res.plated_texture_medium
				"TooHigh":
					if res.has("plated_texture_too_high"): tex = res.plated_texture_too_high

		var sprite: Sprite2D = null
		match index:
			0: sprite = $FinalBeverageDisplay/BeverageSprite1
			1: sprite = $FinalBeverageDisplay/BeverageSprite2

		if sprite and tex:
			sprite.texture = tex
			sprite.scale = drink_scale
			sprite.show()

		index += 1
