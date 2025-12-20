extends Node2D

var active_order: CustomerOrder = null

@export var orders: Array[CustomerOrder]  # assign your .tres order files in Inspector
var order_index := 0


func _on_next_customer_pressed():
	$NextCustomer.hide()

	# Use the global Autoload directly instead of get_node
	print("Remaining customers:", GameData.remaining_customers.size()) 

	if GameData.remaining_customers.is_empty():
		# GameData handles the end-of-day transition in finalize_service.
		# We don't need to do anything here.
		return

	# UI reset
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()

	var order: CustomerOrder = GameData.remaining_customers.pop_front()

	var tex: Texture2D
	match order.customer_name:
		"Niko":
			tex = preload("res://Assets/Customers/boy final.png")
		"Vien":
			tex = preload("res://Assets/Customers/girl final.png")

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


func _on_customer_arrived(order: CustomerOrder):
	active_order = order

	$DialogueBox.show()
	$DialogueBox/OrderText.text = order.order_text

	$BtnAccept.show()
	$BtnContinue.show()
	
	$DialogueBox/OrderText.text = order.order_text


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

	$BtnAccept.hide()
	$BtnContinue.hide()

	get_tree().change_scene_to_file("res://Scenes/Gameplay/fullgameplay.tscn")


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
