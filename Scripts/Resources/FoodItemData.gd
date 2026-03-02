# FoodItemData.gd
extends Resource
class_name CustomItemData

# --- Core Identity ---
@export var item_name: String = "New Food Item"
@export var internal_key: String = "ITEM_KEY"
@export var food_category: String = "Grow"

# --- Visuals ---
@export var base_texture: Texture2D
@export var default_plated_texture: Texture2D

# --- Quantity-Based Textures ---
@export_group("Quantity Textures")
@export var texture_count_1: Texture2D
@export var texture_count_2: Texture2D
@export var texture_count_3: Texture2D
@export var texture_count_4: Texture2D

# --- Portion Mechanics (New) ---
@export_group("Portion Mechanics")
@export var is_portionable: bool = false
@export var plated_texture_half: Texture2D
@export var plated_texture_half_2: Texture2D
@export var plated_texture_half_3: Texture2D
@export var plated_texture_whole: Texture2D
@export var plated_texture_whole_2: Texture2D
@export var plated_texture_whole_3: Texture2D
# New: Images specifically for the Selector UI Buttons
@export var selector_icon_half: Texture2D
@export var selector_icon_whole: Texture2D

# --- Veggie Cup Mechanics ---
@export_group("Veggie Cup Mechanics")
@export var is_veggie_cup: bool = false
# Images for the CupProgress UI (1 to 4 taps)
@export var veggie_cup_low: Texture2D
@export var veggie_cup_med: Texture2D
@export var veggie_cup_high: Texture2D
@export var veggie_cup_full: Texture2D
@export var veggie_plated_low: Texture2D # WRONG SIZE
@export var veggie_plated_med: Texture2D # WRONG SIZE
@export var veggie_plated_high: Texture2D # AGE GROUP (6-9)
@export var veggie_plated_full: Texture2D # AGE GROUP (10-12)

# --- Rice Mechanic Specific Plated Textures ---
@export_group("Rice Mechanic Textures")
@export var plated_texture_small: Texture2D
@export var plated_texture_medium: Texture2D
@export var plated_texture_too_high: Texture2D

# --- Nutritional Stats (New) ---
# Values represent percentage or mg/mcg per serving
@export_group("Nutrients")
@export_range(0, 100) var vitamin_a: float = 0.0
@export_range(0, 100) var vitamin_b: float = 0.0
@export_range(0, 100) var vitamin_c: float = 0.0
@export_range(0, 100) var vitamin_d: float = 0.0
@export_range(0, 100) var zinc: float = 0.0
@export_range(0, 100) var iron: float = 0.0

# --- Gameplay Stats ---
@export_group("Economics")
@export var base_value: int = 100 # INCOME: How much you earn when serving this correctly
@export var cost: int = 5         # EXPENSE: How much deducted per scoop/use

## Returns a dictionary of all nutrients for easy calculation
func get_nutritional_profile() -> Dictionary:
	return {
		"vit_a": vitamin_a,
		"vit_b": vitamin_b,
		"vit_c": vitamin_c,
		"vit_d": vitamin_d,
		"zinc": zinc,
		"iron": iron
	}
