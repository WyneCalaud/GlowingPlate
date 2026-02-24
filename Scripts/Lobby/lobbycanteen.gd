extends Control

# --- References ---
@onready var darken_overlay = $OverlayCanvas/DarkenOverlay
@onready var almanac_ui = $OverlayCanvas/AlmanacUI
@onready var glowboard = $OverlayCanvas/GlowBoard
@onready var nutrishop_ui = $OverlayCanvas/NutriShop
@onready var glow_desk_ui = $OverlayCanvas/GlowDesk

@onready var day_scene = $DayScene
@onready var dialogue_box = $DayScene/DialogueBox
@onready var next_customer_btn = $DayScene/NextCustomer
@onready var customer_manager = $DayScene/CustomerManager

@onready var bottom_buttons = $BottomButtons
@onready var hideshowbutton = $BottomButtons/HBoxContainer/HideShowButton
@onready var almanac_btn = $BottomButtons/HBoxContainer/Almanac
@onready var bulletin_btn = $BottomButtons/HBoxContainer/GlowBoard
@onready var start_day_btn = $BottomButtons/StartDayButton
@onready var nutridesk_btn = $BottomButtons/HBoxContainer/GlowDesk
@onready var nutrishop_btn = $BottomButtons/HBoxContainer/GlowShop

@onready var final_plate_display = $FinalPlateDisplay
@onready var final_beverage_display = $FinalBeverageDisplay

# --- State Variables ---
var current_open_popup: Control = null
var current_popup_tween: Tween
var button_type = null

var current_happiness: float = 100.0
var happiness_decay_rate: float = 2.0
var is_waiting_for_serve: bool = false


# ---------------------------------------------------------
# LIFECYCLE
# ---------------------------------------------------------

func _ready() -> void:
	dialogue_box.hide()
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()

	if almanac_ui.has_signal("closed"):
		if not almanac_ui.closed.is_connected(_on_almanac_ui_closed):
			almanac_ui.closed.connect(_on_almanac_ui_closed)

	if glowboard.has_signal("closed"):
		if not glowboard.closed.is_connected(_on_glowboard_closed):
			glowboard.closed.connect(_on_glowboard_closed)
			
	if nutrishop_ui.has_signal("closed"):
		if not nutrishop_ui.closed.is_connected(_on_nutri_shop_closed):
			nutrishop_ui.closed.connect(_on_nutri_shop_closed)

	if glow_desk_ui.has_signal("closed"):
		if not glow_desk_ui.closed.is_connected(_on_glow_desk_closed):
			glow_desk_ui.closed.connect(_on_glow_desk_closed)

	if nutridesk_btn:
		if not nutridesk_btn.pressed.is_connected(_on_glow_desk_pressed):
			nutridesk_btn.pressed.connect(_on_glow_desk_pressed)

	_check_for_returned_items()
	_restore_day_ui_state()


func _process(delta: float) -> void:
	if is_waiting_for_serve:
		current_happiness = max(0.0, current_happiness - (happiness_decay_rate * delta))


# ---------------------------------------------------------
# STATE RESTORE
# ---------------------------------------------------------

func _restore_day_ui_state() -> void:
	var gd := get_node("/root/GameData")

	if gd.day_started:
		var is_idle = (gd.service_state == GameData.ServiceState.IDLE)
		next_customer_btn.visible = is_idle
		is_waiting_for_serve = !is_idle

		almanac_btn.hide()
		bulletin_btn.hide()
		start_day_btn.hide()
		nutridesk_btn.hide()
		nutrishop_btn.hide()
		hideshowbutton.hide()
		bottom_buttons.hide() # <-- ADDED THIS
	else:
		is_waiting_for_serve = false
		next_customer_btn.hide()

		almanac_btn.show()
		bulletin_btn.show()
		start_day_btn.show()
		nutridesk_btn.show()
		nutrishop_btn.show()
		hideshowbutton.show()
		bottom_buttons.show() # <-- ADDED THIS


func _check_for_returned_items() -> void:
	if OrderSystem.prepared_plate_contents.size() > 0:
		show_final_plate(OrderSystem.prepared_plate_contents)
	else:
		final_plate_display.hide()

	if OrderSystem.prepared_beverage_data.size() > 0:
		show_final_beverages(OrderSystem.prepared_beverage_data)
	else:
		final_beverage_display.hide()


# ---------------------------------------------------------
# DEBUG HELPERS
# ---------------------------------------------------------

