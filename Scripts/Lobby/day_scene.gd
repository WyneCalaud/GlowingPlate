extends Node2D

var active_order: CustomerOrder = null

var order_index := 0

@onready var special_star = $SpecialStar
@onready var special_dim = $SpecialDim
@onready var cat_special_info = $CatSpecialInfo
@onready var key_popup = $KeyPopup
@onready var leo_special = $LeoSpecial

var special_intro_step := 0
var special_intro_active := false

var is_typing: bool = false
var full_dialogue_text: String = ""
var typing_speed: float = 0.06

func _ready():
	$CustomerManager.customer_arrived.connect(_on_customer_arrived)
	$CustomerManager.customer_left.connect(_on_customer_left)

	# HARD OVERRIDE
	if GameData.force_hide_accept_buttons:
		$BtnAccept.hide()
		$BtnContinue.hide()
	else:
		$BtnAccept.hide()
		$BtnContinue.hide()

	$DialogueBox.hide()

	if GameData.saved_customer_order != null:
		$CustomerManager.spawn_customer(
			GameData.saved_customer_order,
			GameData.saved_customer_texture
		)
		
		GameData.returning_from_beverage = false


func _on_customer_arrived(order: CustomerOrder):

	active_order = order

	# 🔒 SAFETY CHECK (important)
	if order == null:
		special_star.hide()
		return

	OrderSystem.set_order_from_customer(order)

	# --- Special Character Star ---
	if order.customer_name in ["Leo", "Maya", "Norma"]:
		special_star.show()
	else:
		special_star.hide()

	var GD := get_node("/root/GameData")

	# 🚫 If returning from kitchen/beverage, DO NOT show dialogue/buttons
	if GD.service_state == GameData.ServiceState.IN_KITCHEN \
	or GD.returning_from_beverage \
	or GD.service_state == GameData.ServiceState.SERVED:
		$DialogueBox.hide()
		$BtnAccept.hide()
		$BtnContinue.hide()
		return

	# ✅ FIRST ARRIVAL ONLY
	if GD.service_state == GameData.ServiceState.CUSTOMER_PRESENT:
		$DialogueBox.show()
		await typewriter_words(order.order_text)
		$BtnAccept.show()
		$BtnContinue.show()
		
	# --- First Time Special Intro ---
	if order.customer_name in ["Leo"]:
		if not GameData.special_intro_shown.get(order.customer_name, false):
			GameData.special_intro_shown[order.customer_name] = true
			_start_special_intro(order.customer_name)
			return



func _on_customer_left():
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()
	special_star.hide()



func _on_btn_accept_pressed() -> void:
	GameData.service_state = GameData.ServiceState.IN_KITCHEN

	# START GLOBAL PATIENCE
	GameData.customer_patience = 100.0
	GameData.patience_running = true

	get_tree().call_group("HUD", "start_patience")

	$BtnAccept.hide()
	$BtnContinue.hide()

	get_tree().change_scene_to_file("res://Scenes/Gameplay/KitchenArea.tscn")

func _on_btn_continue_pressed() -> void:
	if active_order == null:
		return
	# Replace the dialogue text with the expanded clarification
	await typewriter_words(active_order.expanded_text)

func _end_day():
	# CRITICAL FIX:
	# This function was causing a crash by trying to access GameData 
	# while the scene was already transitioning to EndDayResult.
	
	# Since GameData.finalize_service() now handles the transition 
	# to the EndDayResult scene automatically, we do NOT want to 
	# force a scene change back to the Lobby here.
	
	if not is_inside_tree(): return
	
	# We only reset state if we are manually ending the day logic without a transition
	# But in your current flow, GameData handles it.
	pass

func _start_special_intro(name:String):

	special_intro_active = true
	special_intro_step = 0
	
	leo_special.show()
	special_dim.show()
	cat_special_info.show()
	key_popup.hide()

	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()
	$"../OverlayCanvas/GameHUD".hide()

	_update_special_image(name)

func _input(event):

	if not special_intro_active:
		return

	if event is InputEventMouseButton and event.pressed:
		_handle_special_tap()

func _handle_special_tap():

	special_intro_step += 1

	if special_intro_step >= 5:
		_end_special_intro()
	else:
		_update_special_image(active_order.customer_name)

func _unhandled_input(event):

	if event.is_action_pressed("ui_accept") and is_typing:
		$DialogueBox/OrderText.text = full_dialogue_text
		is_typing = false

func _update_special_image(name:String):

	var path = "res://Assets/UI/SpecialInfo/%s_%d.png" % [name, special_intro_step + 1]
	cat_special_info.texture = load(path)

	# Reveal key popup after 2nd image
	if special_intro_step == 1:
		key_popup.show()

func _on_special_tapped(event):

	if not (event is InputEventMouseButton and event.pressed):
		return

	special_intro_step += 1

	if special_intro_step >= 5:
		_end_special_intro()
	else:
		_update_special_image(active_order.customer_name)

func _end_special_intro():

	special_intro_active = false

	special_dim.hide()
	cat_special_info.hide()
	key_popup.hide()
	leo_special.hide()

	# Resume normal dialogue
	$DialogueBox.show()
	$DialogueBox/OrderText.text = active_order.order_text
	$BtnAccept.show()
	$BtnContinue.show()
	$"../OverlayCanvas/GameHUD".show()

func typewriter_words(text: String) -> void:

	is_typing = true
	full_dialogue_text = text
	$DialogueBox/OrderText.text = ""

	var words: PackedStringArray = text.split(" ")
	var built_text: String = ""

	for i in words.size():

		built_text += words[i]

		if i < words.size() - 1:
			built_text += " "

		$DialogueBox/OrderText.text = built_text

		await get_tree().create_timer(typing_speed).timeout

	is_typing = false
