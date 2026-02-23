extends Resource
class_name CustomerOrder

@export var customer_name: String
@export var order_text: String
@export var expanded_text: String

# ⭐ NEW – Exact age
@export var age: int = 8

# plate requirements
@export var needs: Dictionary = {
	"Go": "",
	"Grow": "",
	"GlowVeg": "",
	"GlowFru": ""
}

# beverage requirements
@export var beverage_needs: Array[String] = []

# ⭐ Computed property (auto age group)
func get_age_group() -> String:
	if age <= 9:
		return "6-9"
	else:
		return "10-12"
