extends Area2D
@export var accepted_food_type: String = "Grow"
@export var linked_image: Sprite2D
@export var plated_scale_factor: float = 0.4
var is_filled: bool = false
func try_place_food(food_data: Resource) -> bool:
	if is_filled:
		return false
	# FoodItemData uses: food_category
	if food_data.food_category == accepted_food_type:
		is_filled = true
		linked_image.texture = food_data.base_texture
		linked_image.scale = Vector2(plated_scale_factor, plated_scale_factor)
		return true
	return false
