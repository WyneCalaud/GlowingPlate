# FoodItemData.gd
extends Resource
class_name CustomItemData

# --- Core Identity ---
@export var item_name: String = "New Food Item" # Display name (e.g., "Chicken Leg")
@export var internal_key: String = "ITEM_KEY" # Unique ID for orders/database lookup (e.g., CHICKEN_LEG)
@export var food_category: String = "Grow" # Matches the plate slot type (Go, Grow, GlowVeg, GlowFru)

# --- Visuals ---
@export var base_texture: Texture2D # Inventory/Uncooked state texture
@export var plated_texture: Texture2D # Default texture for when the item is successfully plated ("RightAmount" rice)

# --- Rice Mechanic Specific Plated Textures (New additions for RICE item) ---
@export var plated_texture_small: Texture2D # Texture for a "Small" scoop of rice
@export var plated_texture_medium: Texture2D # Texture for a "Medium" scoop of rice
@export var plated_texture_too_high: Texture2D # Texture for a "TooHigh" scoop of rice

# --- Gameplay Stats ---
@export var base_value: int = 100