func _debug_plate_slots() -> void:
	print("==== 🧪 PLATE DEBUG ====")

	# Explicitly typed dictionaries
	var expected: Dictionary = OrderSystem.current_customer_order.required_plate
	var plated: Dictionary = {}

	# Build what the player plated
	for entry: Dictionary in OrderSystem.prepared_plate_contents:
		var slot: String = entry.get("accepted_type", "") as String
		if slot != "":
			var item = entry.get("item")
			if item and item.has_method("get"):
				plated[slot] = item.internal_key

	# Explicitly typed slot list
	var slots: Array[String] = ["Go", "Grow", "GlowVeg", "GlowFru"]

	for slot: String in slots:
		var exp: String = expected.get(slot, "") as String
		var act: String = plated.get(slot, "") as String

		var status: String = "✅ OK"
		if act == "":
			status = "❌ MISSING"
		elif act != exp:
			status = "❌ WRONG"

		print(
			slot.lpad(8),
			"| Expected:", exp.lpad(14),
			"| Actual:", act.lpad(14),
			"|", status
		)

	print("========================")


# ---------------------------------------------------------
# TEXTURE RESOLUTION (FIXED)
# ---------------------------------------------------------

func _get_item_texture(entry: Dictionary) -> Texture2D:
	var res = entry.get("item")
	if not res:
		return null

	var base_tex = res.get("default_plated_texture")

	var portion: String = str(entry.get("portion_type", ""))
	if portion == "":
		portion = str(res.get_meta("Portion", ""))

	var count: int = int(entry.get("count", 1))

	# --- Veggie Cup Handling ---
	if portion == "VeggieFull":
		var veg_tex = res.get("veggie_plated_full")
		if veg_tex:
			return veg_tex
	elif portion == "VeggieHigh":
		var veg_tex = res.get("veggie_plated_high")
		if veg_tex:
			return veg_tex

	# --- Portion Handling ---
	if portion == "Half":
		match count:
			2: return res.get("plated_texture_half_2")
			3: return res.get("plated_texture_half_3")
			_: return res.get("plated_texture_half")

	elif portion == "Whole":
		match count:
			2: return res.get("plated_texture_whole_2")
			3: return res.get("plated_texture_whole_3")
			_: return res.get("plated_texture_whole")

	# --- Rice / Drink Meta ---
	var rice_amt = res.get_meta("RiceAmount", "")
	var drink_amt = res.get_meta("DrinkAmount", "")

	if rice_amt != "":
		match rice_amt:
			"Small": return res.get("plated_texture_small")
			"Medium": return res.get("plated_texture_medium")
			"TooHigh": return res.get("plated_texture_too_high")

	if drink_amt != "":
		match drink_amt:
			"Low": return res.get("plated_texture_small")
			"Medium": return res.get("plated_texture_medium")
			"TooHigh": return res.get("plated_texture_too_high")

	# --- Standard Stack Counts ---
	match count:
		2: return res.get("texture_count_2")
		3: return res.get("texture_count_3")
		4: return res.get("texture_count_4")
		5: return res.get("texture_count_5")
		_:
			var c1 = res.get("texture_count_1")
			if c1:
				return c1

	return base_tex


# ---------------------------------------------------------
# FINAL PLATE DISPLAY
# ---------------------------------------------------------

func show_final_plate(contents: Array) -> void:
	final_plate_display.show()
	$FinalPlateDisplay/PlateDisplay.texture = preload("res://Items/Plates/Plate Final.png")

	var sprite_map = {
		"Go": $FinalPlateDisplay/PlateSpriteGo,
		"Grow": $FinalPlateDisplay/PlateSpriteGrow,
		"GlowVeg": $FinalPlateDisplay/PlateSpriteVeg,
		"GlowFru": $FinalPlateDisplay/PlateSpriteFru
	}

	for s in sprite_map.values():
		s.hide()

	for entry in contents:
		var category = entry.get("accepted_type")
		var sprite = sprite_map.get(category)
		var tex = _get_item_texture(entry)

		if sprite and tex:
			sprite.texture = tex
			sprite.scale = Vector2(0.1, 0.1)
			sprite.show()


# ---------------------------------------------------------
# FINAL BEVERAGE DISPLAY
# ---------------------------------------------------------

func show_final_beverages(beverage_data: Dictionary) -> void:
	final_beverage_display.show()

	var sprites = [
		$FinalBeverageDisplay/BeverageSprite1,
		$FinalBeverageDisplay/BeverageSprite2
	]

	for s in sprites:
		s.hide()

	var index := 0
	for entry in beverage_data.values():
		if index >= sprites.size():
			break

		var tex = _get_item_texture(entry)
		if tex:
			sprites[index].texture = tex
			sprites[index].scale = Vector2(0.3, 0.3)
			sprites[index].show()
			index += 1


# ---------------------------------------------------------
# SERVE BUTTON
# ---------------------------------------------------------

