extends Node

signal customer_arrived(order: CustomerOrder)
signal customer_left

@export var customer_scene: PackedScene
@export var spawn_y: float = 7
@export var offscreen_x: float = 1450
@export var onscreen_x: float = 1100
@export var move_duration: float = 0.6

var current_customer: Node2D = null

# --- ADDED: Guard flag to prevent animation interruptions ---
var is_animating: bool = false 

func spawn_customer(order: CustomerOrder, texture: Texture2D):
	# 1. Block the function if an animation is already happening
	if is_animating:
		push_warning("Spawn blocked: An animation is currently playing.")
		return
		
	is_animating = true # Lock the animations

	if current_customer:
		current_customer.queue_free()
		current_customer = null

	# Store the order in OrderSystem instead of GameData
	if order != null:
		OrderSystem.current_customer_order.required_plate = order.needs.duplicate(true)
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
		is_animating = false # Unlock when finished
		customer_arrived.emit(order)
	)

func next_customer():
	# 1. Block the function if an animation is already happening
	if is_animating:
		push_warning("Next customer blocked: An animation is currently playing.")
		return

	if not current_customer:
		return

	is_animating = true # Lock the animations

	var tween = create_tween()
	tween.tween_property(current_customer, "position:x", offscreen_x, move_duration).set_ease(Tween.EASE_IN)

	tween.finished.connect(func():
		customer_left.emit()
		
		# 2. Safety check in case current_customer was somehow deleted during the tween
		if current_customer:
			current_customer.queue_free()
			current_customer = null
			
		is_animating = false # Unlock when finished
	)
	
func scale_customer_sprite(sprite: Sprite2D, max_height: float = 300.0) -> void:
	if sprite.texture == null:
		return

	var tex_size = sprite.texture.get_size()
	if tex_size.y == 0:
		return

	var scale_factor = max_height / tex_size.y
	sprite.scale = Vector2.ONE * scale_factor

func _get_sad_texture(character_name:String) -> Texture2D:

	var GD = get_node("/root/GameData")
	var stage : int = GD.get_character_stage(character_name)

	match character_name:

		"Cyril": return preload("res://Assets/Customers/Sad/Cyril_sad.png")
		"Nestor": return preload("res://Assets/Customers/Sad/Nestor_sad.png")
		"Milan": return preload("res://Assets/Customers/Sad/Milan_sad.png")
		"Nina": return preload("res://Assets/Customers/Sad/Nina_sad.png")
		"Pedro Pan": return preload("res://Assets/Customers/Sad/PedroPan_sad.png")
		"Rimo": return preload("res://Assets/Customers/Sad/Rimo_sad.png")
		"Troy": return preload("res://Assets/Customers/Sad/Troy_sad.png")
		"Yeeha": return preload("res://Assets/Customers/Sad/Yeeha_sad.png")
		"Boba": return preload("res://Assets/Customers/Sad/Boba_sad.png")
		"Bree": return preload("res://Assets/Customers/Sad/Bree_sad.png")
		"Jenna": return preload("res://Assets/Customers/Sad/Jenna_sad.png")
		"Miggy": return preload("res://Assets/Customers/Sad/Miggy_sad.png")
		"Tina": return preload("res://Assets/Customers/Sad/Tina_sad.png")

		# ⭐ SPECIAL CHARACTERS

		"Leo":
			match stage:
				1: return preload("res://Assets/Customers/Special Characters/Sad/Leo Current_sad.png")
				2: return preload("res://Assets/Customers/Special Characters/Sad/Leo Better_sad.png")
				3: return preload("res://Assets/Customers/Special Characters/Sad/Leo Glowing_sad.png")

		"Maya":
			match stage:
				1: return preload("res://Assets/Customers/Special Characters/Sad/Maya Current_sad.png")
				2: return preload("res://Assets/Customers/Special Characters/Sad/Maya Better_sad.png")
				3: return preload("res://Assets/Customers/Special Characters/Sad/Maya Glowing_sad.png")

		"Norma":
			match stage:
				1: return preload("res://Assets/Customers/Special Characters/Sad/Norma Current_sad.png")
				2: return preload("res://Assets/Customers/Special Characters/Sad/Norma Better_sad.png")
				3: return preload("res://Assets/Customers/Special Characters/Sad/Norma Glowing_sad.png")

	return null

func play_sad_reaction(character_name:String) -> void:

	if not current_customer:
		return

	var sprite := current_customer.get_node_or_null("CustomerSprite") as Sprite2D
	if sprite:

		var sad_tex := _get_sad_texture(character_name)

		if sad_tex:
			sprite.texture = sad_tex
			scale_customer_sprite(sprite, 470)
