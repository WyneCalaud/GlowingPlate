# res://Scripts/Customer/customer_order.gd
extends Resource
class_name CustomerOrder

@export var customer_name: String
@export var order_text: String
@export var expanded_text: String

# NEW: dictionary of required internal_keys for the plate
# Example keys: "Go", "Grow", "GlowVeg", "GlowFru" — set these in the Inspector on each .tres
@export var needs: Dictionary = {
	"Go": "",
	"Grow": "",
	"GlowVeg": "",
	"GlowFru": ""
}
