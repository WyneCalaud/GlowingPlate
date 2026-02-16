# res://Scripts/Customer/customer_order.gd
extends Resource
class_name CustomerOrder

@export var customer_name: String
@export var order_text: String
@export var expanded_text: String

# ⭐ NEW
# "6-9" or "10-12"
@export var age_group: String = "6-9"

# plate requirements
@export var needs: Dictionary = {
	"Go": "",
	"Grow": "",
	"GlowVeg": "",
	"GlowFru": ""
}

# beverage requirements
@export var beverage_needs: Array[String] = []
