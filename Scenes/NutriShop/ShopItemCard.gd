# ShopItemCard.gd

extends TextureRect

# --- SIGNALS ---
signal card_action(card_node)

# --- EXPORTS ---
@export_group("Button Textures")
@export var tex_buy: Texture2D      # The default Price Tag texture
@export var tex_equip: Texture2D    # The "Equip" button texture
@export var tex_equipped: Texture2D # The "Equipped" button texture

# --- NODES ---
@onready var btn = $BtnPrice
@onready var lbl = $PriceLabel

# --- DATA ---
var item_name: String
var price: int
var category: String
var current_state: String = "LOCKED" # States: LOCKED, UNLOCKED, EQUIPPED

func _ready():
	if btn:
		# ⭐ Tell the global UIAudioManager NOT to attach the default click sound to this button
		btn.add_to_group("silent_button")
		
		btn.pressed.connect(_on_btn_pressed)

# Called by NutriShop to initialize the card
func setup(p_name: String, p_price: int, p_category: String, p_state: String):
	item_name = p_name
	price = p_price
	category = p_category
	update_state(p_state)

# Handles the visual switching logic
func update_state(new_state: String):
	current_state = new_state
	
	if not btn: return
	
	match new_state:
		"LOCKED":
			# Show Price
			if tex_buy: btn.texture_normal = tex_buy
			if lbl:
				lbl.visible = true
				lbl.text = str(price)
			btn.disabled = false
			btn.modulate = Color.WHITE
			
		"UNLOCKED":
			# Show "Equip"
			if tex_equip: btn.texture_normal = tex_equip
			if lbl: lbl.visible = false
			btn.disabled = false
			btn.modulate = Color.WHITE
			
		"EQUIPPED":
			# Show "Equipped"
			if tex_equipped: btn.texture_normal = tex_equipped
			if lbl: lbl.visible = false
			btn.disabled = true # Cannot click if already equipped
			btn.modulate = Color(0.8, 0.8, 0.8) # Slight dim to indicate active state

func _on_btn_pressed():
	# NutriShop will decide what happens based on current_state
	emit_signal("card_action", self)
