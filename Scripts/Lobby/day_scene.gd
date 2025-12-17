extends Node2D

var active_order: CustomerOrder = null

@export var orders: Array[CustomerOrder]  # assign your .tres order files in Inspector
var order_index := 0


func _on_next_customer_pressed():
	$NextCustomer.hide()

	# 🔴 HARD UI RESET (THIS IS THE KEY)
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()

	var GD := get_node("/root/GameData")

	if GD.remaining_customers.is_empty():
		_end_day()
		return

	var order: CustomerOrder = GD.remaining_customers.pop_front()

	var tex: Texture2D
	match order.customer_name:
		"Niko":
			tex = preload("res://Assets/Customers/boy final.png")
		"Vien":
			tex = preload("res://Assets/Customers/girl final.png")

	GD.save_customer(order, tex)
	GD.service_state = GameData.ServiceState.CUSTOMER_PRESENT

	$CustomerManager.spawn_customer(order, tex)


func _ready():
	$CustomerManager.customer_arrived.connect(_on_customer_arrived)
	$CustomerManager.customer_left.connect(_on_customer_left)

	var GD := get_node("/root/GameData")

	# HARD OVERRIDE
	if GD.force_hide_accept_buttons:
		$BtnAccept.hide()
		$BtnContinue.hide()
	else:
		$BtnAccept.hide()
		$BtnContinue.hide()

	$DialogueBox.hide()

	if GD.saved_customer_order != null:
		$CustomerManager.spawn_customer(
			GD.saved_customer_order,
			GD.saved_customer_texture
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
	$NextCustomer.show()


func _on_btn_accept_pressed() -> void:
	var GD := get_node("/root/GameData")
	GD.service_state = GameData.ServiceState.IN_KITCHEN

	$BtnAccept.hide()
	$BtnContinue.hide()

	get_tree().change_scene_to_file("res://Scenes/Gameplay/fullgameplay.tscn")


func _on_btn_continue_pressed() -> void:
	if active_order == null:
		return
	# Replace the dialogue text with the expanded clarification
	$DialogueBox/OrderText.text = active_order.expanded_text

func _end_day():
	var GD := get_node("/root/GameData")
	GD.day_started = false
	GD.service_state = GameData.ServiceState.IDLE

	# Optional: advance day counter here if needed
	# GD.current_day += 1

	# Return to lobby
	get_tree().change_scene_to_file("res://Scenes/Lobby Canteen/lobbycanteen.tscn")
