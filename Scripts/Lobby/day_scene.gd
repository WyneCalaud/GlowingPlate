extends Node2D

var active_order: CustomerOrder = null

var order_index := 0



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
	OrderSystem.set_order_from_customer(order)

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
		$DialogueBox/OrderText.text = order.order_text
		$BtnAccept.show()
		$BtnContinue.show()



func _on_customer_left():
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()



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
	$DialogueBox/OrderText.text = active_order.expanded_text

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
