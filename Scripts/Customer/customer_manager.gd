extends Node

signal customer_arrived(order: CustomerOrder)
signal customer_left

@export var customer_scene: PackedScene
@export var spawn_y: float = 10
@export var offscreen_x: float = 1399
@export var onscreen_x: float = 1080
@export var move_duration: float = 0.6

var current_customer: Node2D = null

func spawn_customer(order: CustomerOrder, texture: Texture2D):
	if current_customer:
		current_customer.queue_free()

	# FIX: Store the order in OrderSystem instead of GameData
	if order != null:
		# Copy the needs from the resource to the Global OrderSystem dictionary
		OrderSystem.current_customer_order.required_plate = order.needs.duplicate(true)
		
		# Optionally store other fields if needed for logic (though OrderSystem mainly checks food)
		OrderSystem.current_customer_order["order_text"] = order.order_text
		OrderSystem.current_customer_order["customer_name"] = order.customer_name

	current_customer = customer_scene.instantiate()
	add_child(current_customer)
	current_customer.position = Vector2(offscreen_x, spawn_y)

	# Assign customer sprite texture
	var sprite := current_customer.get_node_or_null("CustomerSprite") as Sprite2D
	if sprite:
		sprite.texture = texture
		scale_customer_sprite(sprite, 470)


	# Slide in animation
	var tween = create_tween()
	tween.tween_property(current_customer, "position:x", onscreen_x, move_duration).set_ease(Tween.EASE_OUT)

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
	
func scale_customer_sprite(sprite: Sprite2D, max_height: float = 300.0) -> void:
	if sprite.texture == null:
		return

	var tex_size = sprite.texture.get_size()
	if tex_size.y == 0:
		return

	var scale_factor = max_height / tex_size.y
	sprite.scale = Vector2.ONE * scale_factor
