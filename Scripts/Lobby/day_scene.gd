extends Node2D

var active_order: CustomerOrder = null

@export var orders: Array[CustomerOrder]  # assign your .tres order files in Inspector
var order_index := 0


func _on_next_customer_pressed():
	# Pick the order data
	var order = $CustomerManager.orders.pick_random()

	# Decide the sprite texture based on the order
	var tex: Texture2D = null

	match order.customer_name:
		"Niko":
			tex = preload("res://Assets/Customers/boy final.png")
		"Vien":
			tex = preload("res://Assets/Customers/girl final.png")
		#"Bomboclat":
			#tex = preload("res://Assets/Customers/customer_gia.png")
		#_:
			#tex = preload("res://Assets/Customers/customer_student.png")  # fallback default

	var GD = get_node("/root/GameData")
	GD.save_customer(order, tex)  # <-- SAVE THE CUSTOMER

	# Spawn & move customer
	$CustomerManager.next_customer()
	await get_tree().create_timer(0.6).timeout
	$CustomerManager.spawn_customer(order, tex)


func _ready():
	$CustomerManager.customer_arrived.connect(_on_customer_arrived)
	$CustomerManager.customer_left.connect(_on_customer_left)

	# Hide UI at start if needed
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()

	var GD = get_node("/root/GameData")

	if GD.saved_customer_order != null:
		# Respawn SAME CUSTOMER
		$CustomerManager.spawn_customer(GD.saved_customer_order, GD.saved_customer_texture)
	else:
		# Normal flow if no saved customer
		pass


func _on_customer_arrived(order: CustomerOrder):
	active_order = order #storing order
	
	$DialogueBox.show()
	$BtnAccept.show()
	$BtnContinue.show()
	$DialogueBox/OrderText.text = order.order_text




func _on_customer_left():
	# Hide UI again when customer leaves
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()


func _on_btn_accept_pressed() -> void:

	order_index += 1
	get_tree().change_scene_to_file("res://Scenes/Gameplay/fullgameplay.tscn")

func _on_btn_continue_pressed() -> void:
	if active_order == null:
		return
	# Replace the dialogue text with the expanded clarification
	$DialogueBox/OrderText.text = active_order.expanded_text
