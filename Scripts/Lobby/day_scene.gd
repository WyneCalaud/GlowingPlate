extends Node2D

var active_order: CustomerOrder = null

var order_index := 0


func _on_next_customer_pressed():
	
	get_tree().call_group("HUD", "_reset_happiness_ui")
	
	# ✅ New customer = reset patience
	GameData.customer_patience = 100.0
	GameData.patience_running = false
	get_tree().call_group("HUD", "reset_patience")

	$NextCustomer.hide()

	print("Remaining customers:", GameData.remaining_customers.size()) 

	if GameData.remaining_customers.is_empty():
		return

	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()

	var order: CustomerOrder = GameData.remaining_customers.pop_front()

	var tex: Texture2D

	# ⭐ SPECIAL CHARACTER STAGE HANDLING
	var stage := GameData.get_character_stage(order.customer_name)

	match order.customer_name:

		# ================= NORMAL =================
		"Cyril":
			tex = preload("res://Assets/Customers/Cyril.png")
		"Nestor":
			tex = preload("res://Assets/Customers/Nestor.png")
		"Milan":
			tex = preload("res://Assets/Customers/Milan.png")
		"Nina":
			tex = preload("res://Assets/Customers/Nina.png")
		"Pedro Pan":
			tex = preload("res://Assets/Customers/Pedro Pan.png")
		"Rimo":
			tex = preload("res://Assets/Customers/Rimo.png")
		"Tina":
			tex = preload("res://Assets/Customers/Tina.png")
		"Troy":
			tex = preload("res://Assets/Customers/Troy.png")
		"Yeeha":
			tex = preload("res://Assets/Customers/Yeeha.png")
		"Boba":
			tex = preload("res://Assets/Customers/Boba.png")
		"Bree":
			tex = preload("res://Assets/Customers/Bree.png")
		"Jenna":
			tex = preload("res://Assets/Customers/Jenna.png")
		"Miggy":
			tex = preload("res://Assets/Customers/Miggy.png")
		"Principal":
			tex = preload("res://Assets/Customers/Principal_.png")

		# ================= SPECIAL STORY =================

		"Leo":
			match stage:
				1: tex = preload("res://Assets/Customers/Special Characters/Leo Current.png")
				2: tex = preload("res://Assets/Customers/Special Characters/Leo Better.png")
				3: tex = preload("res://Assets/Customers/Special Characters/Leo Glowing.png")

		"Maya":
			match stage:
				1: tex = preload("res://Assets/Customers/Special Characters/Maya Current.png")
				2: tex = preload("res://Assets/Customers/Special Characters/Maya Better.png")
				3: tex = preload("res://Assets/Customers/Special Characters/Maya Glowing.png")

		"Norma":
			match stage:
				1: tex = preload("res://Assets/Customers/Special Characters/Norma Current.png")
				2: tex = preload("res://Assets/Customers/Special Characters/Norma Better.png")
				3: tex = preload("res://Assets/Customers/Special Characters/Norma Glowing.png")

	GameData.save_customer(order, tex)
	GameData.service_state = GameData.ServiceState.CUSTOMER_PRESENT

	$CustomerManager.spawn_customer(order, tex)



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

	# Show Next Customer button only if customers remain
	if not GameData.remaining_customers.is_empty():
		$NextCustomer.show()
	else:
		$NextCustomer.hide()


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