func _on_btn_final_serve_pressed() -> void:
	var GD = get_node("/root/GameData")
	is_waiting_for_serve = false

	_debug_plate_slots() # 👈 DEBUG CALL

	var correct := (
		OrderSystem.is_plate_correct()
		and OrderSystem.is_beverage_correct()
	)

	if not correct:
		current_happiness = clamp(current_happiness - 30.0, 0.0, 100.0)

	var character_id := ""
	if GD.saved_customer_order:
		character_id = GD.saved_customer_order.customer_name

	GD.finalize_service({
		"earned_money": 10 if correct else 0,
		"reputation_change": 1.0 if correct else -0.5,
		"happiness": current_happiness,
		"character_id": character_id,
		"prog_gain": 34.0 if correct else 0.0,
		"is_correct": correct
	})

	GD.clear_customer()
	GD.service_state = GameData.ServiceState.SERVED
	current_happiness = 100.0

	final_beverage_display.hide()
	final_plate_display.hide()

	dialogue_box.show()
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()
	$DayScene/DialogueBox/OrderText.text = "😊" if correct else "😢"

	customer_manager.next_customer()

	if not GD.remaining_customers.is_empty():
		next_customer_btn.show()


# ---------------------------------------------------------
# DAY BUTTON
# ---------------------------------------------------------

func _on_day_button_pressed() -> void:
	var GD := get_node("/root/GameData")
	var day_orders: Array = []

	match GD.current_day:

		1:
			day_orders = [
				preload("res://Data/Customer/Day1one.tres"),
				preload("res://Data/Customer/Day1two.tres"),
				preload("res://Data/Customer/Day1three.tres")
			]

		2:
			day_orders = [
				preload("res://Data/Customer/Day2one.tres"),
				preload("res://Data/Customer/Day2two.tres"),
				preload("res://Data/Customer/Day2three.tres"),
				preload("res://Data/Customer/Day2four.tres")
			]

		3:
			day_orders = [
				preload("res://Data/Customer/Day3one.tres"),
				preload("res://Data/Customer/Day3two.tres"),
				preload("res://Data/Customer/Day3three.tres")
			]

		_:
			day_orders = [
				preload("res://Data/Customer/Day1one.tres")
			]

	GD.start_day_with_orders(day_orders)
	_restore_day_ui_state()


func _emit_customer_exit():
	var manager = get_tree().get_first_node_in_group("CustomerManager")
	if manager and manager.current_customer:
		manager.customer_leave()

# --- Scene Transitions ---

func _start_transition(type: String):
	button_type = type
	$Fade_transition.show()
	$Fade_transition/Fade_timer.start()
	$Fade_transition/AnimationPlayer.play("Fade_In")

func _on_fade_timer_timeout() -> void:
	if button_type == "menu":
		get_tree().change_scene_to_file("res://Scenes/Main Menu/Main_menu.tscn")

func _on_settings_button_pressed() -> void:
	_start_transition("menu")


# ---------------------------------------------------------
# POPUP LOGIC
# ---------------------------------------------------------

func _on_glow_desk_pressed() -> void:
	if current_open_popup == glow_desk_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(glow_desk_ui)

func open_popup(popup_node: Control) -> void:
	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	current_open_popup = popup_node 
	darken_overlay.show()
	current_open_popup.show()
	
	current_popup_tween = create_tween().set_parallel(true)
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.5, 0.3)
	current_popup_tween.tween_property(current_open_popup, "modulate:a", 1.0, 0.3).from(0.0)
	
func close_popup() -> void:
	if current_open_popup == null:
		return

	if current_popup_tween and current_popup_tween.is_valid():
		current_popup_tween.kill()

	var popup_to_close = current_open_popup
	current_open_popup = null 
	
	current_popup_tween = create_tween().set_parallel(true)
	current_popup_tween.tween_property(darken_overlay, "modulate:a", 0.0, 0.3)
	current_popup_tween.tween_property(popup_to_close, "modulate:a", 0.0, 0.3)
	current_popup_tween.finished.connect(func(): 
		darken_overlay.hide()
		popup_to_close.hide()
		popup_to_close.modulate.a = 1.0
	)

func _on_almanac_ui_closed() -> void: close_popup()
func _on_glowboard_closed() -> void: close_popup()
func _on_nutri_shop_closed() -> void: close_popup()
func _on_glow_desk_closed() -> void: close_popup()


func _on_almanac_pressed() -> void:
	if current_open_popup == almanac_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(almanac_ui)


func _on_glow_board_pressed() -> void:
	if current_open_popup == glowboard:
		close_popup()
	elif current_open_popup == null:
		open_popup(glowboard)


func _on_glow_shop_pressed() -> void:
	if current_open_popup == nutrishop_ui:
		close_popup()
	elif current_open_popup == null:
		open_popup(nutrishop_ui)
