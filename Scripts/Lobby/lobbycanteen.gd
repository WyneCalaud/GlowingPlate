extends Control

# --- References ---
@onready var darken_overlay = $OverlayCanvas/DarkenOverlay
@onready var almanac_ui = $OverlayCanvas/AlmanacUI
@onready var bulletin_board_ui = $OverlayCanvas/BulletinBoardUI

@onready var day_scene = $DayScene
@onready var dialogue_box = $DayScene/DialogueBox
@onready var next_customer_btn = $DayScene/NextCustomer
@onready var customer_manager = $DayScene/CustomerManager

@onready var bottom_buttons = $BottomButtons
@onready var almanac_btn = $BottomButtons/AlmanacButton
@onready var bulletin_btn = $BottomButtons/BulletinBoardButton
@onready var start_day_btn = $BottomButtons/StartDayButton
@onready var nutridesk_btn = $BottomButtons/NutriDeskButton
@onready var nutrishop_btn = $BottomButtons/NutriShopButton

@onready var final_plate_display = $FinalPlateDisplay
@onready var final_beverage_display = $FinalBeverageDisplay

# --- State Variables ---
var current_open_popup: Control = null
var current_popup_tween: Tween
var button_type = null

var current_happiness: float = 100.0
var happiness_decay_rate: float = 2.0
var is_waiting_for_serve: bool = false

# --- Lifecycle ---

func _ready() -> void:
	dialogue_box.hide()
	$DayScene/BtnAccept.hide()
	$DayScene/BtnContinue.hide()

	_check_for_returned_items()
	_restore_day_ui_state()

func _process(delta: float) -> void:
	if is_waiting_for_serve:
		current_happiness = max(0.0, current_happiness - (happiness_decay_rate * delta))

# --- Logic & State ---

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
	else:
		is_waiting_for_serve = false
		next_customer_btn.hide()
		
		almanac_btn.show()
		bulletin_btn.show()
		start_day_btn.show()
		nutridesk_btn.show()
		nutrishop_btn.show()

func _check_for_returned_items() -> void:
	if OrderSystem.prepared_plate_contents.size() > 0:
		show_final_plate(OrderSystem.prepared_plate_contents)
	else:
		final_plate_display.hide()

	if OrderSystem.prepared_beverage_data.size() > 0:
		show_final_beverages(OrderSystem.prepared_beverage_data)
	else:
		final_beverage_display.hide()

# --- DEBUG HELPERS ---

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

# --- Display Helpers ---

func _get_item_texture(res: Resource) -> Texture2D:
	if not res: return null
	var tex = res.get("default_plated_texture")

	if res.has_meta("RiceAmount"):
		match res.get_meta("RiceAmount"):
			"Small": tex = res.get("plated_texture_small")
			"TooHigh": tex = res.get("plated_texture_too_high")
	elif res.has_meta("DrinkAmount"):
		match res.get_meta("DrinkAmount"):
			"Low": tex = res.get("plated_texture_small")
			"Medium": tex = res.get("plated_texture_medium")
			"TooHigh": tex = res.get("plated_texture_too_high")

	return tex

func show_final_plate(contents: Array) -> void:
	final_plate_display.show()
	$FinalPlateDisplay/PlateDisplay.texture = preload("res://Items/Plates/Plate Final.png")

	var sprite_map = {
		"Go": $FinalPlateDisplay/PlateSpriteGo,
		"Grow": $FinalPlateDisplay/PlateSpriteGrow,
		"GlowVeg": $FinalPlateDisplay/PlateSpriteVeg,
		"GlowFru": $FinalPlateDisplay/PlateSpriteFru
	}

	for s in sprite_map.values(): s.hide()

	for entry in contents:
		var category = entry.get("accepted_type")
		var sprite = sprite_map.get(category)
		var tex = _get_item_texture(entry.get("item"))

		if sprite and tex:
			sprite.texture = tex
			sprite.scale = Vector2(0.1, 0.1)
			sprite.show()

func show_final_beverages(beverage_data: Dictionary) -> void:
	final_beverage_display.show()
	var sprites = [$FinalBeverageDisplay/BeverageSprite1, $FinalBeverageDisplay/BeverageSprite2]
	for s in sprites: s.hide()

	var index := 0
	for entry in beverage_data.values():
		if index >= sprites.size(): break
		var tex = _get_item_texture(entry.get("item"))
		if tex:
			sprites[index].texture = tex
			sprites[index].scale = Vector2(0.3, 0.3)
			sprites[index].show()
			index += 1

# --- Signal Handlers ---

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

	GD.finalize_service({
		"earned_money": 10 if correct else 0,
		"reputation_change": 1.0 if correct else -0.5,
		"happiness": current_happiness
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

# --- Remaining code unchanged ---


func _on_day_button_pressed() -> void:
	var GD := get_node("/root/GameData")
	var day_orders: Array[CustomerOrder] = [
		preload("res://Data/Customer/Day1one.tres"),
		preload("res://Data/Customer/Day1two.tres"),
		preload("res://Data/Customer/Day1three.tres")
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

# --- Popup Logic ---

func _on_almanac_pressed() -> void:
	if current_open_popup == almanac_ui: close_popup()
	elif current_open_popup == null: open_popup(almanac_ui)

func _on_bulletin_board_pressed() -> void:
	if current_open_popup == bulletin_board_ui: close_popup()
	elif current_open_popup == null: open_popup(bulletin_board_ui)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and current_open_popup != null:
		close_popup()

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
	if current_open_popup == null: return
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
func _on_bulletin_board_ui_closed() -> void: close_popup()
