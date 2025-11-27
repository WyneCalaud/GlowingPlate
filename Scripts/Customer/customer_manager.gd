extends Node

signal customer_arrived(order: CustomerOrder)
signal customer_left

@export var customer_scene: PackedScene
@export var orders: Array[CustomerOrder]  # 👈 your actual orders array lives here
@export var spawn_y: float = 15
@export var offscreen_x: float = 0
@export var onscreen_x: float = 350
@export var move_duration: float = 0.5

var current_customer: Node2D = null

func spawn_customer(order: CustomerOrder, texture: Texture2D):
	if current_customer:
		current_customer.queue_free()

	current_customer = customer_scene.instantiate()
	add_child(current_customer)
	current_customer.position = Vector2(offscreen_x, spawn_y)

	# Assign customer sprite texture
	var sprite = current_customer.get_node("CustomerSprite")
	sprite.texture = texture

	# Slide in animation
	var tween = create_tween()
	tween.tween_property(current_customer, "position:x", onscreen_x, move_duration)\
		.set_ease(Tween.EASE_OUT)

	tween.finished.connect(func():
		customer_arrived.emit(order)
	)

	
func next_customer():
	if not current_customer:
		return

	var tween = create_tween()
	tween.tween_property(current_customer, "position:x", offscreen_x, move_duration)\
		.set_ease(Tween.EASE_IN)

	tween.finished.connect(func():
		customer_left.emit()
		current_customer.queue_free()
		current_customer = null
	)
