extends Node2D

@export var orders: Array[CustomerOrder]  # assign your .tres order files in Inspector
var order_index := 0


func _on_next_customer_pressed():
	$CustomerManager.next_customer()
	await get_tree().create_timer(0.6).timeout
	$CustomerManager.spawn_customer($CustomerManager.orders.pick_random())



func _ready():
	$CustomerManager.customer_arrived.connect(_on_customer_arrived)
	$CustomerManager.customer_left.connect(_on_customer_left)

	# Hide UI at start if needed
	$DialogueBox.hide()
	$BtnAccept.hide()
	$BtnContinue.hide()



func _on_customer_arrived(order: CustomerOrder):
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
	$CustomerManager.next_customer()  # ✅ slide out
	order_index += 1
